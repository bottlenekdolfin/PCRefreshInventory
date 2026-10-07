@{

    # Script module associated with this manifest
    RootModule = 'PCRefreshInventory.psm1'

    # Version of this module
    ModuleVersion = '1.0.0'

    # Unique identifier for this module
    # Replace this value with a GUID generated for your module
    GUID = 'b3c55e49-27af-420e-96fc-fc535dc79260'

    # Author of this module
    Author = 'Corbin Forrester'

    # Description of the functionality provided by this module
    Description = 'PowerShell tools for collecting Windows PC refresh inventory, including applications, disk usage, mapped drives, printers, PST files, and PlanSwift data.'

    # Minimum version of Windows PowerShell required
    PowerShellVersion = '5.1'

    # Functions exported by this module
    FunctionsToExport = @(
        'Get-ApplicationInventory'
        'Get-CDriveInfo'
        'Get-MappedDriveInventory'
        'Get-PlanSwiftInventory'
        'Get-PrinterInventory'
        'Get-PSTInventory'
        'Get-PCRefreshInventory'
    )

    # Cmdlets exported by this module
    CmdletsToExport = @()

    # Variables exported by this module
    VariablesToExport = @()

    # Aliases exported by this module
    AliasesToExport = @()

    # Additional module metadata
    PrivateData = @{

        PSData = @{

            # Add tags that help describe the module
            Tags = @(
                'PowerShell'
                'Inventory'
                'Windows'
                'PCRefresh'
                'PlanSwift'
            )

            # Add these later if the GitHub repository has them
            # ProjectUri = 'https://github.com/USERNAME/PCRefreshInventory'
            # LicenseUri = 'https://github.com/USERNAME/PCRefreshInventory/blob/main/LICENSE'

        }
    }
}
