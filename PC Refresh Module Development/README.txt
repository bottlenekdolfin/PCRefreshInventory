# PC Refresh Inventory

A modular PowerShell tool that collects Windows computer information needed before a PC refresh or replacement.

The inventory includes applications, printers, mapped drives, Outlook PST files, PlanSwift storage, disk usage, the currently logged-on user, and the BIOS serial number. It produces a plain-text report designed for use in ServiceNow or another service-management system.

---

# TL;DR: How to Run It

## Import the module

Open PowerShell in the project folder and run:

```powershell
Import-Module .\PCRefresh.psm1 -Force
```

## Inventory the local computer

```powershell
Get-PCRefreshInventory
```

## Inventory a different computer

```powershell
Get-PCRefreshInventory -ComputerName COMPUTERNAME
```

Replace `COMPUTERNAME` with the target computer name.

Example:

```powershell
Get-PCRefreshInventory -ComputerName PC12345
```

## Show verbose progress

For the local computer:

```powershell
Get-PCRefreshInventory -Verbose
```

For a different computer:

```powershell
Get-PCRefreshInventory `
    -ComputerName PC12345 `
    -Verbose
```

The module writes the completed inventory report to the output location configured in `Get-PCRefreshInventory.ps1`.

> The PowerShell module is the normal way to run the inventory manually. The generated standalone script is intended for automated deployment through an endpoint-management platform such as Ivanti.

---

# Overview

PC Refresh Inventory gathers information that may need to be documented, migrated, or recreated when replacing a Windows computer.

The tool collects:

- Computer name
- Currently logged-on user
- BIOS serial number
- Installed applications
- C: drive usage
- Persistent mapped drives
- Installed printers
- Printer ports and available IP addresses
- Outlook PST files
- PlanSwift storage locations
- PlanSwift storage sizes
- PlanSwift Local Cache information

Each inventory function returns structured PowerShell objects. `New-InventorySummary` converts those objects into a readable text report.

---

# Project Structure

The exact repository structure may vary, but the project is organized around individual source functions, a PowerShell module, a build script, and a generated standalone deployment script.

```text
PCRefreshInventory/
|
+-- Functions/
|   +-- Get-ApplicationInventory.ps1
|   +-- Get-CDriveInfo.ps1
|   +-- Get-MappedDriveInventory.ps1
|   +-- Get-PlanSwiftInventory.ps1
|   +-- Get-PrinterInventory.ps1
|   +-- Get-PSTInventory.ps1
|   +-- New-InventorySummary.ps1
|   +-- Get-PCRefreshInventory.ps1
|
+-- PCRefreshInventory.psm1
+-- PCRefreshInventory.psd1
+-- Build-PCRefreshInventory.ps1
|
+-- Output/
    +-- PCRefreshInventory-Standalone.ps1
```

The project has three layers.

## 1. Individual source functions

The files in the `Functions` folder are the source of truth.

Changes should normally be made to these files rather than directly to the generated standalone script.

## 2. PowerShell module

`PCRefreshInventory.psm1` loads and exports the inventory commands for normal interactive use.

The primary command is:

```powershell
Get-PCRefreshInventory
```

## 3. Standalone deployment script

`PCRefreshInventory-Standalone.ps1` contains all required functions and an automatic execution block.

It is intended for deployment through Ivanti or another endpoint-management platform.

The standalone script should be treated as a generated deployment artifact.

---

# Importing the Module

## Import from the current folder

```powershell
Import-Module .\PCRefreshInventory.psm1 -Force
```

The `-Force` parameter reloads the module if a previous version is already loaded in the current PowerShell session.

## Import by full path

```powershell
Import-Module `
    "C:\Path\To\PCRefreshInventory\PCRefreshInventory.psm1" `
    -Force
```

## Import by module name

If the module has been installed in a folder included in `$env:PSModulePath`, import it by name:

```powershell
Import-Module PCRefreshInventory -Force
```

## Verify the module loaded

```powershell
Get-Module PCRefreshInventory
```

List the commands exported by the module:

```powershell
Get-Command -Module PCRefreshInventory
```

---

# Running the Inventory

## Local computer

```powershell
Get-PCRefreshInventory
```

When `-ComputerName` is omitted, the function defaults to:

```powershell
$env:COMPUTERNAME
```

## Remote computer

