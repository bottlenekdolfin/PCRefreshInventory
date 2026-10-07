Get-ChildItem "$PSScriptRoot\Functions\*.ps1" |
ForEach-Object {
. $_.FullName
}