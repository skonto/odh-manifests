#!/usr/bin/env bash

echo "Updating KServe manifests"
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
kserve_dir="$script_dir/../kserve"
tmp_dir="$(mktemp -d)"

git init "$tmp_dir"
cd "$tmp_dir" || exit
git remote add -f origin https://github.com/kserve/kserve.git
git config core.sparseCheckout true
echo "config" >> .git/info/sparse-checkout
git pull origin master

rm -rf "$kserve_dir"
mkdir "$kserve_dir"

mv ./config/* "$kserve_dir"

echo "KServe manifests fetched from upstream"
