# Build-SingleScript.ps1

$ModuleRoot = $PSScriptRoot
$FunctionFolder = Join-Path $ModuleRoot "Functions"
$OutputFolder = Join-Path $ModuleRoot "Output"

$OutputFile = Join-Path $OutputFolder "PCRefreshInventory-Standalone.ps1"

# Create output folder if needed
if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Start fresh
if (Test-Path $OutputFile) {
    Remove-Item $OutputFile -Force
}

$Header = @"
# =================================================================
# PC Refresh Inventory Standalone Script
# Generated: $(Get-Date)
# =================================================================

"@

Set-Content -Path $OutputFile -Value $Header

# Add all helper functions first
Get-ChildItem "$FunctionFolder\*.ps1" |
    Where-Object { $_.Name -ne 'Get-PCRefreshInventory.ps1' } |
    Sort-Object Name |
    ForEach-Object {

        Add-Content $OutputFile "`r`n# ===== $($_.Name) =====`r`n"
        Get-Content $_.FullName | Add-Content $OutputFile
        Add-Content $OutputFile "`r`n"
    }

# Add main function last
$MainFunction = Join-Path $FunctionFolder 'Get-PCRefreshInventory.ps1'

if (Test-Path $MainFunction) {
    Add-Content $OutputFile "`r`n# ===== Get-PCRefreshInventory.ps1 =====`r`n"
    Get-Content $MainFunction | Add-Content $OutputFile
}

Write-Host "Created: $OutputFile" -ForegroundColor Green