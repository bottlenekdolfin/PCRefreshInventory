function Get-MappedDriveInventory {

    <#
    .SYNOPSIS
        Retrieves mapped network drives for the currently logged-in user.

    .DESCRIPTION
        Returns persistent mapped drive letters and associated UNC paths
        from the active user's registry profile on a local or remote
        computer.

    .PARAMETER ComputerName
        Computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-MappedDriveInventory

    .EXAMPLE
        Get-MappedDriveInventory -ComputerName PC123
    #>

    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {

        if ($ComputerName -eq $env:COMPUTERNAME) {

            $ComputerSystem = Get-CimInstance `
                -ClassName Win32_ComputerSystem `
                -ErrorAction Stop

            $User = $ComputerSystem.UserName

            if (-not $User) {
                return @()
            }

            $SID = (
                [System.Security.Principal.NTAccount]$User
            ).Translate(
                [System.Security.Principal.SecurityIdentifier]
            ).Value

            $NetworkKey = "Registry::HKEY_USERS\$SID\Network"

            if (-not (Test-Path -LiteralPath $NetworkKey)) {
                return @()
            }

            Get-ChildItem `
                -LiteralPath $NetworkKey `
                -ErrorAction Stop |
            ForEach-Object {

                $DriveMapping = Get-ItemProperty `
                    -LiteralPath $_.PSPath `
                    -ErrorAction SilentlyContinue

                if ($DriveMapping.RemotePath) {

                    [PSCustomObject]@{
                        ComputerName = $ComputerName
                        DriveLetter  = $_.PSChildName
                        Path         = $DriveMapping.RemotePath
                    }
                }
            }
        }
        else {

            Invoke-Command `
                -ComputerName $ComputerName `
                -ErrorAction Stop `
                -ScriptBlock {

                    $ComputerSystem = Get-CimInstance `
                        -ClassName Win32_ComputerSystem `
                        -ErrorAction Stop

                    $User = $ComputerSystem.UserName

                    if (-not $User) {
                        return
                    }

                    $SID = (
                        [System.Security.Principal.NTAccount]$User
                    ).Translate(
                        [System.Security.Principal.SecurityIdentifier]
                    ).Value

                    $NetworkKey = "Registry::HKEY_USERS\$SID\Network"

                    if (-not (Test-Path -LiteralPath $NetworkKey)) {
                        return
                    }

                    Get-ChildItem `
                        -LiteralPath $NetworkKey `
                        -ErrorAction Stop |
                    ForEach-Object {

                        $DriveMapping = Get-ItemProperty `
                            -LiteralPath $_.PSPath `
                            -ErrorAction SilentlyContinue

                        if ($DriveMapping.RemotePath) {

                            [PSCustomObject]@{
                                ComputerName = $env:COMPUTERNAME
                                DriveLetter  = $_.PSChildName
                                Path         = $DriveMapping.RemotePath
                            }
                        }
                    }
                }
        }
    }
    catch {

        Write-Warning (
            "Unable to inventory mapped drives on {0}: {1}" -f
            $ComputerName,
            $_.Exception.Message
        )
    }
}