```powershell
Get-PCRefreshInventory -ComputerName PC12345
```

Remote execution may require:

- Administrative permissions
- PowerShell remoting
- WinRM connectivity
- Firewall access
- Access to administrative shares
- Access to the remote user profile
- Access to the remote user's loaded registry hive

## Verbose output

```powershell
Get-PCRefreshInventory -Verbose
```

Verbose output is particularly useful for PlanSwift storage scans because it displays:

- Storage locations being processed
- Size calculation start times
- Size calculation completion times
- Scan duration
- Calculated size or status

Remote example:

```powershell
Get-PCRefreshInventory `
    -ComputerName PC12345 `
    -Verbose
```

---

# Inventory Functions

## `Get-ApplicationInventory`

Collects installed applications registered in the standard 64-bit and 32-bit Windows uninstall registry locations.

Registry paths:

```text
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
```

Returned properties include:

- `ComputerName`
- `DisplayName`
- `DisplayVersion`

Registry entries with a blank `DisplayName` are excluded.

### Limitations

This function does not necessarily include:

- Microsoft Store applications
- AppX packages
- Portable software
- Applications installed only for an individual user
- Software that does not register with Windows uninstall information

---

## `Get-CDriveInfo`

Collects C: drive capacity information.

Returned properties include:

- `ComputerName`
- `TotalGB`
- `UsedGB`
- `FreeGB`
- `FreePercent`

Example output:

```text
========== C DRIVE ==========
Total Size: 476.31 GB
Used Space: 301.25 GB
Free Space: 175.06 GB
Free Percent: 36.8%
```

If the C: drive query fails, the rest of the inventory can continue. The report displays:

```text
C: drive information unavailable.
```

---

## `Get-MappedDriveInventory`

Collects persistent mapped drives for the currently logged-on user.

The function:

1. Retrieves the currently logged-on interactive user.
2. Converts the username to a security identifier, or SID.
3. Reads the user's persistent network mappings from:

```text
HKEY_USERS\<UserSID>\Network
```

Returned properties include:

- `ComputerName`
- `DriveLetter`
- `Path`

Example output:

```text
H -> \\FileServer\Home
S -> \\FileServer\Shared
```

### Why the registry is used

A script running through endpoint management may execute as LocalSystem or another service account.

Commands such as `Get-PSDrive` would normally display drives visible to the account running PowerShell, not necessarily drives mapped for the interactive user.

Reading the interactive user's registry hive provides a more appropriate inventory of persistent mappings.

### Limitations

The function may not detect:

- Temporary drive mappings
- Nonpersistent `New-PSDrive` mappings
- Drive mappings belonging to another user's session
- Mappings created by software that does not use the standard registry location

---

## `Get-PrinterInventory`

Collects installed printer information.

Returned properties include:

- `ComputerName`
- `PrinterName`
- `DriverName`
- `Location`
- `PortName`
- `PortType`
- `IPAddress`

Example standard TCP/IP printer:

```text
Office Printer - Main Office - IP_10.10.20.15 - 10.10.20.15 - HP Universal Printing
```

Example IPP printer:

```text
IPP Printer - Not Set - https://printer.example.com/ipp/print - No IP - Microsoft IPP Class Driver
```

### Printer IP address behavior

Not every printer exposes a traditional IP address through:

```powershell
PrinterHostAddress
```

A missing IP address is common with:

- IPP printers
- WSD printers
- Shared print-server queues
- URL-based printer ports

The function preserves `PortName` even when `IPAddress` is unavailable.

This allows an IPP URL, WSD identifier, or shared printer queue to remain visible in the report.

A blank `PrinterHostAddress` does not necessarily mean printer inventory failed.

---

## `Get-PSTInventory`

Searches common Outlook PST locations for the currently logged-on user.

Locations searched:

```text
C:\Users\<User>\Documents\Outlook Files
C:\Users\<User>\AppData\Local\Microsoft\Outlook
```

Subfolders are searched recursively.

Returned properties include:

- `ComputerName`
- `Name`
- `SizeBytes`
- `SizeGB`
- `FullName`

Example output:

```text
========== PST FILES ==========
PST Files Found: YES
PST File Count: 1

Name: Archive.pst
Size: 3.72 GB
Location: C:\Users\User\Documents\Outlook Files\Archive.pst

Total PST Size: 3.72 GB
```

