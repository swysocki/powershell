<#
Generate my tracks from a master json file
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$InputFile,
    [Parameter(Mandatory=$False)]
    [string]$OutputFile="data.json",
    [Parameter(Mandatory=$False)]
    [string]$Refresh="5"
)

# retrieve master file as one string
$file = Get-Content -Raw $InputFile

# remove possible newlines
$file = $file -replace "`r|`n", ""

# split each json item into a separate element
$option = [System.StringSplitOptions]::RemoveEmptyEntries
$file = $file.split("][", $option)


# iterate through each item
# clobbering the data.json file on purpose
# also return the brackets [] that were removed splitting
$file | % { $_ = $_.Insert(0, "[")
            $_ = $_.Insert($_.Length, "]")
            $_ | Out-File $OutputFile
            Start-Sleep $Refresh }

# Remove when finished
Remove-Item -Force $OutputFile
