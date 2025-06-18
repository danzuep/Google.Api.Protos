#!/bin/bash

# https://github.com/googleapis/gax-dotnet/blob/main/updateprotos.sh
# Updates the protos in Google.Api.CommonProtos/protos

set -e

rm -rf google

git clone --depth=1 --filter=blob:none --no-checkout https://github.com/googleapis/googleapis .
git sparse-checkout init --cone
git sparse-checkout add google/api/*.proto google/rpc/*.proto google/rpc/context/*.proto google/type/*.proto
git checkout
