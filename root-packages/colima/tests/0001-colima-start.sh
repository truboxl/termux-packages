#!/bin/bash
set -e -u

pkg install -y root-repo
pkg install -y docker
#pkg install -y colima

echo "Package version:"
command -v colima
colima --version
command -v docker
docker --version
command -v limactl
limactl --version

tmpdir=$(mktemp -d)
pushd "$tmpdir"

colima start
docker run hello-world
docker stop
colima stop

popd
rm -fr "$tmpdir"
