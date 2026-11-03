#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# `astrona test` bootstraps and applies in one go. Wait until the operator and
# the Perses server answer, so the reference solution is not
# applied into a half-started environment.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n perses-operator wait deployment --all --for=condition=Available --timeout=300s
