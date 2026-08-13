[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Manifest = Get-Content -LiteralPath (Join-Path $ProjectRoot 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$DistRoot = Join-Path $ProjectRoot 'dist'
$ArchivePath = Join-Path $DistRoot "DeepSeek-Harness-Desktop-Source-$($Manifest.version).zip"
$Git = Get-Command 'git.exe' -ErrorAction SilentlyContinue

if ($null -eq $Git) { throw 'git.exe is required to create the source archive.' }

Push-Location $ProjectRoot
try {
    $InsideWorkTree = (& $Git.Source rev-parse --is-inside-work-tree).Trim()
    if ($LASTEXITCODE -ne 0 -or $InsideWorkTree -ne 'true') {
        throw 'Source packaging must run inside a Git worktree.'
    }

    New-Item -ItemType Directory -Path $DistRoot -Force | Out-Null
    & $Git.Source archive --format=zip --output=$ArchivePath HEAD
    if ($LASTEXITCODE -ne 0) { throw "git archive failed with exit code $LASTEXITCODE" }

    Write-Host "Source archive: $ArchivePath"
} finally {
    Pop-Location
}
