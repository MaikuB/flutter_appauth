#!/usr/bin/env bash
#
# Rebuilds the vendored AppAuth-JS browser bundle from source.
#
# The output (../assets/appauth.bundle.js and its source map) is committed to
# the repository so consumers of the plugin never need a JavaScript toolchain.
# Re-run this only when bumping the pinned @openid/appauth version in
# package.json, then commit the regenerated assets.
#
# Requirements: Node.js + npm. Versions are pinned via package-lock.json so the
# output is reproducible.
set -euo pipefail

cd "$(dirname "$0")"

# Use a clean, lockfile-exact install for reproducibility.
npm ci

npm run build

echo "Built ../assets/appauth.bundle.js"
