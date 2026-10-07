function Get-ApplicationInventory {

    <#
    .SYNOPSIS
        Retrieves installed applications.

    .DESCRIPTION
        Retrieves software registered in both the 64-bit and
        32-bit uninstall registry locations.

    .PARAMETER ComputerName
        Computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-ApplicationInventory

    .EXAMPLE
        Get-ApplicationInventory -ComputerName PC123
    #>

    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {

        if ($ComputerName -eq $env:COMPUTERNAME) {

            Get-ItemProperty `
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", `
                "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
                -ErrorAction SilentlyContinue |
            Where-Object {
                $_.DisplayName
            } |
            Select-Object `
                @{Name = 'ComputerName'; Expression = { $ComputerName }},
                DisplayName,
                DisplayVersion |
            Sort-Object DisplayName, DisplayVersion -Unique
        }
        else {

            Invoke-Command `
                -ComputerName $ComputerName `
                -ErrorAction Stop `
                -ScriptBlock {

                    Get-ItemProperty `
                        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", `
                        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
                        -ErrorAction SilentlyContinue |
                    Where-Object {
                        $_.DisplayName
                    } |
                    Select-Object `
                        @{Name = 'ComputerName'; Expression = { $env:COMPUTERNAME }},
                        DisplayName,
                        DisplayVersion |
                    Sort-Object DisplayName, DisplayVersion -Unique
                }
        }
    }
    catch {

        Write-Warning (
            "Unable to inventory applications on {0}: {1}" -f
            $ComputerName,
            $_.Exception.Message
        )
    }
}