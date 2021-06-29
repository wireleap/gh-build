#!/bin/sh
set -e

SCRIPT_NAME="$(basename "$0")"

fatal() { echo "FATAL [$SCRIPT_NAME]: $*" 1>&2; exit 1; }
info() { echo "INFO [$SCRIPT_NAME]: $*"; }

usage() {
cat<<EOF
Syntax: $SCRIPT_NAME /path/to/outdir linux|darwin|all
Helper script to compile components (inside docker) and build release dist binaries

EOF
exit 1
}

[ -n "$1" ] || usage

command -v docker >/dev/null || fatal "docker not installed"

AUXDIR="$(dirname "$(realpath "$0")")"
SRCDIR="$(realpath "$1")"
OUTDIR="$(realpath "$2")"

case "$3" in
    linux|darwin)   TARGETS="$3";;
    all)            TARGETS="linux darwin";;
    *)              fatal "target_os not specified or supported: $3";;
esac

for target_os in $TARGETS; do
    info "building for: $target_os"
    arch=$target_os-amd64
    mkdir -p "$OUTDIR/.deps"
    DEPS_CACHE="$OUTDIR/.deps" TARGET_OS="$target_os" BUILD_TAGS="upgrade" \
        "$SRCDIR/contrib/docker/build-bin.sh" "$OUTDIR"
    cd "$OUTDIR"
    for bin in *; do
        if echo "$(basename "$bin")" | grep -q '_\|\.hash$'; then
            continue
        fi
        mv "$bin" "${bin}_${arch}"
        "$AUXDIR/gen-signature.sh" "${bin}_${arch}"
    done
    cd -
done