### Limitations

This function does not search the entire computer.

PST files stored in custom locations may not be detected, such as:

```text
C:\PST
C:\Email Archives
D:\Outlook Data
```

Searching the entire drive would improve coverage but could significantly increase inventory time and disk activity.

---

# PlanSwift Inventory

`Get-PlanSwiftInventory` inventories PlanSwift 10 storage configurations and the PlanSwift Local Cache.

Standard storage root:

```text
C:\Program Files (x86)\PlanSwift10\Data\Storages
```

Local Cache location:

```text
C:\Program Files (x86)\PlanSwift10\Data\Storages\Local\Jobs
```

## Configured storage discovery

Each PlanSwift storage folder may contain a `Data.xml` configuration file.

The function:

1. Enumerates the configured storage folders.
2. Excludes the special `Local` storage folder from the normal storage loop.
3. Reads each `Data.xml` file.
4. Locates the configured `Folder` property.
5. Determines whether the configured path is reachable.
6. Classifies the storage location.
7. Calculates storage size when appropriate.
8. Returns an object for each configured storage.

## PlanSwift storage conditions

### Local storage with data

```text
Main Storage: 42.37 GB - C:\PlanSwiftData
```

### Empty local storage

```text
Empty Storage: 0 GB - C:\EmptyPlanSwiftData
```

A numeric zero means the scan completed successfully and found no file data.

### Failed size calculation

```text
Main Storage: Unavailable - C:\PlanSwiftData
```

`Unavailable` means the path was found, but the size calculation did not complete successfully.

This prevents inaccessible data from being incorrectly reported as `0 GB`.

### OneDrive storage

```text
Cloud Storage: Already in OneDrive - C:\Users\User\OneDrive\PlanSwift
```

The function avoids an unnecessary size calculation when the original configured path indicates that the data is already in OneDrive.

### Network storage

```text
Shared Storage: Network Storage - \\FileServer\PlanSwift
```

The function recognizes UNC paths and avoids recursively calculating their size.

### Missing or unreachable storage

```text
Old Storage: Not Found or Unreachable - D:\OldPlanSwiftData
```

The configuration remains visible in the report even when its path cannot be reached.

## Local Cache

The Local Cache is inspected separately.

Possible states include:

```text
Local Cache: 4.28 GB - C:\Program Files (x86)\PlanSwift10\Data\Storages\Local\Jobs
```

```text
Local Cache: 0 GB - C:\Program Files (x86)\PlanSwift10\Data\Storages\Local\Jobs
```

```text
Local Cache: Unavailable - C:\Program Files (x86)\PlanSwift10\Data\Storages\Local\Jobs
```

```text
Local Cache: Not Found or Unreachable - C:\Program Files (x86)\PlanSwift10\Data\Storages\Local\Jobs
```

## Remote size calculations

For remote inventory, eligible PlanSwift size calculations are performed on the target computer through PowerShell remoting.

This prevents the complete file tree from being enumerated across an administrative share.

The remote computer returns only the final byte count.

---

# `New-InventorySummary`

`New-InventorySummary` converts the collected PowerShell objects into a plain-text report.

The formatting is intentionally suitable for copying into ServiceNow or another service-management ticket.

The summary contains sections for:

- Printers
- Mapped drives
- PlanSwift
- PST files
- C: drive
- Applications

The printer section uses one line per printer to keep the report condensed.

Example:

```text
Office Printer - Main Office - IP_10.10.20.15 - 10.10.20.15 - HP Universal Printing
```

Missing values use readable descriptions such as:

```text
Not Set
No IP
Unavailable
Not Found or Unreachable
```

---

# `Get-PCRefreshInventory`

`Get-PCRefreshInventory` coordinates the complete inventory process.

The function:

1. Runs each inventory collector.
2. Retrieves the currently logged-on user.
3. Retrieves and trims the BIOS serial number.
4. Passes all collected objects to `New-InventorySummary`.
5. Creates a timestamped filename.
6. Verifies that the output directory is available.
7. Writes the summary to the configured output location.
8. Returns the summary to the PowerShell console.

The multi-object inventory categories are captured as arrays so that zero, one, or multiple results are handled consistently.

---

# Example Report

