#!/usr/bin/env bash
source .env
BUILD_ENV="$1_WOW_DIR"
FINAL_DIR="${!BUILD_ENV}"
./.release/release.sh -d
echo "$FINAL_DIR"
cp -r .release/BetterEditMode "$FINAL_DIR/"

#rm -rf "