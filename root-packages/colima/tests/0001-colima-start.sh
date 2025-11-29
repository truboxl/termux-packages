#!/bin/bash
set -e

pkg install -y root-repo
pkg install -y docker
#pkg install -y colima

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
