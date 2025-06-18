# ./update-google-protos.ps1

param (
    [string[]] $checkoutProtoPaths = @(
            "google/api/*.proto",
            "google/rpc/*.proto",
            "google/rpc/context/*.proto",
            "google/type/*.proto"
        ),
    [string] $gitUrl = "https://github.com/googleapis/googleapis.git"
)

# https://github.com/googleapis/gax-dotnet/blob/main/updateprotos.sh
function CloneWithGitSparseCheckout {
    param (
        [Parameter(Mandatory = $true)]
        [string]$GitUrl,
        [Parameter(Mandatory = $true)]
        [string[]]$CheckoutProtoPaths,
        [string]$CloneDir = "protos"
    )

    Set-Location "$PSScriptRoot/.."

    if (Test-Path $CloneDir) {
        # Remove-Item -Recurse -Force $CloneDir
        Write-Host "Directory '$CloneDir' already exists. Updating it..."
        git fetch origin; git reset --hard '@{u}'
    }

    git clone --filter=blob:none --no-checkout --depth=1 $GitUrl $CloneDir
    Set-Location $CloneDir

    git sparse-checkout init --no-cone
    git sparse-checkout set $CheckoutProtoPaths
    git checkout

    Set-Location ..
    git sparse-checkout disable
    git rev-parse --show-toplevel
}

CloneWithGitSparseCheckout -GitUrl $gitUrl -CheckoutProtoPaths $checkoutProtoPaths