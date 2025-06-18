# https://github.com/googleapis/gax-dotnet/blob/main/updateprotos.sh

Set-Location "$PSScriptRoot/.."

Remove-Item -Recurse -Force protos

$checkoutProtoPaths = @(
    "google/api/*.proto",
    "google/rpc/*.proto",
    "google/rpc/context/*.proto",
    "google/type/*.proto"
)

git clone --filter=blob:none --no-checkout --depth=1 https://github.com/googleapis/googleapis.git protos
Set-Location protos
git sparse-checkout init --no-cone
git sparse-checkout set $checkoutProtoPaths
git checkout

Set-Location ..
git sparse-checkout disable
git rev-parse --show-toplevel
# git status
