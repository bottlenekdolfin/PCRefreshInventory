function Get-PrinterInventory {

    <#
    .SYNOPSIS
        Retrieves installed printers.

    .DESCRIPTION
        Returns printer name, driver, location, port information,
        and IP address when available for local or remote computers.

    .PARAMETER ComputerName
        Computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-PrinterInventory

    .EXAMPLE
        Get-PrinterInventory -ComputerName PC123
    #>

    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {

        if ($ComputerName -eq $env:COMPUTERNAME) {

            Get-Printer -ErrorAction Stop |
            ForEach-Object {

                $Printer = $_

                $Port = Get-PrinterPort `
                    -Name $Printer.PortName `
                    -ErrorAction SilentlyContinue

                $IPAddress = $null

                if (
                    $Port -and
                    $Port.PSObject.Properties['PrinterHostAddress']
                ) {
                    $IPAddress = $Port.PrinterHostAddress
                }

                [PSCustomObject]@{
                    ComputerName = $ComputerName
                    PrinterName  = $Printer.Name
                    DriverName   = $Printer.DriverName
                    Location     = $Printer.Location
                    PortName     = $Printer.PortName
                    PortType     = if ($Port) {
                        $Port.GetType().Name
                    }
                    else {
                        $null
                    }
                    IPAddress    = $IPAddress
                }
            }
        }
        else {

            Invoke-Command `
                -ComputerName $ComputerName `
                -ErrorAction Stop `
                -ScriptBlock {

                    Get-Printer -ErrorAction Stop |
                    ForEach-Object {

                        $Printer = $_

                        $Port = Get-PrinterPort `
                            -Name $Printer.PortName `
                            -ErrorAction SilentlyContinue

                        $IPAddress = $null

                        if (
                            $Port -and
                            $Port.PSObject.Properties['PrinterHostAddress']
                        ) {
                            $IPAddress = $Port.PrinterHostAddress
                        }

                        [PSCustomObject]@{
                            ComputerName = $env:COMPUTERNAME
                            PrinterName  = $Printer.Name
                            DriverName   = $Printer.DriverName
                            Location     = $Printer.Location
                            PortName     = $Printer.PortName
                            PortType     = if ($Port) {
                                $Port.GetType().Name
                            }
                            else {
                                $null
                            }
                            IPAddress    = $IPAddress
                        }
                    }
                }
        }
    }
    catch {

        Write-Warning (
            "Unable to inventory printers on {0}: {1}" -f
            $ComputerName,
            $_.Exception.Message
        )
    }
}
