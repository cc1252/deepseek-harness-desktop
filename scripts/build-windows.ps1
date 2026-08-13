[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Npm = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
$Npx = Get-Command 'npx.cmd' -ErrorAction SilentlyContinue

if ($null -eq $Npm -or $null -eq $Npx) {
    throw 'npm.cmd and npx.cmd are required. Install Node.js before building.'
}

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

Push-Location $ProjectRoot
try {
    & $Npm.Source run check
    if ($LASTEXITCODE -ne 0) { throw "Source verification failed with exit code $LASTEXITCODE" }

    & $Npm.Source run setup
    if ($LASTEXITCODE -ne 0) { throw "Runtime setup failed with exit code $LASTEXITCODE" }

    & $Npx.Source --no-install electron-builder --win nsis portable --x64 --publish never
    if ($LASTEXITCODE -ne 0) { throw "electron-builder failed with exit code $LASTEXITCODE" }

    & (Join-Path $PSScriptRoot 'package-source.ps1')
    if ($LASTEXITCODE -ne 0) { throw "Source packaging failed with exit code $LASTEXITCODE" }

    $Artifacts = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'dist') -Filter '*.exe' -File |
        Where-Object { $_.Name -match '^DeepSeek-Harness-Desktop-(Setup|Portable)-' } |
        Sort-Object Name

    if ($Artifacts.Count -lt 2) {
        throw 'Expected both installer and portable Windows artifacts.'
    }

    $Manifest = Get-Content -LiteralPath (Join-Path $ProjectRoot 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $SourceArchive = Get-Item -LiteralPath (Join-Path $ProjectRoot "dist\DeepSeek-Harness-Desktop-Source-$($Manifest.version).zip")
    $ReleaseFiles = @($Artifacts) + @($SourceArchive)

    $ChecksumLines = foreach ($Artifact in $ReleaseFiles) {
        $Hash = (Get-Sha256Hex -LiteralPath $Artifact.FullName).ToLowerInvariant()
        "$Hash  $($Artifact.Name)"
    }
    Set-Content -LiteralPath (Join-Path $ProjectRoot 'dist\SHA256SUMS.txt') -Value $ChecksumLines -Encoding ASCII

    Write-Host 'Windows artifacts:'
    $ReleaseFiles | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    Write-Host 'SHA-256 checksums written to dist\SHA256SUMS.txt.'
} finally {
    Pop-Location
}
