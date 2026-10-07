function Get-ComputerInventory {

    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {

        if ($ComputerName -eq $env:COMPUTERNAME) {

            $User = (
                Get-CimInstance Win32_ComputerSystem
            ).UserName

            $Serial = (
                Get-CimInstance Win32_BIOS
            ).SerialNumber

        }
        else {

            $User = (
                Get-CimInstance `
                    Win32_ComputerSystem `
                    -ComputerName $ComputerName
            ).UserName

            $Serial = (
                Get-CimInstance `
                    Win32_BIOS `
                    -ComputerName $ComputerName
            ).SerialNumber

        }

        [PSCustomObject]@{
            ComputerName = $ComputerName
            User         = $User
            Serial       = $Serial
            RunDate      = Get-Date -Format "yyyyMMdd-HHmmss"
        }
    }
    catch {

        Write-Warning "Unable to inventory $ComputerName"

    }
}