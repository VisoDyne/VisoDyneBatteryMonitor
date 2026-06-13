[CmdletBinding()]
param(
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$rootPath = $PSScriptRoot
$updatesPath = Join-Path $rootPath 'updates.json'
$releaseDir = Join-Path $rootPath 'Release'
$updateContentsDir = Join-Path $rootPath 'Update contents'

if (-not (Test-Path -LiteralPath $updatesPath)) {
    throw "Could not find updates.json at: $updatesPath"
}

if (-not (Test-Path -LiteralPath $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir | Out-Null
}

if (-not (Test-Path -LiteralPath $updateContentsDir)) {
    New-Item -ItemType Directory -Path $updateContentsDir | Out-Null
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = Read-Host 'Enter the new version number'
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    throw 'Version number cannot be empty.'
}

$invalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars()
if ($Version.IndexOfAny($invalidFileNameChars) -ge 0) {
    throw "Version '$Version' contains invalid filename characters."
}


$parsedUpdates = Get-Content -LiteralPath $updatesPath -Raw | ConvertFrom-Json
if ($null -eq $parsedUpdates) {
    throw 'updates.json must contain at least one update entry.'
}

# Convert both a single object and an array into a predictable array shape.
$updates = @($parsedUpdates)
if ($updates.Count -eq 0) {
    throw 'updates.json must contain at least one update entry.'
}

$updateEntry = $updates[0]
$currentVersion = [string]$updateEntry.version

if ($Version -eq $currentVersion) {
    throw "Version '$Version' matches current version. Provide a different version."
}

$productName = [string]$updateEntry.product
if ([string]::IsNullOrWhiteSpace($productName)) {
    $productName = 'update'
}

$zipName = "$productName-$Version-win64.zip"
$zipPath = Join-Path $releaseDir $zipName

$contentItems = Get-ChildItem -LiteralPath $updateContentsDir -Recurse -File
if ($contentItems.Count -eq 0) {
    throw "No files found in '$updateContentsDir' to include in the release zip."
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $updateContentsDir '*') -DestinationPath $zipPath -Force

if (-not (Test-Path -LiteralPath $zipPath)) {
    throw "Failed to create release zip at: $zipPath"
}

$sha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()

$updateEntry.version = $Version
$updateEntry.checksum = "sha256:$sha256"
$updateEntry.download_url = ''

$jsonOutput = ConvertTo-Json -InputObject $updates -Depth 10
Set-Content -LiteralPath $updatesPath -Value $jsonOutput -Encoding UTF8

Write-Host "Release package created: $zipPath"
Write-Host "Version updated: $currentVersion -> $Version"
Write-Host "Checksum updated in updates.json"
Write-Host "download_url cleared in updates.json"
