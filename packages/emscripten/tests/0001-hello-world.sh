#!/bin/bash
set -e

tmpdir=$(mktemp -d)
pushd "$tmpdir"
echo "int main() { return 0; }" > hello1.c
cat <<- EOL > hello2.c
#include <stdio.h>

int main() {
	puts("Hello, World!");
	return 0;
}
EOL
cat <<- EOL > hello3.cpp
#include <iostream>

int main() {
    std::cout << "Hello world!\n";
    return 0;
}
EOL

emcc hello1.c -o hello1.html
emcc hello2.c -o hello2.html
em++ hello3.cpp -o hello3.html

popd
rm -frv "$tmpdir"

emcc -v
em++ -v
