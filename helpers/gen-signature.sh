#!/bin/sh
set -e

fatal() { echo "FATAL [$(basename $0)]: $@" 1>&2; exit 1; }
info() { echo "INFO [$(basename $0)]: $@"; }

usage() {
cat<<EOF
Syntax: $0 filepath
Generate hash file for filepath and check if it verifies

Arguments:

    filepath        - path to file to be signed

EOF
exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

filepath=$1
filename=$(basename $1)

info "generating sha256sum"
SHA256SUM="$(sha256sum $filepath | cut -d " " -f 1)  $filename"

info "generating sha512sum"
SHA512SUM="$(sha512sum $filepath | cut -d " " -f 1)  $filename"

info "writing $filepath.hash"
cat > $filepath.hash <<EOF
To ensure the binary has not been corrupted in transit or tampered with,
perform the following two steps to cryptographically verify binary integrity:

1. Verify the authenticity of this file by checking that it is signed with our
   GPG release key (the signature date might differ but the fingerprint must
   be identical to the one specified here):

    $ gpg --recv-keys --keyserver pool.sks-keyservers.net 693C86E9DECA9D07D79FF9D22ECD72AD056012E1
    $ gpg --list-keys --with-fingerprint builds@wireleap.com
      pub   rsa4096 2021-03-26 [SC]
            693C 86E9 DECA 9D07 D79F  F9D2 2ECD 72AD 0560 12E1
      uid           [unknown] Wireleap CI Automated Build Signing Key <builds@wireleap.com>
      sub   rsa4096 2021-03-26 [E]
    $ gpg --verify $filename.hash
      gpg: Signature made Fri Mar 26 13:38:53 2021 UTC
      gpg:                using RSA key 693C86E9DECA9D07D79FF9D22ECD72AD056012E1
      gpg: Good signature from "Wireleap CI Automated Build Signing Key <builds@wireleap.com>" [unknown]
      gpg: WARNING: This key is not certified with a trusted signature!
      gpg:          There is no indication that the signature belongs to the owner.
      Primary key fingerprint: 693C 86E9 DECA 9D07 D79F  F9D2 2ECD 72AD 0560 12E1

2. Recalculate the binary hash and make sure it matches your choice of hash below.

    $ sha256sum $filename
      $SHA256SUM

    $ sha512sum $filename
      $SHA512SUM

   Note, you can compare hashes automatically::

    $ sha256sum -c $filename.hash
      $filename: OK

    $ sha512sum -c $filename.hash
      $filename: OK

EOF

info "signing $filepath.hash"
gpg --local-user 693C86E9DECA9D07D79FF9D22ECD72AD056012E1 --output "$filepath.hash.asc" --clearsign "$filepath.hash"
mv "$filepath.hash.asc" "$filepath.hash"

info "verifying gpg signature"
gpg --verify --batch "$filepath.hash"

info "verifying checksum"

# for sha*sum to work as it looks in . for the file to check
dir="$(dirname "$filepath")"

if [ "$dir" != '.' ]; then
    cd "$dir"
fi

sha256sum -c "$filename.hash"
sha512sum -c "$filename.hash"
info "signed and verified successfully"
