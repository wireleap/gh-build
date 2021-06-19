#!/bin/sh
set -e

mkdir -p "$HOME/.ssh"
echo "$*" > "$HOME/.ssh/id_rsa"
chmod go-rwx "$HOME/.ssh/id_rsa"
cp helpers/known_hosts "$HOME/.ssh/known_hosts"

