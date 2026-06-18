# Install ticket-to-pr workflow into VS Code prompts folder.
# Usage: .\install.ps1 [-Workspace <path>] [-Force]
#
#   -Workspace <path>   Install to <path>\.github\prompts\ instead of user prompts
#   -Force              Overwrite config file even if it already exists

param(
    [string]$Workspace,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$WorkflowDir = 'workflows\ticket-to-pr'
$Source = Join-Path $PSScriptRoot $WorkflowDir

if (-not (Test-Path $Source)) {
    Write-Error "$Source not found. Run this script from the repo root."
    exit 1
}

# Determine target directory
if ($Workspace) {
    $Target = Join-Path $Workspace '.github\prompts'
} else {
    $Target = Join-Path $env:APPDATA 'Code\User\prompts'
}

if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}

$files = Get-ChildItem -Path $Source -Filter 't2p-*'
$installed = 0
$skipped = 0
foreach ($file in $files) {
    $dest = Join-Path $Target $file.Name
    if ($file.Name -eq 't2p-config.yaml' -and (Test-Path $dest) -and -not $Force) {
        $skipped++
        Write-Host "  Skipped $($file.Name) (already exists - preserving your settings)"
    } else {
        Copy-Item $file.FullName -Destination $Target -Force
        $installed++
    }
}

Write-Host ""
Write-Host "Installed $installed files to $Target"
if ($skipped -gt 0) {
    Write-Host "Skipped $skipped config file(s) (use -Force to overwrite)"
}
if (-not (Test-Path (Join-Path $Target 't2p-config.yaml'))) {
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Edit $Target\t2p-config.yaml with your settings"
    Write-Host "  2. Run /t2p-PLAN PROJ-123 in Copilot Chat"
} else {
    Write-Host ""
    Write-Host "Run /t2p-PLAN PROJ-123 in Copilot Chat to get started."
}
