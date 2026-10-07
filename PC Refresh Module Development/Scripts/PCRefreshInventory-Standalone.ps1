# =================================================================
# PC Refresh Inventory Standalone Script
# Generated: 10/07/2026 15:35:41
# =================================================================


# ===== Get-ApplicationInventory.ps1 =====

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



# ===== Get-CDriveInfo.ps1 =====

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



# ===== Get-MappedDriveInventory.ps1 =====

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



# ===== Get-PlanSwiftInventory.ps1 =====


function Get-PlanSwiftInventory {
 
[CmdletBinding()]
param(
[string]$ComputerName = $env:COMPUTERNAME
)
 
$IsLocal = $ComputerName -eq $env:COMPUTERNAME

#Write-Host "ComputerName: $ComputerName"
#Write-Host "Local PC: $env:COMPUTERNAME"
#Write-Host "IsLocal: $IsLocal"

if ($IsLocal) {

    $StorageRoot =
        "C:\Program Files (x86)\PlanSwift10\Data\Storages"

    $LocalJobsPath =
        "C:\Program Files (x86)\PlanSwift10\Data\Storages\Local\Jobs"

}
else {

    $StorageRoot =
        "\\$ComputerName\C$\Program Files (x86)\PlanSwift10\Data\Storages"

    $LocalJobsPath =
        "\\$ComputerName\C$\Program Files (x86)\PlanSwift10\Data\Storages\Local\Jobs"

}
 

    if (-not (Test-Path $StorageRoot)) {
        return @()
    }

    $PlanSwiftInfo = @()

    Get-ChildItem $StorageRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object Name -ne "Local" |
ForEach-Object {
    
    $XmlFile = Join-Path `
    -Path $_.FullName `
    -ChildPath "Data.xml"

if (-not (Test-Path -LiteralPath $XmlFile)) {
    continue
}

try {
    [xml]$Xml = Get-Content `
        -LiteralPath $XmlFile `
        -ErrorAction Stop
}
catch {
    Write-Warning (
        "Unable to read PlanSwift storage configuration {0}: {1}" -f
        $XmlFile,
        $_.Exception.Message
    )

    continue
}

$DataPath = (
    $Xml.Item.Properties.Property |
    Where-Object Name -eq "Folder" |
    Select-Object -First 1
).'#text'

$OriginalPath = $DataPath

Write-Verbose (
    "[{0}] Data path found: {1}" -f
    (Get-Date -Format 'HH:mm:ss'),
    $OriginalPath
)

if (
    -not $IsLocal -and
    $DataPath -match '^C:'
) {
    $DataPath = $DataPath -replace `
        '^C:',
        "\\$ComputerName\C$"
}

$Found = $false
$SizeGB = "Not Calculated"

if ($DataPath -and (Test-Path -LiteralPath $DataPath)) {

    $Found = $true

    if ($OriginalPath -match "OneDrive") {
        $SizeGB = "Already in OneDrive"
    }
    elseif ($OriginalPath -like "\\*") {
        $SizeGB = "Network Storage"
    }
    else {
        Write-Verbose (
            "[{0}] Starting size calculation: {1}" -f
            (Get-Date -Format 'HH:mm:ss'),
            $OriginalPath
        )

        $Timer = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            if ($IsLocal) {

    $MeasuredSize = (
        Get-ChildItem `
            -LiteralPath $OriginalPath `
            -Recurse `
            -File `
            -ErrorAction Stop |
        Measure-Object `
            -Property Length `
            -Sum
    ).Sum

    if ($null -eq $MeasuredSize) {
        $SizeBytes = 0
    }
    else {
        $SizeBytes = $MeasuredSize
    }
}
            else {
                $SizeBytes = Invoke-Command `
                    -ComputerName $ComputerName `
                    -ErrorAction Stop `
                    -ScriptBlock {
                        param(
                            [string]$Path
                        )

                        try {
                            if (-not (Test-Path -LiteralPath $Path)) {
                                return $null
                            }

                            $MeasuredSize = (
    Get-ChildItem `
        -LiteralPath $Path `
        -Recurse `
        -File `
        -ErrorAction Stop |
    Measure-Object `
        -Property Length `
        -Sum
).Sum

if ($null -eq $MeasuredSize) {
    return 0
}
else {
    return $MeasuredSize
}
                        }
                        catch {
                           return $null
                        }
                    } `
                    -ArgumentList $OriginalPath
            }

            if ($null -eq $SizeBytes) {
                $SizeGB = "Unavailable"
            }
            else {
                $SizeGB = [math]::Round(
                    ([double]$SizeBytes / 1GB),
                    2
                )
            }
        }
        catch {
            $SizeGB = "Unavailable"

            Write-Warning (
                "Unable to calculate PlanSwift storage size for {0}: {1}" -f
                $OriginalPath,
                $_.Exception.Message
            )
        }
        finally {
            $Timer.Stop()
        }

        Write-Verbose (
            "[{0}] Finished size calculation: {1} ({2:N1} sec)" -f
            (Get-Date -Format 'HH:mm:ss'),
            $SizeGB,
            $Timer.Elapsed.TotalSeconds
        )
    }
}

$PlanSwiftInfo += [PSCustomObject]@{
    ComputerName = $ComputerName
    StorageName  = $_.Name
    DataPath     = $DataPath
    Found        = $Found
    SizeGB       = $SizeGB
}
}


#
# Local Cache
#

$CacheFound = Test-Path `
    -LiteralPath $LocalJobsPath `
    -ErrorAction SilentlyContinue

$CacheSizeGB = 0

if ($CacheFound) {

    Write-Verbose (
        "[{0}] Starting Local Cache size calculation" -f
        (Get-Date -Format 'HH:mm:ss')
    )

    $Timer = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        if ($IsLocal) {

            $MeasuredSize = (
                Get-ChildItem `
                    -LiteralPath $LocalJobsPath `
                    -Recurse `
                    -File `
                    -ErrorAction Stop |
                Measure-Object `
                    -Property Length `
                    -Sum
            ).Sum

            if ($null -eq $MeasuredSize) {
                $SizeBytes = 0
            }
            else {
                $SizeBytes = $MeasuredSize
            }
        }
        else {

            $SizeBytes = Invoke-Command `
                -ComputerName $ComputerName `
                -ErrorAction Stop `
                -ScriptBlock {

                    $Path = (
                        "C:\Program Files (x86)\PlanSwift10\" +
                        "Data\Storages\Local\Jobs"
                    )

                    try {

                        if (-not (Test-Path -LiteralPath $Path)) {
                            return $null
                        }

                        $MeasuredSize = (
                            Get-ChildItem `
                                -LiteralPath $Path `
                                -Recurse `
                                -File `
                                -ErrorAction Stop |
                            Measure-Object `
                                -Property Length `
                                -Sum
                        ).Sum

                        if ($null -eq $MeasuredSize) {
                            return 0
                        }
                        else {
                            return $MeasuredSize
                        }
                    }
                    catch {
                        return $null
                    }
                }
        }

        if ($null -eq $SizeBytes) {
            $CacheSizeGB = "Unavailable"
        }
        else {
            $CacheSizeGB = [math]::Round(
                ([double]$SizeBytes / 1GB),
                2
            )
        }
    }
    catch {

        $CacheSizeGB = "Unavailable"

        Write-Warning (
            "Unable to calculate PlanSwift Local Cache size on {0}: {1}" -f
            $ComputerName,
            $_.Exception.Message
        )
    }
    finally {

        $Timer.Stop()
    }

    Write-Verbose (
        "[{0}] Finished Local Cache size calculation: {1} ({2:N1} sec)" -f
        (Get-Date -Format 'HH:mm:ss'),
        $CacheSizeGB,
        $Timer.Elapsed.TotalSeconds
    )
}

$PlanSwiftInfo += [PSCustomObject]@{
    ComputerName = $ComputerName
    StorageName  = "Local Cache"
    DataPath     = $LocalJobsPath
    Found        = $CacheFound
    SizeGB       = $CacheSizeGB
}

    return $PlanSwiftInfo
}




# ===== Get-PrinterInventory.ps1 =====

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



# ===== Get-PSTInventory.ps1 =====

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



# ===== New-InventorySummary.ps1 =====

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



# ===== Get-PCRefreshInventory.ps1 =====

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

#
# Run the inventory and return a meaningful exit code to Ivanti
#

try {
    Get-PCRefreshInventory -ErrorAction Stop
    exit 0
}
catch {
    exit 1
}

