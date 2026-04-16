#!/usr/bin/env bash
# Orbcrypt — Lean 4 Environment Setup
# Adapted from seLe4n (https://github.com/hatter6822/seLe4n)
# Sets up elan, Lean 4 toolchain, and Mathlib for the Orbcrypt project.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUIET=0
BUILD_REQUESTED=0
for arg in "$@"; do
  case "${arg}" in
    --quiet|-q) QUIET=1 ;;
    --build) BUILD_REQUESTED=1 ;;
  esac
done
log() { if [ "${QUIET}" -eq 0 ]; then echo "$@"; fi; }

# Elapsed-time helper for performance diagnostics.
SETUP_START_TIME="${EPOCHREALTIME:-$(date +%s)}"
log_elapsed() {
  local now="${EPOCHREALTIME:-$(date +%s)}"
  local elapsed
  if command -v bc >/dev/null 2>&1; then
    elapsed="$(echo "${now} - ${SETUP_START_TIME}" | bc)"
  else
    elapsed="$(( ${now%.*} - ${SETUP_START_TIME%.*} ))"
  fi
  log "[setup +${elapsed}s] $*"
}

ELAN_HOME_DEFAULT="${HOME}/.elan"
ELAN_HOME_DIR="${ELAN_HOME:-$ELAN_HOME_DEFAULT}"
ELAN_ENV_FILE="${ELAN_HOME_DIR}/env"
LEAN_TOOLCHAIN_FILE="${ROOT_DIR}/lean-toolchain"
ELAN_INSTALLER_URL="https://raw.githubusercontent.com/leanprover/elan/87f5ec2f5627dd3df16b346733147412c3ddeef1/elan-init.sh"
ELAN_INSTALLER_SHA256="4bacca9502cb89736fe63d2685abc2947cfbf34dc87673504f1bb4c43eda9264"

# Pin elan binary release version for direct download path.
ELAN_BINARY_VERSION="v4.2.1"
ELAN_BINARY_SHA256_X86="4e717523217af592fa2d7b9c479410a31816c065d66ccbf0c2149337cfec0f5c"
ELAN_BINARY_SHA256_ARM="bb78726ace6a912c7122a389018bcd69d9122ce04659800101392f7db380d3b3"

# SHA-256 hashes for the Lean toolchain archives (v4.30.0-rc1).
# To regenerate after version bump:
#   curl -fsSL "https://github.com/leanprover/lean4/releases/download/v4.30.0-rc1/lean-4.30.0-rc1-linux.tar.zst" | sha256sum
#   curl -fsSL "https://github.com/leanprover/lean4/releases/download/v4.30.0-rc1/lean-4.30.0-rc1-linux_aarch64.tar.zst" | sha256sum
#   curl -fsSL "https://github.com/leanprover/lean4/releases/download/v4.30.0-rc1/lean-4.30.0-rc1-linux.zip" | sha256sum
#   curl -fsSL "https://github.com/leanprover/lean4/releases/download/v4.30.0-rc1/lean-4.30.0-rc1-linux_aarch64.zip" | sha256sum
LEAN_TOOLCHAIN_SHA256_ZST_X86="37c2913cf41b49f33ab2eebc449d12394081817315c9f915af1ff43f1642de42"
LEAN_TOOLCHAIN_SHA256_ZST_ARM="66593bc683fbf6acd889353b37704f6ba088b07e1224bc560d01e291f6e57502"
LEAN_TOOLCHAIN_SHA256_ZIP_X86="b2293b2003350c456aec8f954f75e0743a1cf0b63e3127e0c90d7c430e7dec49"
LEAN_TOOLCHAIN_SHA256_ZIP_ARM="a70829d2f2ea1b1752b6b805b2b2acb76b3e38be4ee71e6717d5ed8f9d8467e1"

# -------- Parse toolchain spec early (needed by fast-path) --------
if [ ! -f "${LEAN_TOOLCHAIN_FILE}" ]; then
  echo "error: lean-toolchain not found at ${LEAN_TOOLCHAIN_FILE}" >&2
  exit 1