```text
Run Date: 20261007-153541
Computer: PC12345
User: DOMAIN\User
Serial: ABC12345

========== PRINTERS ==========
Office Printer - Main Office - IP_10.10.20.15 - 10.10.20.15 - HP Universal Printing
IPP Printer - Not Set - https://printer.example.com/ipp/print - No IP - Microsoft IPP Class Driver

========== DRIVES ==========
H -> \\FileServer\Home
S -> \\FileServer\Shared

========== PLANSWIFT ==========
Main Storage: 42.37 GB - C:\PlanSwiftData
Local Cache: 4.28 GB - C:\Program Files (x86)\PlanSwift10\Data\Storages\Local\Jobs
Shared Storage: Network Storage - \\FileServer\PlanSwift
Cloud Storage: Already in OneDrive - C:\Users\User\OneDrive\PlanSwift
Old Storage: Not Found or Unreachable - D:\OldPlanSwiftData

========== PST FILES ==========
PST Files Found: YES
PST File Count: 1

Name: Archive.pst
Size: 3.72 GB
Location: C:\Users\User\Documents\Outlook Files\Archive.pst

Total PST Size: 3.72 GB

========== C DRIVE ==========
Total Size: 476.31 GB
Used Space: 301.25 GB
Free Space: 175.06 GB
Free Percent: 36.8%

========== APPLICATIONS ==========
Application One
Application Two
Application Three
```

---

# Output Configuration

The report destination is configured in `Get-PCRefreshInventory.ps1`.

Example:

```powershell
$OutputDirectory = "\\FileServer\Share\RefreshInventory"
```

The generated filename includes the computer name and run timestamp:

```text
PC12345-20261007-153541.txt
```

Timestamped filenames prevent a later run from overwriting an earlier inventory report.

## Public repository warning

Before publishing the repository, replace any internal output path with a generic example.

Do not commit:

- Internal IP addresses
- Internal server names
- Credentials
- Usernames used for authentication
- Passwords
- API keys
- Access tokens
- Private organizational information

---

# Running Functions During Development

The module is the preferred way to load the project, but individual source functions can also be dot-sourced during development.

## Dot-source one function

```powershell
. .\Functions\Get-PrinterInventory.ps1
```

Then run:

```powershell
Get-PrinterInventory
```

## Dot-source all function files

From the project root:

```powershell
Get-ChildItem .\Functions -Filter "*.ps1" |
ForEach-Object {
    . $_.FullName
}
```

If PowerShell is already in the `Functions` directory:

```powershell
Get-ChildItem -Filter "*.ps1" |
ForEach-Object {
    . $_.FullName
}
```

## Reload the module after editing

```powershell
Import-Module .\PCRefreshInventory.psm1 -Force
```

If a clean module reload is needed:

```powershell
Remove-Module PCRefreshInventory `
    -ErrorAction SilentlyContinue

Import-Module .\PCRefreshInventory.psm1 -Force
```

---

# Standalone Deployment

The PowerShell module is the normal interactive interface:

```powershell
Import-Module .\PCRefreshInventory.psm1 -Force
Get-PCRefreshInventory
```

The standalone script is intended for automated endpoint deployment.

The generated standalone script contains:

1. All required function definitions
2. The `Get-PCRefreshInventory` function
3. An automatic execution block
4. Process exit-code handling

## Standalone execution footer

The generated script ends with:

```powershell
try {
    Get-PCRefreshInventory -ErrorAction Stop
    exit 0
}
catch {
    exit 1
}
```

The automatic execution block belongs only in the generated standalone deployment script.

Do not place this block in the source version of:

```text
Functions\Get-PCRefreshInventory.ps1
```

If the execution block were inside the source function file, importing or dot-sourcing the file would immediately run the complete inventory. The `exit` command could also close the development PowerShell session.

## Run the standalone script manually

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File ".\Output\PCRefreshInventory-Standalone.ps1"
```

The standalone script runs the inventory automatically. It is not necessary to call `Get-PCRefreshInventory` separately.

---

# Exit Codes

The standalone deployment script returns:

```text
0 = Inventory completed and the report was written successfully
1 = A fatal inventory or output failure occurred
```

`Get-PCRefreshInventory` rethrows fatal errors so the standalone wrapper can return exit code `1`.

Recommended function-level error handling:

```powershell
catch {
    Write-Error (
        "PC refresh inventory failed for {0}: {1}" -f
        $ComputerName,
        $_.Exception.Message
    )

    throw
}
```

