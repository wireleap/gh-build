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
    name=$target_os-amd64
    mkdir -p "$OUTDIR/.deps" "$OUTDIR/$name"
    DEPS_CACHE="$OUTDIR/.deps" TARGET_OS="$target_os" BUILD_TAGS="upgrade" \
        "$SRCDIR/contrib/docker/build-bin.sh" "$OUTDIR/$name"

    version="$("$SRCDIR"/contrib/gitversion.sh)"
    minor="$(echo "$version" | cut -d'.' -f1-2)"

    cd "$OUTDIR/$name"
    for bin in *; do
        "$AUXDIR/gen-signature.sh" "$bin"
        echo "# $bname" >> changelog.md
        cat "$SRCDIR/changelogs/$minor/$(basename "$bin").md" >> changelog.md
        echo >> changelog.md
    done
done

