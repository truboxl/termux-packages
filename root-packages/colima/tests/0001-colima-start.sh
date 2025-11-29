#!/bin/bash
set -e -u

pkg install -y root-repo
pkg install -y docker
#pkg install -y colima

#command -v colima || echo "colima is not installed" && exit 1
#colima version
#command -v docker || echo "docker is not installed" && exit 1
#docker --version
#command -v limactl || echo "limactl is not installed" && exit 1
#limactl --version

tmpdir=$(mktemp -d)
pushd "$tmpdir"

colima start
docker run hello-world
docker stop
colima stop

popd
rm -fr "$tmpdir"
