# Install ticket-to-pr workflow into VS Code prompts folder.
# Usage: .\install.ps1 [-Workspace <path>]
#
#   -Workspace <path>   Install to <path>\.github\prompts\ instead of user prompts

param(
    [string]$Workspace
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
foreach ($file in $files) {
    Copy-Item $file.FullName -Destination $Target -Force
}

Write-Host "Installed $($files.Count) files to $Target"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit $Target\t2p-config.yaml with your settings"
Write-Host "  2. Run /t2p-PLAN PROJ-123 in Copilot Chat"
