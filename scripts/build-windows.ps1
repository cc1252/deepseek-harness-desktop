[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Npm = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
$Npx = Get-Command 'npx.cmd' -ErrorAction SilentlyContinue

if ($null -eq $Npm -or $null -eq $Npx) {
    throw 'npm.cmd and npx.cmd are required. Install Node.js before building.'
}

Push-Location $ProjectRoot
try {
    & $Npm.Source run check
    if ($LASTEXITCODE -ne 0) { throw "Source verification failed with exit code $LASTEXITCODE" }

    & $Npm.Source run setup
    if ($LASTEXITCODE -ne 0) { throw "Runtime setup failed with exit code $LASTEXITCODE" }

    & $Npx.Source --no-install electron-builder --win nsis portable --x64
    if ($LASTEXITCODE -ne 0) { throw "electron-builder failed with exit code $LASTEXITCODE" }

    $Artifacts = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'dist') -Filter '*.exe' -File |
        Where-Object { $_.Name -match '^DeepSeek-Harness-Desktop-(Setup|Portable)-' } |
        Sort-Object Name

    if ($Artifacts.Count -lt 2) {
        throw 'Expected both installer and portable Windows artifacts.'
    }

    $ChecksumLines = foreach ($Artifact in $Artifacts) {
        $Hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Artifact.FullName).Hash.ToLowerInvariant()
        "$Hash  $($Artifact.Name)"
    }
    Set-Content -LiteralPath (Join-Path $ProjectRoot 'dist\SHA256SUMS.txt') -Value $ChecksumLines -Encoding ASCII

    Write-Host 'Windows artifacts:'
    $Artifacts | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    Write-Host 'SHA-256 checksums written to dist\SHA256SUMS.txt.'
} finally {
    Pop-Location
}
