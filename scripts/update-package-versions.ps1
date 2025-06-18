# ./update-package-versions.ps1 -Path "src"

param (
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# Check if dotnet-outdated-tool is installed and install it if not
function CheckForDotNetGlobalTool([string]$PackageId) {
    if (-not (dotnet tool list --global $PackageId | Select-String -Pattern $PackageId)) {
        Write-Host "Installing global tool: ${PackageId}"
        dotnet tool install --global $PackageId
    }
}

# Main script execution
$ErrorActionPreference = "Stop"

try {
    CheckForDotNetGlobalTool -PackageId "dotnet-outdated-tool"

    Write-Host "Updating package versions in directory"

    $dir = Get-Item -Path $Path
    Write-Host $dir.FullName
    Push-Location $dir.FullName
    dotnet outdated -u
    Pop-Location

    $folders = Get-ChildItem -Path $dir -Directory | Where-Object { $_.Name -notin @('bin', 'obj') }
    foreach ($folder in $folders) {
        Write-Host $folder.FullName
        Push-Location $folder.FullName
        dotnet outdated -u
        Pop-Location
    }

    Write-Host "All packages updated to their latest versions"
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}