#!/bin/bash
set -e

pkg install -y root-repo
pkg install -y docker
#pkg install -y colima

command -v colima
limactl -V
command -v docker
docker -V

tmpdir=$(mktemp -d)
pushd "$tmpdir"

colima start
docker run hello-world
docker stop
colima stop

popd
rm -fr "$tmpdir"