The standalone wrapper then converts the thrown error into the appropriate process exit code.

---

# Execution Context

The account running the inventory must have permission to:

- Query CIM information
- Read installed application registry paths
- Read the active user's registry hive
- Read the active user's Outlook directories
- Query installed printers
- Read PlanSwift storage folders
- Write to the configured output directory

## Endpoint-management execution

An endpoint-management system may run the script as:

- The currently logged-on user
- A configured deployment account
- LocalSystem
- A service account

A script that works in an administrator PowerShell console may behave differently when deployed through endpoint management.

Testing should be performed under the same security context used in production.

## LocalSystem and UNC access

When LocalSystem accesses a remote UNC path, Windows may authenticate using the computer's domain account:

```text
DOMAIN\COMPUTERNAME$
```

The output share and NTFS permissions must allow the intended deployment identity to create report files.

If the script must run when nobody is logged on, LocalSystem can be more reliable than an execution mode that requires an interactive user token. However, the output share permissions must support that choice.

---

# Local and Remote Inventory

Most inventory functions accept:

```powershell
-ComputerName
```

The default value is:

```powershell
$env:COMPUTERNAME
```

## Local inventory

```powershell
Get-PCRefreshInventory
```

## Remote inventory

```powershell
Get-PCRefreshInventory -ComputerName PC12345
```

Remote inventory may depend on:

- DNS resolution
- Network connectivity
- PowerShell remoting
- WinRM configuration
- Administrative permissions
- Firewall configuration
- Administrative share access
- Remote registry and profile availability

The primary deployment scenario can still be local execution through an endpoint-management agent.

---

# Error Handling

Individual inventory functions attempt to preserve as much useful data as possible.

Examples:

- A C: drive failure does not necessarily stop printer or application inventory.
- A printer is retained when no traditional IP address is available.
- A malformed PlanSwift `Data.xml` file does not stop every storage from being processed.
- A successful empty PlanSwift scan returns `0 GB`.
- A failed PlanSwift scan returns `Unavailable`.
- An unreachable PlanSwift configuration remains visible.
- A missing logged-on user does not automatically make machine inventory fail.
- A failed final report write is treated as a fatal error.

Some category-level failures may result in an empty category. Consult PowerShell warnings or endpoint-management logs when the report does not match the expected state of a computer.

---

# Syntax Validation

Each source function should be parsed after editing.

Example:

```powershell
$SourcePath = ".\Functions\Get-PrinterInventory.ps1"

$Tokens = $null
$ParseErrors = $null

[System.Management.Automation.Language.Parser]::ParseFile(
    $SourcePath,
    [ref]$Tokens,
    [ref]$ParseErrors
) | Out-Null

$ParseErrors
```

No output from `$ParseErrors` means no parser errors were detected.

## Validate the generated standalone script

```powershell
$StandalonePath = ".\Output\PCRefreshInventory-Standalone.ps1"

$Tokens = $null
$ParseErrors = $null

[System.Management.Automation.Language.Parser]::ParseFile(
    $StandalonePath,
    [ref]$Tokens,
    [ref]$ParseErrors
) | Out-Null

if ($ParseErrors.Count -gt 0) {
    $ParseErrors |
        Format-List Message, Extent

    throw "Standalone script failed syntax validation."
}

Write-Host "Standalone script passed syntax validation."
```

Do not deploy a generated script when parser errors are present.

---

# Testing the Module

Import the module:

```powershell
Import-Module .\PCRefreshInventory.psm1 -Force
```

Verify the main command:

```powershell
Get-Command Get-PCRefreshInventory
```

Run a local test:

```powershell
Get-PCRefreshInventory -Verbose
```

Run a remote test:

```powershell
Get-PCRefreshInventory `
    -ComputerName PC12345 `
    -Verbose
```

Verify that the expected report was written to the configured output directory.

---

# Testing the Standalone Script

