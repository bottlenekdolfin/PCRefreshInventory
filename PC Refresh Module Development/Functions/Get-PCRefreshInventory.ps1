function Get-PCRefreshInventory {

    <#
    .SYNOPSIS
        Runs the complete PC refresh inventory.

    .DESCRIPTION
        Collects PlanSwift, PST, mapped-drive, printer, application,
        C: drive, user, and serial-number information. Builds a summary,
        saves the summary to the upload share, and returns the summary
        to the PowerShell console.

    .PARAMETER ComputerName
        Computer to inventory. Defaults to the local computer.

    .EXAMPLE
        Get-PCRefreshInventory

    .EXAMPLE
        Get-PCRefreshInventory -ComputerName PC123
    #>

    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {

        #
        # Collect inventory categories
        #

        $PlanSwiftInfo = @(
            Get-PlanSwiftInventory `
                -ComputerName $ComputerName
        )

        $PSTInfo = @(
            Get-PSTInventory `
                -ComputerName $ComputerName
        )

        $DriveInfo = @(
            Get-MappedDriveInventory `
                -ComputerName $ComputerName
        )

        $PrinterInfo = @(
            Get-PrinterInventory `
                -ComputerName $ComputerName
        )

        $ApplicationInfo = @(
            Get-ApplicationInventory `
                -ComputerName $ComputerName
        )

        $CDriveInfo = Get-CDriveInfo `
            -ComputerName $ComputerName

        #
        # Retrieve the logged-on user and BIOS serial number
        #

        if ($ComputerName -eq $env:COMPUTERNAME) {

            $ComputerSystem = Get-CimInstance `
                -ClassName Win32_ComputerSystem `
                -ErrorAction Stop

            $BIOS = Get-CimInstance `
                -ClassName Win32_BIOS `
                -ErrorAction Stop
        }
        else {

            $ComputerSystem = Get-CimInstance `
                -ClassName Win32_ComputerSystem `
                -ComputerName $ComputerName `
                -ErrorAction Stop

            $BIOS = Get-CimInstance `
                -ClassName Win32_BIOS `
                -ComputerName $ComputerName `
                -ErrorAction Stop
        }

        $User = $ComputerSystem.UserName

        $Serial = if ($BIOS.SerialNumber) {
            $BIOS.SerialNumber.Trim()
        }
        else {
            $null
        }

        #
        # Build the inventory summary
        #

        $Summary = New-InventorySummary `
            -ComputerName $ComputerName `
            -User $User `
            -Serial $Serial `
            -CDriveInfo $CDriveInfo `
            -PlanSwiftInfo $PlanSwiftInfo `
            -PSTInfo $PSTInfo `
            -DriveInfo $DriveInfo `
            -PrinterInfo $PrinterInfo `
            -ApplicationInfo $ApplicationInfo

        #
        # Save the inventory summary
        #

        $RunDate = Get-Date -Format "yyyyMMdd-HHmmss"

        $OutputDirectory = "\\10.232.28.30\upload\Refresh"

        $OutputPath = Join-Path `
            -Path $OutputDirectory `
            -ChildPath "$ComputerName-$RunDate.txt"

        if (-not (Test-Path -LiteralPath $OutputDirectory)) {
            throw "The inventory upload directory is unavailable: $OutputDirectory"
        }

        $Summary |
            Out-File `
                -FilePath $OutputPath `
                -Encoding UTF8 `
                -ErrorAction Stop

        Write-Verbose "Inventory report saved to $OutputPath"

        #
        # Return the summary to the PowerShell console
        #

        return $Summary
    }
catch {

    Write-Error (
        "PC refresh inventory failed for {0}: {1}" -f
        $ComputerName,
        $_.Exception.Message
    )

    throw
}
}