fi
TOOLCHAIN="$(tr -d '\n\r' < "${LEAN_TOOLCHAIN_FILE}")"
if [ -z "${TOOLCHAIN}" ]; then
  echo "error: ${LEAN_TOOLCHAIN_FILE} is empty" >&2
  exit 1
fi
# Parse toolchain spec "org/repo:tag" into components for download URLs.
TOOLCHAIN_ORG="$(echo "${TOOLCHAIN}" | cut -d/ -f1)"
TOOLCHAIN_REPO="$(echo "${TOOLCHAIN}" | cut -d/ -f2 | cut -d: -f1)"
TOOLCHAIN_TAG="$(echo "${TOOLCHAIN}" | cut -d: -f2)"
# elan normalises "org/repo:tag" -> "org-repo-tag" for directory names.
TOOLCHAIN_DIR_NAME="$(echo "${TOOLCHAIN}" | sed 's|/|-|g; s|:|-|g')"

# -------- Parse Mathlib revision for SHA-pinned cache URLs --------
# Pin cache URLs to the exact Mathlib commit locked in lake-manifest.json,
# not a mutable branch like 'master'. This follows the same security pattern
# used for the elan and Lean toolchain downloads above (immutable references
# with integrity verification).
MATHLIB_REV=""
if [ -f "${ROOT_DIR}/lake-manifest.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    MATHLIB_REV="$(jq -r '.packages[] | select(.name == "mathlib") | .rev' "${ROOT_DIR}/lake-manifest.json" 2>/dev/null)"
  elif command -v python3 >/dev/null 2>&1; then
    MATHLIB_REV="$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for p in data.get('packages', []):
    if p.get('name') == 'mathlib':
        print(p['rev'])
        break
" "${ROOT_DIR}/lake-manifest.json" 2>/dev/null)"
  fi
fi
# Validate: must be a 40-character lowercase hex string (SHA-1 commit hash).
# Reject anything else to prevent URL injection from a crafted manifest.
if ! echo "${MATHLIB_REV}" | grep -qE '^[a-f0-9]{40}$'; then
  MATHLIB_REV=""
fi
if [ -z "${MATHLIB_REV}" ]; then
  log_elapsed "warning: could not parse a valid Mathlib commit from lake-manifest.json; cache URLs will not be SHA-pinned"
fi

# -------- Lake / Mathlib cache configuration --------
# Mathlib ships precompiled `.olean` caches that can shave ~30 min off a fresh
# build. They are hosted on Azure Blob Storage (`lakecache.blob.core.windows.net`)
# with a Cloudflare R2 mirror (`*.r2.cloudflarestorage.com`), and Lake's native
# cache service talks to `reservoir.lean-lang.org`. In sandboxed / CI environments
# with an outbound-host allowlist, all three may be unreachable — in which case
# every `lake exe cache get` attempt bursts out 8000+ 404s at zero throughput
# and "downloads" nothing.
#
# Strategy:
#   1. Probe the real upstream hosts once per session to decide whether the
#      cache is reachable.
#   2. If reachable, delegate to `lake exe cache get` with default settings.
#   3. If blocked, DON'T rewrite URLs to an accessible-but-empty bucket like
#      raw.githubusercontent.com — that just produces confusing "0 KB/s"
#      progress spam for files that will never exist there. Instead, skip the
#      fetch, print one honest warning, and let Lake build Mathlib from source.
#      The resulting local `.olean` files persist under
#      `.lake/packages/mathlib/.lake/build/` and are reused on every subsequent
#      build in the same workspace.
#   4. Record the decision in a marker file so we don't re-probe on every
#      session start. The marker records which outcome occurred.
#
# Notes:
#   - Older revisions of this script wrote a `~/.lake/config.toml` redirecting
#     Lake's native cache service to `raw.githubusercontent.com/...`. That file
#     is now actively harmful: Lake queries it for every build and the 404s
#     are indistinguishable from real misses. The script removes any stale
#     copy of its own making.
#   - `MATHLIB_CACHE_GET_URL` is intentionally left unset. The Mathlib cache
#     tool already falls through Azure → Cloudflare automatically; a manual
#     override to a 404-only host just makes failure less informative.

MATHLIB_CACHE_MARKER="${ROOT_DIR}/.lake/.mathlib_cache_ok"
MATHLIB_CACHE_NOFETCH_MARKER="${ROOT_DIR}/.lake/.mathlib_cache_unreachable"
LAKE_CONFIG_DIR="${HOME}/.lake"
LAKE_CONFIG_FILE="${LAKE_CONFIG_DIR}/config.toml"

# Signature written at the top of any lake config this script previously
# installed. Used to safely detect + remove the stale redirect without
# clobbering a config the user hand-wrote for some other reason.
LAKE_CONFIG_STALE_MARKER="# Lake cache configuration — redirects cache lookups to raw.githubusercontent.com"

cache_host_reachable() {
  # Return 0 iff at least one upstream cache host can actually serve a file.
  # HEAD probes aren't enough: many firewalls proxy 4xx responses that look
  # indistinguishable from legitimate "bucket root needs auth" errors, and
  # Cloudflare's R2 edge returns 503 "DNS cache overflow" for egress IPs it
  # can't route — both still leave `lake exe cache get` to fail on every file.
  #
  # The reliable test is a real GET: ask each endpoint for a small known-good
  # file and see whether any bytes actually land. We use Mathlib's own
  # `lookup` subcommand to pick a valid ltar hash for the current commit, then
  # try to download it with a short timeout.

  local probe_url probe_body sample_hash
  probe_body="$(mktemp)"

  # Find any one ltar hash the cache tool would fetch. If the tool isn't
  # built yet or lookup fails, fall back to a hash that's been stable for
  # months on the pinned Mathlib commit.
  sample_hash=""
  # Look up a real current-commit hash if the cache tool is already built
  # AND can respond within 15s. Otherwise fall back to a previously-stable
  # hash; the probe only needs SOME plausible .ltar URL to prove connectivity.
  if command -v lake >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
    sample_hash="$( (cd "${ROOT_DIR}" && timeout 15 lake exe cache lookup Mathlib.Init 2>/dev/null) \
      | awk -F'/' '/\.ltar$/ {name=$NF; sub(/\.ltar$/, "", name); print name; exit}' )"
  fi
  [ -n "${sample_hash}" ] || sample_hash="9b9a4626d26ea70d"

  for probe_url in \
    "https://lakecache.blob.core.windows.net/mathlib4/f/${sample_hash}.ltar" \
    "https://a09a7664adc082e00f294ac190827820.r2.cloudflarestorage.com/mathlib4/f/${sample_hash}.ltar"
  do
    local code bytes
    code="$(curl -sSL -m 8 -o "${probe_body}" \
      -w '%{http_code}' "${probe_url}" 2>/dev/null || echo "000")"
    bytes="$(wc -c < "${probe_body}" 2>/dev/null || echo 0)"
    if [ "${code}" = "200" ] && [ "${bytes:-0}" -gt 1024 ]; then
      log_elapsed "cache host reachable and serving data: ${probe_url}"
      rm -f "${probe_body}"
      return 0
    fi
  done
  rm -f "${probe_body}"
  return 1
}

remove_stale_lake_config() {
  # If ~/.lake/config.toml was written by an earlier version of this script
  # and points at the broken raw.githubusercontent.com redirect, delete it.
  # Leave user-authored configs untouched.
  if [ -f "${LAKE_CONFIG_FILE}" ] && head -1 "${LAKE_CONFIG_FILE}" 2>/dev/null | grep -qF "${LAKE_CONFIG_STALE_MARKER}"; then
    log_elapsed "removing stale ${LAKE_CONFIG_FILE} (broken raw.githubusercontent.com redirect)"
    rm -f "${LAKE_CONFIG_FILE}"
  fi
}

configure_lake_cache() {
  remove_stale_lake_config

  # If we've already decided cache is unreachable, skip silently. User can
  # force a re-probe by deleting both marker files.
  if [ -f "${MATHLIB_CACHE_NOFETCH_MARKER}" ]; then
    log_elapsed "Mathlib cache previously probed as unreachable; building from source"
    return 1
  fi

  if [ -f "${MATHLIB_CACHE_MARKER}" ]; then
    log_elapsed "Lake cache already populated (marker found)"
    return 0
  fi

  mkdir -p "$(dirname "${MATHLIB_CACHE_MARKER}")"

  if ! cache_host_reachable; then
    log_elapsed "warning: all Mathlib cache endpoints are blocked by the network allowlist"
    log_elapsed "  (Azure Blob, Cloudflare R2, and Reservoir are all unreachable)"
    log_elapsed "  skipping 'lake exe cache get' — it would 404 on every file"
    log_elapsed "  builds will compile Mathlib from source once; the resulting .oleans"
    log_elapsed "  persist under .lake/packages/mathlib/.lake/build/ and are reused"
    log_elapsed "  on every subsequent build in this workspace"
    touch "${MATHLIB_CACHE_NOFETCH_MARKER}"
    return 1
  fi

  log_elapsed "Mathlib cache hosts reachable — attempting download"
  # Unset any stale override left by older script versions so the cache tool
  # uses its built-in Azure → Cloudflare fallback.
  unset MATHLIB_CACHE_GET_URL
  if (cd "${ROOT_DIR}" && lake exe cache get 2>&1); then
    log_elapsed "Mathlib cache downloaded successfully"
    touch "${MATHLIB_CACHE_MARKER}"
    return 0
  fi

  log_elapsed "warning: cache endpoints reachable but 'lake exe cache get' failed"
  log_elapsed "  builds will fall back to compiling Mathlib from source"
  return 1
}

# -------- Fast-path: skip setup if everything is already ready --------
fast_path_ready() {
  if [ -f "${ELAN_ENV_FILE}" ]; then
    # shellcheck disable=SC1090
    source "${ELAN_ENV_FILE}"
  fi
  command -v lake >/dev/null 2>&1 || return 1
  local tc_dir="${ELAN_HOME_DIR}/toolchains/${TOOLCHAIN_DIR_NAME}"
  [ -x "${tc_dir}/bin/lean" ] || return 1
  [ -f "${tc_dir}/lib/crti.o" ] || return 1
  return 0
}

if fast_path_ready; then
  log_elapsed "Lean environment already configured (fast-path)"
  configure_lake_cache || true
  if [ "${BUILD_REQUESTED}" -eq 1 ]; then
    log_elapsed "running lake build"
    (cd "${ROOT_DIR}" && lake build)
  fi
  exit 0
fi

log_elapsed "full environment setup required"

# -------- Prerequisite check --------
if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required to install elan" >&2
  exit 1
fi

# -------- Package management helpers --------
APT_UPDATE_DONE=0

run_pkg_install() {
  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

apt_update_once() {
  if [ "${APT_UPDATE_DONE}" -eq 0 ]; then
    if ! run_pkg_install apt-get update; then
      run_pkg_install apt-get update \
        -o Dir::Etc::sourceparts="-" \
        -o APT::Get::List-Cleanup="0" || true
    fi
    APT_UPDATE_DONE=1
  fi
}

compute_sha256() {
  local target_file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${target_file}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${target_file}" | awk '{print $1}'
  else
    echo "error: neither sha256sum nor shasum is available" >&2
    exit 1
  fi
}

verify_toolchain_sha256() {
  local target_file="$1"
  local format="$2"
  local expected_sha=""

  case "$(uname -m)" in
    x86_64|amd64)
      if [ "${format}" = "zst" ]; then
        expected_sha="${LEAN_TOOLCHAIN_SHA256_ZST_X86}"
      else
        expected_sha="${LEAN_TOOLCHAIN_SHA256_ZIP_X86}"
      fi
      ;;
    aarch64|arm64)
      if [ "${format}" = "zst" ]; then
        expected_sha="${LEAN_TOOLCHAIN_SHA256_ZST_ARM}"
      else
        expected_sha="${LEAN_TOOLCHAIN_SHA256_ZIP_ARM}"
      fi
      ;;
  esac

  if [ -z "${expected_sha}" ]; then
    echo "error: no SHA-256 hash configured for architecture $(uname -m); aborting" >&2
    return 1
  fi

  local actual_sha
  actual_sha="$(compute_sha256 "${target_file}")"
  if [ "${actual_sha}" != "${expected_sha}" ]; then
    echo "error: Lean toolchain checksum verification failed" >&2
    echo "  expected: ${expected_sha}" >&2
    echo "  actual:   ${actual_sha}" >&2
    rm -f "${target_file}"
    exit 1
  fi
  log_elapsed "toolchain SHA-256 verified (${format})"
}

