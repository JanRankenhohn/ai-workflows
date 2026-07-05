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

# --- Interactive config setup ---
$configDest = Join-Path $Target 't2p-config.yaml'
$needsSetup = (-not (Test-Path $configDest)) -or $Force

# Default MCP settings
$mcpServers = @{
    jira = @{ enabled = $false; name = "jira" }
    azure_devops = @{ enabled = $false; name = "ado" }
}

if ($needsSetup) {
    Write-Host ""
    Write-Host "=== t2p Workflow Setup ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Which MCP servers do you have configured?" -ForegroundColor Yellow
    Write-Host ""

    # Jira
    Write-Host "  Enable Jira MCP? Used by /t2p-EXPLORE, /t2p-PLAN, /t2p-REVIEW, /t2p-CREATE-PR."
    Write-Host "  If disabled, the agent will ask you for ticket details instead."
    $jiraChoice = Read-Host "  Enable? (y/N)"
    if ($jiraChoice -match '^[Yy]') {
        $mcpServers.jira.enabled = $true
        $jiraName = Read-Host "  Jira MCP server name (from your mcp.json)"
        if ($jiraName) { $mcpServers.jira.name = $jiraName }
    }

    Write-Host ""

    # Azure DevOps
    Write-Host "  Enable Azure DevOps MCP? Used by /t2p-CREATE-PR."
    Write-Host "  If disabled, you create the PR manually."
    $adoChoice = Read-Host "  Enable? (y/N)"
    if ($adoChoice -match '^[Yy]') {
        $mcpServers.azure_devops.enabled = $true
        $adoName = Read-Host "  Azure DevOps MCP server name (from your mcp.json)"
        if ($adoName) { $mcpServers.azure_devops.name = $adoName }
    }

    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Green
    Write-Host "  Jira:       $(if ($mcpServers.jira.enabled) { "enabled (server: $($mcpServers.jira.name))" } else { 'disabled' })"
    Write-Host "  Azure DevOps: $(if ($mcpServers.azure_devops.enabled) { "enabled (server: $($mcpServers.azure_devops.name))" } else { 'disabled' })"
    Write-Host ""
} else {
    # Read existing config to get MCP names for tool substitution
    $configContent = Get-Content $configDest -Raw
    if ($configContent -match 'jira:\s*\n\s*enabled:\s*(true|false)') {
        $mcpServers.jira.enabled = $Matches[1] -eq 'true'
    }
    if ($configContent -match 'jira:[\s\S]*?name:\s*"([^"]+)"') {
        $mcpServers.jira.name = $Matches[1]
    }
    if ($configContent -match 'azure_devops:\s*\n\s*enabled:\s*(true|false)') {
        $mcpServers.azure_devops.enabled = $Matches[1] -eq 'true'
    }
    if ($configContent -match 'azure_devops:[\s\S]*?name:\s*"([^"]+)"') {
        $mcpServers.azure_devops.name = $Matches[1]
    }
}

# --- Copy and transform files ---
$files = Get-ChildItem -Path $Source -Filter 't2p-*'
$installed = 0
$skipped = 0

foreach ($file in $files) {
    $dest = Join-Path $Target $file.Name

    if ($file.Name -eq 't2p-config.yaml') {
        if ($needsSetup) {
            # Generate config from template + user answers
            $content = Get-Content $file.FullName -Raw
            $content = $content -replace '(jira:\s*\n\s*enabled:\s*)false', "`$1$($mcpServers.jira.enabled.ToString().ToLower())"
            $content = $content -replace '(jira:\s*\n\s*enabled:\s*(?:true|false)\s*#[^\n]*\n\s*name:\s*)"[^"]+"', "`$1`"$($mcpServers.jira.name)`""
            $content = $content -replace '(azure_devops:\s*\n\s*enabled:\s*)false', "`$1$($mcpServers.azure_devops.enabled.ToString().ToLower())"
            $content = $content -replace '(azure_devops:\s*\n\s*enabled:\s*(?:true|false)\s*#[^\n]*\n\s*name:\s*)"[^"]+"', "`$1`"$($mcpServers.azure_devops.name)`""
            Set-Content -Path $dest -Value $content -NoNewline
            $installed++
        } else {
            $skipped++
            Write-Host "  Skipped $($file.Name) (already exists - preserving your settings)"
        }
    } else {
        # Copy prompt file with MCP name substitution
        $content = Get-Content $file.FullName -Raw

        if ($mcpServers.jira.enabled) {
            $content = $content -replace '__JIRA_MCP__', $mcpServers.jira.name
        } else {
            # Remove disabled MCP tool entries from frontmatter tools arrays
            $content = $content -replace '"__JIRA_MCP__/\*",?\s*', ''
            $content = $content -replace '"__JIRA_MCP__",?\s*', ''
        }

        if ($mcpServers.azure_devops.enabled) {
            $content = $content -replace '__ADO_MCP__', $mcpServers.azure_devops.name
        } else {
            $content = $content -replace '"__ADO_MCP__/\*",?\s*', ''
            $content = $content -replace '"__ADO_MCP__",?\s*', ''
        }

        # Clean up trailing commas in tools arrays
        $content = $content -replace ',\s*\]', ']'

        Set-Content -Path $dest -Value $content -NoNewline
        $installed++
    }
}

Write-Host ""
Write-Host "Installed $installed files to $Target" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "Skipped $skipped config file(s) (use -Force to overwrite)"
}
Write-Host ""
Write-Host "Run /t2p-PLAN PROJ-123 in Copilot Chat to get started."
