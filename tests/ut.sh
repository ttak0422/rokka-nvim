#!/usr/bin/env bash

cd `dirname $0`
RESULT=$(nix eval --impure --expr 'import ./entry.nix {}')

echo ${RESULT}

[[ "${RESULT}" == "[ ]" ]]
