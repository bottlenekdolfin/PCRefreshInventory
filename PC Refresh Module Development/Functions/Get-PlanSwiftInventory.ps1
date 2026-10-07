
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

