function New-InventorySummary {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [string]$User,

        [string]$Serial,

        [object]$CDriveInfo,

        [object[]]$PlanSwiftInfo,

        [object[]]$PSTInfo,

        [object[]]$DriveInfo,

        [object[]]$PrinterInfo,

        [object[]]$ApplicationInfo
    )

    $Summary = @()

    $Summary += "Run Date: $(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $Summary += "Computer: $ComputerName"

    if ($User) {
        $Summary += "User: $User"
    }
    else {
        $Summary += "User: No user logged in"
    }

    if ($Serial) {
        $Summary += "Serial: $Serial"
    }
    else {
        $Summary += "Serial: Unavailable"
    }

    #
    # Printers
    #

    $Summary += ""
    $Summary += "========== PRINTERS =========="

    if ($PrinterInfo -and $PrinterInfo.Count -gt 0) {

        foreach ($Printer in $PrinterInfo) {

            $PrinterLocation = if ($Printer.Location) {
                $Printer.Location
            }
            else {
                "Not Set"
            }

            $PrinterIP = if ($Printer.IPAddress) {
                $Printer.IPAddress
            }
            else {
                "No IP"
            }

            $Summary += (
                "$($Printer.PrinterName) - " +
                "$PrinterLocation - " +
                "$($Printer.PortName) - " +
                "$PrinterIP - " +
                "$($Printer.DriverName)"
            )
        }
    }
    else {
        $Summary += "No printers found."
    }

    #
    # Mapped Drives
    #

    $Summary += ""
    $Summary += "========== DRIVES =========="

    if ($DriveInfo -and $DriveInfo.Count -gt 0) {

        foreach ($Drive in $DriveInfo) {
            $Summary += "$($Drive.DriveLetter) -> $($Drive.Path)"
        }
    }
    else {
        $Summary += "No shared drives found."
    }

    #
    # PlanSwift
    #

    $Summary += ""
    $Summary += "========== PLANSWIFT =========="

    if ($PlanSwiftInfo -and $PlanSwiftInfo.Count -gt 0) {

        foreach ($Storage in $PlanSwiftInfo) {

            if (-not $Storage.Found) {

                $Summary += (
                    "$($Storage.StorageName): " +
                    "Not Found or Unreachable - " +
                    "$($Storage.DataPath)"
                )
            }
            elseif (
                $Storage.SizeGB -is [double] -or
                $Storage.SizeGB -is [int] -or
                $Storage.SizeGB -is [long] -or
                $Storage.SizeGB -is [decimal]
            ) {

                $Summary += (
                    "$($Storage.StorageName): " +
                    "$($Storage.SizeGB) GB - " +
                    "$($Storage.DataPath)"
                )
            }
            else {

                $Summary += (
                    "$($Storage.StorageName): " +
                    "$($Storage.SizeGB) - " +
                    "$($Storage.DataPath)"
                )
            }
        }
    }
    else {
        $Summary += "No PlanSwift Data Found"
    }

    #
    # PST Files
    #

    $Summary += ""
    $Summary += "========== PST FILES =========="

    if ($PSTInfo -and $PSTInfo.Count -gt 0) {

        $Summary += "PST Files Found: YES"
        $Summary += "PST File Count: $($PSTInfo.Count)"

        $TotalPSTBytes = (
            $PSTInfo |
            Measure-Object `
                -Property SizeBytes `
                -Sum
        ).Sum

        foreach ($PST in $PSTInfo) {

            $Summary += ""
            $Summary += "Name: $($PST.Name)"
            $Summary += "Size: $($PST.SizeGB) GB"
            $Summary += "Location: $($PST.FullName)"
        }

        if ($null -eq $TotalPSTBytes) {
            $TotalPSTBytes = 0
        }

        $Summary += ""
        $Summary += (
            "Total PST Size: {0} GB" -f
            [math]::Round(
                ([double]$TotalPSTBytes / 1GB),
                2
            )
        )
    }
    else {
        $Summary += "PST Files Found: NO"
    }

    #
    # C Drive
    #

    $Summary += ""
    $Summary += "========== C DRIVE =========="

    if ($CDriveInfo) {

        $Summary += "Total Size: $($CDriveInfo.TotalGB) GB"
        $Summary += "Used Space: $($CDriveInfo.UsedGB) GB"
        $Summary += "Free Space: $($CDriveInfo.FreeGB) GB"

        if ($CDriveInfo.PSObject.Properties['FreePercent']) {
            $Summary += "Free Percent: $($CDriveInfo.FreePercent)%"
        }
    }
    else {
        $Summary += "C: drive information unavailable."
    }

    #
    # Applications
    #

    $Summary += ""
    $Summary += "========== APPLICATIONS =========="

    if ($ApplicationInfo -and $ApplicationInfo.Count -gt 0) {

        foreach ($Application in $ApplicationInfo) {
            $Summary += $Application.DisplayName
        }
    }
    else {
        $Summary += "No applications found."
    }

    return $Summary
}