function Get-CDriveInfo {

    <#
    .SYNOPSIS
        Retrieves C: drive capacity and free space information.

    .DESCRIPTION
        Returns total, used, and free space for the C: drive on the
        local computer or a specified remote computer.

    .PARAMETER ComputerName
        Computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-CDriveInfo

    .EXAMPLE
        Get-CDriveInfo -ComputerName PC123
    #>

    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {

        if ($ComputerName -eq $env:COMPUTERNAME) {

            $CDrive = Get-CimInstance `
                -ClassName Win32_LogicalDisk `
                -Filter "DeviceID='C:'" `
                -ErrorAction Stop
        }
        else {

            $CDrive = Get-CimInstance `
                -ClassName Win32_LogicalDisk `
                -ComputerName $ComputerName `
                -Filter "DeviceID='C:'" `
                -ErrorAction Stop
        }

        if (-not $CDrive) {
            throw "The C: drive was not returned by the query."
        }

        if ($null -eq $CDrive.Size -or $CDrive.Size -le 0) {
            throw "The C: drive size was unavailable or invalid."
        }

        [PSCustomObject]@{
            ComputerName = $ComputerName

            TotalGB = [math]::Round(
                ($CDrive.Size / 1GB),
                2
            )

            UsedGB = [math]::Round(
                (($CDrive.Size - $CDrive.FreeSpace) / 1GB),
                2
            )

            FreeGB = [math]::Round(
                ($CDrive.FreeSpace / 1GB),
                2
            )

            FreePercent = [math]::Round(
                (($CDrive.FreeSpace / $CDrive.Size) * 100),
                1
            )
        }
    }
    catch {

        Write-Warning (
            "Unable to query C: drive on {0}: {1}" -f
            $ComputerName,
            $_.Exception.Message
        )
    }
}