Run the generated artifact from a fresh PowerShell process:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File ".\Output\PCRefreshInventory-Standalone.ps1"
```

Check the exit code after the process finishes:

```powershell
$LASTEXITCODE
```

Expected success value:

```text
0
```

Expected fatal failure value:

```text
1
```

Testing from a fresh process confirms that:

- All required functions were included
- The script does not depend on functions already loaded in the development console
- The execution footer is in the correct location
- The report can be written using the current security context

---

# Recommended Deployment Tests

Before broad deployment, test the following scenarios:

1. A user is logged on and the module is run interactively.
2. A user is logged on and the standalone script is run under the deployment account.
3. No user is logged on.
4. PlanSwift is not installed.
5. PlanSwift has local storage.
6. PlanSwift has an empty storage folder.
7. PlanSwift uses OneDrive storage.
8. PlanSwift uses network storage.
9. A configured PlanSwift path is unreachable.
10. The computer has a standard TCP/IP printer.
11. The computer has an IPP printer.
12. The computer has no PST files.
13. The computer has PST files in subfolders.
14. The report output share is unavailable.
15. The report output share denies write access.
16. The standalone script is launched from a clean PowerShell process.
17. The deployment is tested against a small pilot group.

---

# Recommended Development Workflow

```text
Edit an individual source function
        |
        v
Parse the source file
        |
        v
Test the function
        |
        v
Import the module with -Force
        |
        v
Test the complete module
        |
        v
Build the standalone script
        |
        v
Parse the generated standalone
        |
        v
Run the standalone in a fresh process
        |
        v
Test under the deployment identity
        |
        v
Pilot deployment
        |
        v
Production deployment
```

Avoid maintaining changes only in the generated standalone script.

If a correction is made directly to the standalone file during troubleshooting, apply the equivalent correction to the appropriate individual source file or build script before generating the next release.

---

# Requirements

- Windows PowerShell 5.1 or a compatible Windows PowerShell environment
- Windows CIM/WMI providers
- PrintManagement PowerShell cmdlets
- Access to the interactive user's registry hive
- Access to the interactive user's profile
- Permission to write to the configured output location
- PowerShell remoting for remote inventory
- Administrative-share access for applicable remote operations
- PlanSwift 10 for PlanSwift-specific inventory

---

# Security Considerations

Before publishing or deploying the project:

- Remove internal IP addresses.
- Remove internal server names where appropriate.
- Do not commit passwords.
- Do not embed service-account credentials.
- Do not commit API keys or access tokens.
- Restrict write access to the report share.
- Review whether reports contain sensitive usernames or paths.
- Review the repository before making it public.
- Keep environment-specific configuration separate when practical.
- Confirm organizational requirements before publishing internal tools.

Example `.gitignore` entries:

```gitignore
Output/
*.log
*.tmp
Config-Local.ps1
PCRefreshInventory-Standalone.ps1
```

Whether the generated standalone script should be ignored depends on whether generated releases will be committed to the repository.

---

# Known Limitations

- PST searches are limited to common Outlook locations.
- Application inventory does not include every installation technology.
- Printer IP addresses are not available for every printer type.
- Mapped-drive inventory focuses on persistent registry mappings.
- Remote inventory depends on remoting, permissions, and network availability.
- Some user-specific information is unavailable when no user is logged on.
- PlanSwift size calculations may take time when folders contain many files.
- PST enumeration may continue past inaccessible subfolders without reporting every skipped item.
- An empty inventory category may represent either no data or a category-level collection failure.

---

# Future Improvements

Potential improvements include:

- Save a local report before attempting the network upload
- Retry failed uploads
- Add structured JSON output
- Add CSV output
- Add category-level success and failure status
- Add Pester tests
- Automate parser validation during the build
- Add automatic version numbers
- Generate a deployment-file hash
- Move output settings into a configuration file
- Add an optional full-drive PST search
- Build a simplified local-only deployment version
- Detect Microsoft Store and AppX applications
- Add more explicit IPP and WSD printer classification
- Add upload status to the report
- Add execution-duration measurements for each category

---

# Contributing

When contributing to the project:

1. Modify the relevant individual source function.
2. Parse the function for syntax errors.
3. Test the function independently.
4. Import the module with `-Force`.
5. Test the complete inventory.
6. Rebuild the standalone script.
7. Parse the generated standalone script.
8. Run the standalone script from a fresh PowerShell process.
9. Document behavior changes.
10. Avoid committing organization-specific configuration.

---

# License

Add the license selected for the repository.

Common options include:

- MIT License
- Apache License 2.0
- Internal use only

If the project is intended only for internal organizational use, confirm the appropriate repository visibility and licensing requirements before publishing.