# -------- zstd install (quick, no apt-get update) --------
install_zstd_if_needed() {
  if command -v zstd >/dev/null 2>&1; then
    return 0
  fi
  if command -v apt-get >/dev/null 2>&1; then
    if timeout 5 bash -c 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends zstd 2>/dev/null' >/dev/null 2>&1; then
      log_elapsed "zstd installed from cache"
    else
      log_elapsed "zstd not in cache; will use zip fallback"
    fi
  fi
}

install_zstd_if_needed

# -------- Architecture detection --------
detect_arch_suffix() {
  local arch
  arch="$(uname -m)"
  case "${arch}" in
    x86_64|amd64)  echo "" ;;
    aarch64|arm64) echo "_aarch64" ;;
    *) echo "error: unsupported architecture '${arch}'" >&2; exit 1 ;;
  esac
}

# -------- elan env file --------
ensure_elan_env_file() {
  if [ -f "${ELAN_ENV_FILE}" ]; then
    return 0
  fi
  mkdir -p "$(dirname "${ELAN_ENV_FILE}")"
  cat > "${ELAN_ENV_FILE}" << 'ENVEOF'
#!/bin/sh
# elan shell setup
case ":${PATH}:" in
    *:"${HOME}/.elan/bin":*)
        ;;
    *)
        export PATH="${HOME}/.elan/bin:${PATH}"
        ;;
