#!/data/data/com.termux/files/usr/bin/bash

if [[ "$#" == 0 ]]; then
	echo "ERROR: Specify package(s) to run tests for as argument"
	echo
	echo "Usage: $0 PACKAGE ..."
	echo
	echo "List of valid packages with tests:"
	find . -mindepth 3 -maxdepth 3 -name tests -type d | sed -ne "s|.*/\(.*\)/tests$|\1|p"
	exit 1
fi

PACKAGES=($@)

for (( i=0; i < ${#PACKAGES[@]}; i++ )); do
	NUM_TESTS=0
	NUM_FAILURES=0
	PACKAGE="${PACKAGES[$i]}"

	TEST_DIR="$(find . -mindepth 2 -maxdepth 2 -name $PACKAGE -type d)/tests"
	if [[ ! -d "$TEST_DIR" ]]; then
		echo "WARN: No tests folder for package $PACKAGE, skipping"
		continue
	fi

	for TEST_SCRIPT in "$TEST_DIR"/*; do
		test -t 1 && printf "\033[32m"
		echo "Running test ${TEST_SCRIPT}..."
		(( NUM_TESTS += 1 ))
		test -t 1 && printf "\033[31m"
		(
			assert_equals() {
				FIRST="$1"
				SECOND="$2"
				if [[ "$FIRST" != "$SECOND" ]]; then
					echo "assertion failed - expected '$FIRST', got '$SECOND'"
					exit 1
				fi
			}
			set -e -u
			. $TEST_SCRIPT
		)
		if [[ $? != 0 ]]; then
			(( NUM_FAILURES += 1 ))
		fi
		test -t 1 && printf "\033[0m"
	done

	echo "$PACKAGE: $NUM_TESTS tests run - $NUM_FAILURES failure(s)"
done
