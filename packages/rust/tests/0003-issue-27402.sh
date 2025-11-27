#!/bin/bash
# https://github.com/rust-lang/rust/issues/147590
# https://github.com/termux/termux-packages/issues/27402
#
# Unexpected output:-
# Error: diagnostic error detected
#
# Expected output:-
set -e

#pkg install -y rust

tmpdir=$(mktemp -d)
pushd "$tmpdir"
echo

cat <<-EOL >>./test.rs
fn main() {}
EOL
echo "${PWD}/test.rs"
cat "${PWD}/test.rs"
echo

echo "rustdoc --test ./test.rs"
rustdoc --test ./test.rs

popd
rm -fr "$tmpdir"
echo

command -v rustdoc
rustdoc -V
command -v rustc
rustc -V
