[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$NodeVersion = '24.19.0'
$NodeArchiveName = "node-v$NodeVersion-win-x64.zip"
$NodeReleaseBase = "https://nodejs.org/dist/v$NodeVersion"
$PinnedNodeArchiveSha256 = '57F71AB3652E797D84ACDDC79C81CC9FF1C6DDB2A1974CDB83F00FEE9BFF4C73'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$HarnessRoot = Join-Path $ProjectRoot 'harness'
$HarnessManifest = Join-Path $HarnessRoot 'package.json'
$HarnessLock = Join-Path $HarnessRoot 'package-lock.json'
$HarnessModules = Join-Path $HarnessRoot 'node_modules'
$DshManifest = Join-Path $HarnessModules '@deepseek-ai\dsh\package.json'
$OfficialIcon = Join-Path $HarnessModules '@deepseek-ai\dsh-web-frontend\dist\favicon.svg'
$BuildIcon = Join-Path $ProjectRoot 'build\deepseek-harness.svg'
$RuntimeRoot = Join-Path $HarnessRoot 'runtime'
$RuntimeNode = Join-Path $RuntimeRoot 'node.exe'

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $Algorithm = [System.Security.Cryptography.SHA256]::Create()
    $Stream = [System.IO.File]::Open(
        $LiteralPath,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read
    )
    try {
        return ([System.BitConverter]::ToString($Algorithm.ComputeHash($Stream))).Replace('-', '')
    } finally {
        $Stream.Dispose()
        $Algorithm.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $HarnessManifest)) {
    throw "Harness manifest is missing: $HarnessManifest"
}

if (-not (Test-Path -LiteralPath $HarnessLock)) {
    throw "Harness lockfile is missing: $HarnessLock"
}

$HarnessPackage = Get-Content -LiteralPath $HarnessManifest -Raw -Encoding UTF8 | ConvertFrom-Json
$ExpectedDshVersion = [string]$HarnessPackage.dependencies.'@deepseek-ai/dsh'

function Test-HarnessInstall {
    if (-not (Test-Path -LiteralPath $DshManifest)) { return $false }
    try {
        $Installed = Get-Content -LiteralPath $DshManifest -Raw -Encoding UTF8 | ConvertFrom-Json
        return [string]$Installed.version -eq $ExpectedDshVersion
    } catch {
        return $false
    }
}

function Test-NodeRuntime {
    if (-not (Test-Path -LiteralPath $RuntimeNode)) { return $false }
    try {
        $InstalledVersion = (& $RuntimeNode --version).TrimStart('v').Trim()
        return $InstalledVersion -eq $NodeVersion
    } catch {
        return $false
    }
}

if ($Force -or -not (Test-HarnessInstall)) {
    $Npm = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
    if ($null -eq $Npm) {
        throw 'npm.cmd was not found. Install Node.js before preparing the project.'
    }

    Write-Host "Installing @deepseek-ai/dsh $ExpectedDshVersion from the committed lockfile..."
    Push-Location $HarnessRoot
    try {
        & $Npm.Source ci --omit=dev --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw "npm ci failed with exit code $LASTEXITCODE" }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "Harness runtime dependencies are already prepared ($ExpectedDshVersion)."
}

if (-not (Test-Path -LiteralPath $OfficialIcon)) {
    throw "The official Harness icon was not found after installation: $OfficialIcon"
}

New-Item -ItemType Directory -Path (Split-Path -Parent $BuildIcon) -Force | Out-Null
Copy-Item -LiteralPath $OfficialIcon -Destination $BuildIcon -Force

if ($Force -or -not (Test-NodeRuntime)) {
    $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("deepseek-harness-desktop-" + [Guid]::NewGuid().ToString('N'))
    $ArchivePath = Join-Path $TempRoot $NodeArchiveName
    $ChecksumsPath = Join-Path $TempRoot 'SHASUMS256.txt'
    $ExtractRoot = Join-Path $TempRoot 'extracted'

    New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
    try {
        Write-Host "Downloading Node.js v$NodeVersion for Windows x64..."
        Invoke-WebRequest -UseBasicParsing -Uri "$NodeReleaseBase/$NodeArchiveName" -OutFile $ArchivePath
        Invoke-WebRequest -UseBasicParsing -Uri "$NodeReleaseBase/SHASUMS256.txt" -OutFile $ChecksumsPath

        $EscapedArchiveName = [Regex]::Escape($NodeArchiveName)
        $ChecksumLine = Get-Content -LiteralPath $ChecksumsPath | Where-Object {
            $_ -match "^([0-9a-fA-F]{64})\s+\*?$EscapedArchiveName$"
        } | Select-Object -First 1

        if ($null -eq $ChecksumLine) {
            throw "No SHA-256 entry was found for $NodeArchiveName"
        }

        $PublishedHash = ([Regex]::Match($ChecksumLine, '^([0-9a-fA-F]{64})')).Groups[1].Value.ToUpperInvariant()
        if ($PublishedHash -ne $PinnedNodeArchiveSha256) {
            throw "The published Node.js checksum differs from the pinned release checksum. Pinned $PinnedNodeArchiveSha256, published $PublishedHash"
        }

        $ActualHash = (Get-Sha256Hex -LiteralPath $ArchivePath).ToUpperInvariant()
        if ($ActualHash -ne $PinnedNodeArchiveSha256) {
            throw "Node.js checksum mismatch. Expected $PinnedNodeArchiveSha256, received $ActualHash"
        }

        Write-Host "Verified Node.js archive SHA-256: $ActualHash"
        Expand-Archive -LiteralPath $ArchivePath -DestinationPath $ExtractRoot -Force
        $ExpandedRoot = Join-Path $ExtractRoot "node-v$NodeVersion-win-x64"

        New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $ExpandedRoot 'node.exe') -Destination $RuntimeNode -Force
        Copy-Item -LiteralPath (Join-Path $ExpandedRoot 'LICENSE') -Destination (Join-Path $RuntimeRoot 'NODE-LICENSE.txt') -Force
        Copy-Item -LiteralPath $ChecksumsPath -Destination (Join-Path $RuntimeRoot 'SHASUMS256.txt') -Force
    } finally {
        if (Test-Path -LiteralPath $TempRoot) {
            Remove-Item -LiteralPath $TempRoot -Recurse -Force
        }
    }
} else {
    Write-Host "Bundled Node.js runtime is already prepared (v$NodeVersion)."
}

& (Get-Command 'node.exe').Source (Join-Path $ProjectRoot 'scripts\generate-third-party-notices.mjs')
if ($LASTEXITCODE -ne 0) { throw "Third-party notice generation failed with exit code $LASTEXITCODE" }

Write-Host 'Runtime preparation complete.'