esac
ENVEOF
}

# -------- Manual curl-based install --------
manual_curl_install() {
  log_elapsed "manual curl-based install starting"

  local elan_bin_dir="${ELAN_HOME_DIR}/bin"
  local toolchain_dir="${ELAN_HOME_DIR}/toolchains/${TOOLCHAIN_DIR_NAME}"
  local arch_suffix
  arch_suffix="$(detect_arch_suffix)"
  local version_number="${TOOLCHAIN_TAG#v}"
  local lean_archive_name="lean-${version_number}-linux${arch_suffix}"

  mkdir -p "${elan_bin_dir}" "${ELAN_HOME_DIR}/toolchains"

  ensure_elan_env_file

  cat > "${ELAN_HOME_DIR}/settings.toml" << SETTINGSEOF
version = "12"
default_toolchain = "${TOOLCHAIN_DIR_NAME}"
SETTINGSEOF

  # Download elan binary in background
  local elan_bg_pid=""
  if [ ! -x "${elan_bin_dir}/elan" ]; then
    (
      local arch_name expected_sha
      case "$(uname -m)" in
        x86_64|amd64)
          arch_name="x86_64-unknown-linux-gnu"
          expected_sha="${ELAN_BINARY_SHA256_X86}"
          ;;
        aarch64|arm64)
          arch_name="aarch64-unknown-linux-gnu"
          expected_sha="${ELAN_BINARY_SHA256_ARM}"
          ;;
        *) exit 1 ;;
      esac
      local elan_tar
      elan_tar="$(mktemp)"
      curl -fsSL "https://github.com/leanprover/elan/releases/download/${ELAN_BINARY_VERSION}/elan-${arch_name}.tar.gz" -o "${elan_tar}"
      local actual_sha
      actual_sha="$(compute_sha256 "${elan_tar}")"
      if [ "${actual_sha}" != "${expected_sha}" ]; then
        echo "error: elan binary checksum verification failed" >&2
        rm -f "${elan_tar}"
        exit 1
      fi
      tar -xzf "${elan_tar}" -C "${elan_bin_dir}/" \
        && chmod +x "${elan_bin_dir}/elan-init"
      rm -f "${elan_tar}"
    ) &
    elan_bg_pid=$!
  fi

  # Install Lean toolchain (foreground — critical path)
  if [ ! -d "${toolchain_dir}/bin" ]; then
    log_elapsed "downloading Lean toolchain ${TOOLCHAIN}"

    if command -v zstd >/dev/null 2>&1; then
      local lean_tar
      lean_tar="$(mktemp)"
      trap 'rm -f "${lean_tar}"' EXIT
      curl -fsSL "https://github.com/${TOOLCHAIN_ORG}/${TOOLCHAIN_REPO}/releases/download/${TOOLCHAIN_TAG}/${lean_archive_name}.tar.zst" -o "${lean_tar}"
      verify_toolchain_sha256 "${lean_tar}" "zst"
      log_elapsed "extracting toolchain (zstd)"
      local lean_extracted
      lean_extracted="$(mktemp)"
      rm -f "${lean_extracted}"
      lean_extracted="${lean_extracted}.tar"
      zstd -d "${lean_tar}" -o "${lean_extracted}"
      tar -xf "${lean_extracted}" -C "${ELAN_HOME_DIR}/toolchains/"
      rm -f "${lean_tar}" "${lean_extracted}"
      trap - EXIT
    else
      log_elapsed "zstd unavailable; downloading zip archive instead"
      local lean_zip
      lean_zip="$(mktemp)"
      trap 'rm -f "${lean_zip}"' EXIT
      curl -fsSL "https://github.com/${TOOLCHAIN_ORG}/${TOOLCHAIN_REPO}/releases/download/${TOOLCHAIN_TAG}/${lean_archive_name}.zip" -o "${lean_zip}"
      verify_toolchain_sha256 "${lean_zip}" "zip"
      unzip -qo "${lean_zip}" -d "${ELAN_HOME_DIR}/toolchains/"
      rm -f "${lean_zip}"
      trap - EXIT
    fi

    # Rename extracted directory to match elan's naming convention.
    local extracted_dir="${ELAN_HOME_DIR}/toolchains/${lean_archive_name}"
    if [ -d "${extracted_dir}" ] && [ "${extracted_dir}" != "${toolchain_dir}" ]; then
      mv "${extracted_dir}" "${toolchain_dir}"
    fi

    log_elapsed "Lean toolchain installed to ${toolchain_dir}"
  else
    log_elapsed "Lean toolchain already present at ${toolchain_dir}"
  fi

  # Wait for elan background download
  if [ -n "${elan_bg_pid}" ]; then
    if wait "${elan_bg_pid}" 2>/dev/null; then
      log_elapsed "elan binary download complete (SHA-256 verified)"
    else
      log_elapsed "warning: elan binary download failed; toolchain symlinks will be used instead"
    fi
  fi

  # Create direct symlinks so lean/lake/leanc are on PATH immediately
  for bin in lean lake leanc leanmake; do
    if [ -x "${toolchain_dir}/bin/${bin}" ] && [ ! -e "${elan_bin_dir}/${bin}" ]; then
      ln -sf "${toolchain_dir}/bin/${bin}" "${elan_bin_dir}/${bin}"
    fi
  done

  # Register toolchain with elan via symlink
  # shellcheck disable=SC1090
  source "${ELAN_ENV_FILE}"
  if command -v elan >/dev/null 2>&1; then
    elan toolchain link "${TOOLCHAIN}" "${toolchain_dir}" 2>/dev/null || true
    elan default "${TOOLCHAIN}" 2>/dev/null || true
  fi

  mkdir -p "${ELAN_HOME_DIR}/update-hashes"
  echo "manual-install" > "${ELAN_HOME_DIR}/update-hashes/${TOOLCHAIN_DIR_NAME}"
}

