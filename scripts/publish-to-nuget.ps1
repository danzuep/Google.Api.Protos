# ./publish-to-nuget.ps1 -Package "Google.Api.Protos"

param (
    [string] $Package = "Google.Api.Protos",
    [string] $PublishPath = "../publish",
    [string] $GitVersionPropertiesPath = "${PublishPath}/gitversion.properties",
    [string] $TargetConfiguration = "Release",
    [string] $NugetRepository = $env:NEXUS_REPOSITORY,
    [string] $NugetApiKey = $env:NEXUS_KEY
)

# Check if dotnet-outdated-tool is installed and install it if not
function CheckForDotNetGlobalTool([string]$PackageId) {
    if (-not (dotnet tool list --global $PackageId | Select-String -Pattern $PackageId)) {
        Write-Host "Installing global tool: ${PackageId}"
        dotnet tool install --global $PackageId
    }
}

function Get-GitVersionNuGetVersion([string]$PropertiesPath) {
    CheckForDotNetGlobalTool -PackageId "GitVersion.Tool"
    dotnet-gitversion /output dotenv /showvariable SemVer > $PropertiesPath
    if ($LASTEXITCODE -ne 0) {
        throw "GitVersion command failed to generate '$PropertiesPath' file."
    }
    $props = Get-Content $PropertiesPath | ConvertFrom-StringData
    $version = $props.GitVersion_MajorMinorPatch.Trim('''')
    Write-Host "Using GitVersion NuGet version: $version"
    return $version
}

function Pack-Package {
    param(
        [string] $PackageName,
        [string] $Version,
        [string] $Configuration = "Release"
    )
    Write-Output "Building $PackageName version $Version ($Configuration)..."
    dotnet build -c $Configuration -p:Version=$Version
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet build failed for configuration $Configuration"
    }
    Write-Output "Packing $PackageName version $Version ($Configuration)..."
    dotnet pack -c $Configuration --include-source --include-symbols -p:Version=$Version --no-build
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet pack failed for configuration $Configuration"
    }
}

function Push-Package {
    param(
        [string] $PackageName,
        [string] $Version,
        [string] $Repository,
        [string] $ApiKey,
        [string] $PublishPath = "../publish" # "src/$PackageName/bin/"
    )
    $packageFileName = "$PackageName.$Version.symbols.nupkg"
    $packagePath = Join-Path -Path $PublishPath -ChildPath $packageFileName

    if (-not (Test-Path $packagePath)) {
        throw "Package file $packagePath not found"
    }

    Write-Output "Pushing package $packageFileName to $Repository..."
    dotnet nuget push $packagePath -s $Repository -k $ApiKey
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet nuget push failed for package"
    }
}

# Main script execution
$ErrorActionPreference = "Stop"

try {
    if (-not (Test-Path "$PSScriptRoot/../protos")) {
        . "$PSScriptRoot/update-google-protos.ps1"
    }
    $source = "$PSScriptRoot/../src"
    Set-Location $source
    Write-Output "Package name is $Package"
    $version = Get-GitVersionNuGetVersion -PropertiesPath $GitVersionPropertiesPath
    Pack-Package -PackageName $Package -Version $version -Configuration $TargetConfiguration
    Write-Output "Publishing $Package version $version"
    Push-Package -PackageName $Package -Version $version -PublishPath $PublishPath -Repository $NugetRepository -ApiKey $NugetApiKey
    Write-Output "Updating package versions"
    . "$PSScriptRoot/update-package-versions.ps1" -Path $source
    Write-Output "Publish and update completed successfully."
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    Set-Location -Path "$PSScriptRoot/.."
}