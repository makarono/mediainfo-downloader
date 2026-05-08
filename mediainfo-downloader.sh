#!/usr/bin/env bash
set -e

MEDIAINFO_VERSION="release"
MEDIAINFO_ARCHITECTURE="amd64"
DOWNLOAD_DIR="mediainfo-bin"
LIB_DIR=""
DOWNLOADED_ARCHIVE="mediainfo.zip"
CLEANUP_FILES=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -v | --version)
    MEDIAINFO_VERSION=$2
    shift 2
    ;;
  -a | --architecture)
    MEDIAINFO_ARCHITECTURE=$2
    shift 2
    ;;
  -d | --dir)
    DOWNLOAD_DIR=$2
    shift 2
    ;;
  -l | --lib-dir)
    LIB_DIR=$2
    shift 2
    ;;
  -c | --cleanup)
    CLEANUP_FILES=true
    shift
    ;;
  -h | --help)
    echo "Usage: $0 [-v|--version <version>] [-a|--architecture <architecture>] [-d|--dir <download_directory>] [-l|--lib-dir <lib_directory>] [-c|--cleanup] [-h|--help]"
    echo "  version:      release (latest) or YY.MM eg. 25.10"
    echo "  architecture: amd64, arm64"
    echo "  lib-dir:      if set, also downloads libmediainfo.so to this directory"
    exit 0
    ;;
  *)
    echo "Error: invalid argument: $1"
    exit 1
    ;;
  esac
done

function get_latest_version() {
  curl -s https://api.github.com/repos/MediaArea/MediaInfo/releases/latest \
    | grep '"tag_name"' \
    | sed 's/.*"v\([^"]*\)".*/\1/'
}

function check_installed() {
  local program="${1}"
  if command -v "$program" >/dev/null 2>&1; then
    echo "$program is installed on this system."
  else
    echo "$program is not installed on this system."
  fi
}

function download() {
  local url="${1}"
  local output="${2}"
  echo "$url"
  check_installed curl
  curl -L "$url" --output "$output"
}

function extract_cli() {
  local archive="${1}"
  check_installed unzip
  [ -d "$DOWNLOAD_DIR" ] || mkdir -p "$DOWNLOAD_DIR"
  unzip -jo "$archive" "bin/mediainfo" -d "$DOWNLOAD_DIR" && rm -f "$archive" && echo "mediainfo is ready in: $DOWNLOAD_DIR"
}

function extract_lib() {
  local archive="${1}"
  check_installed unzip
  [ -d "$LIB_DIR" ] || mkdir -p "$LIB_DIR"
  unzip -jo "$archive" "lib/*" -d "$LIB_DIR" && rm -f "$archive" && echo "libmediainfo is ready in: $LIB_DIR"
}

case "$MEDIAINFO_ARCHITECTURE" in
amd64 | x86_64)
  ARCH="x86_64"
  ;;
arm64 | aarch64)
  ARCH="arm64"
  ;;
*)
  echo "unsupported architecture: $MEDIAINFO_ARCHITECTURE" >&2
  exit 1
  ;;
esac

case "$MEDIAINFO_VERSION" in
release)
  VERSION=$(get_latest_version)
  echo "Downloading latest MediaInfo version: $VERSION for architecture: $MEDIAINFO_ARCHITECTURE to directory: $DOWNLOAD_DIR"
  ;;
[0-9.]*)
  VERSION="$MEDIAINFO_VERSION"
  echo "Downloading specific MediaInfo version: $VERSION for architecture: $MEDIAINFO_ARCHITECTURE to directory: $DOWNLOAD_DIR"
  ;;
help)
  echo "download latest version for amd64: $0" >&2
  echo "download specific version: $0 --version 25.10" >&2
  echo "download specific version and architecture: $0 --version 25.10 --architecture arm64" >&2
  exit 1
  ;;
*)
  echo '$MEDIAINFO_VERSION must be release or version number eg. 25.10' >&2
  exit 1
  ;;
esac

CLI_URL="https://mediaarea.net/download/binary/mediainfo/${VERSION}/MediaInfo_CLI_${VERSION}_Lambda_${ARCH}.zip"
DLL_URL="https://mediaarea.net/download/binary/libmediainfo0/${VERSION}/MediaInfo_DLL_${VERSION}_Lambda_${ARCH}.zip"

download "$CLI_URL" "$DOWNLOADED_ARCHIVE" && extract_cli "$DOWNLOADED_ARCHIVE"

if [ -n "$LIB_DIR" ]; then
  download "$DLL_URL" "mediainfo-dll.zip" && extract_lib "mediainfo-dll.zip"
fi