# -------- Main installation flow --------
source_elan_env() {
  if [ -f "${ELAN_ENV_FILE}" ]; then
    # shellcheck disable=SC1090
    source "${ELAN_ENV_FILE}"
  fi
}

source_elan_env
TOOLCHAIN_FRESHLY_INSTALLED=0

local_tc_dir="${ELAN_HOME_DIR}/toolchains/${TOOLCHAIN_DIR_NAME}"
if [ ! -x "${local_tc_dir}/bin/lean" ]; then
  log_elapsed "installing Lean toolchain ${TOOLCHAIN} (direct download)"
  if manual_curl_install; then
    TOOLCHAIN_FRESHLY_INSTALLED=1
  else
    log_elapsed "direct install failed; falling back to elan installer"
    if ! command -v elan >/dev/null 2>&1; then
      log_elapsed "downloading elan installer"
      elan_installer="$(mktemp)"
      trap 'rm -f "${elan_installer}"' EXIT
      curl -fsSL "${ELAN_INSTALLER_URL}" -o "${elan_installer}"
      installer_sha256="$(compute_sha256 "${elan_installer}")"
      if [ "${installer_sha256}" != "${ELAN_INSTALLER_SHA256}" ]; then
        echo "error: elan installer checksum verification failed" >&2
        exit 1
      fi
      if ! sh "${elan_installer}" -y --no-modify-path; then
        echo "error: both direct install and elan installer failed" >&2
        exit 1
      fi
      rm -f "${elan_installer}"
      trap - EXIT
    fi
    ensure_elan_env_file
    source_elan_env
    if command -v elan >/dev/null 2>&1 && [ ! -d "${local_tc_dir}/bin" ]; then
      elan toolchain install "${TOOLCHAIN}" 2>/dev/null || true
    fi
    elan default "${TOOLCHAIN}" 2>/dev/null || true
    TOOLCHAIN_FRESHLY_INSTALLED=1
  fi
