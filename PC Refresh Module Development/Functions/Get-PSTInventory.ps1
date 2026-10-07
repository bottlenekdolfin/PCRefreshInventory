function Get-PSTInventory {

    <#
    .SYNOPSIS
        Finds Outlook PST files for the currently logged-in user.

    .DESCRIPTION
        Searches common Outlook PST locations for the logged-in user
        and returns file details including size and path.

    .PARAMETER ComputerName
        Computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-PSTInventory

    .EXAMPLE
        Get-PSTInventory -ComputerName PC123
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
                return
            }

            $UserName = $User.Split('\')[-1]

            $PSTLocations = @(
                "C:\Users\$UserName\Documents\Outlook Files"
                "C:\Users\$UserName\AppData\Local\Microsoft\Outlook"
            )
        }
        else {

            $ComputerSystem = Get-CimInstance `
                -ClassName Win32_ComputerSystem `
                -ComputerName $ComputerName `
                -ErrorAction Stop

            $User = $ComputerSystem.UserName

            if (-not $User) {
                return
            }

            $UserName = $User.Split('\')[-1]

            $PSTLocations = @(
                "\\$ComputerName\C$\Users\$UserName\Documents\Outlook Files"
                "\\$ComputerName\C$\Users\$UserName\AppData\Local\Microsoft\Outlook"
            )
        }

        $PSTFiles = @()

        foreach ($PSTLocation in $PSTLocations) {

            if (-not (Test-Path -LiteralPath $PSTLocation)) {
                continue
            }

            $PSTFiles += Get-ChildItem `
                -LiteralPath $PSTLocation `
                -Filter "*.pst" `
                -File `
                -Recurse `
                -ErrorAction SilentlyContinue
        }

        $PSTFiles |
        Sort-Object FullName -Unique |
        ForEach-Object {

            [PSCustomObject]@{
                ComputerName = $ComputerName
                Name         = $_.Name
                SizeBytes    = $_.Length
                SizeGB       = [math]::Round(
                    ($_.Length / 1GB),
                    2
                )
                FullName     = $_.FullName
            }
        }
    }
    catch {

        Write-Warning (
            "Unable to inventory PST files on {0}: {1}" -f
            $ComputerName,
            $_.Exception.Message
        )
    }
}