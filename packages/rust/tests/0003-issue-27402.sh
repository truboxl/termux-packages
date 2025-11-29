#!/bin/bash
# https://github.com/rust-lang/rust/issues/147590
# https://github.com/termux/termux-packages/issues/27402
#
# Expected result:-
# Do not SIGSEGV
set -e -u

#pkg install -y rust

command -v rustdoc || echo "rustdoc is not installed" && exit 1
rustdoc -V
command -v rustc || echo "rustc is not installed" && exit 1
rustc -V

tmpdir=$(mktemp -d)
pushd "$tmpdir"
echo

cat <<-EOL >./test.rs
fn main() {}
EOL
echo "${PWD}/test.rs"
cat "${PWD}/test.rs"
echo

echo "rustdoc --test ./test.rs"
rustdoc --test ./test.rs

popd
rm -fr "$tmpdir"