else
  log_elapsed "Lean toolchain ${TOOLCHAIN} is already installed"
fi

ensure_elan_env_file
source_elan_env

if ! command -v lake >/dev/null 2>&1; then
  echo "error: lake is still not on PATH after setup" >&2
  exit 1
fi

# -------- CRT startup files verification --------
if [ "${TOOLCHAIN_FRESHLY_INSTALLED}" -eq 1 ]; then
  verify_crt_files() {
    local tc_dir="${ELAN_HOME_DIR}/toolchains/${TOOLCHAIN_DIR_NAME}"
    local missing=0
    for crt_file in crti.o crt1.o Scrt1.o; do
      if [ ! -f "${tc_dir}/lib/${crt_file}" ]; then
        missing=1
        break
      fi
    done
    if [ "${missing}" -eq 1 ]; then
      echo "[setup] warning: CRT startup files missing; re-downloading toolchain" >&2
      rm -rf "${tc_dir}"
      manual_curl_install
      source_elan_env
      for crt_file in crti.o crt1.o Scrt1.o; do
        if [ ! -f "${tc_dir}/lib/${crt_file}" ]; then
          echo "[setup] warning: ${crt_file} still missing; linking may fail" >&2
          if command -v apt-get >/dev/null 2>&1; then
            apt_update_once
            run_pkg_install env DEBIAN_FRONTEND=noninteractive apt-get install -y libc-dev 2>/dev/null || true
          fi
          return 1
        fi
      done
      log_elapsed "CRT files restored successfully"
    fi
    return 0
  }
  verify_crt_files
fi

log_elapsed "Lean environment is ready"
log_elapsed "lake version: $(lake --version)"

configure_lake_cache || true

if [ "${QUIET}" -eq 0 ]; then
  echo "[setup] next steps:"
  echo "  source \"${ELAN_ENV_FILE}\""
  echo "  lake build"
fi

if [ "${BUILD_REQUESTED}" -eq 1 ]; then
  log_elapsed "running lake build"
  (cd "${ROOT_DIR}" && lake build)
fi
