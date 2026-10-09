#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
wally install
mkdir -p dist
darklua process src/main.luau dist/redliner.lua --config .darklua.json
test -s dist/redliner.lua
