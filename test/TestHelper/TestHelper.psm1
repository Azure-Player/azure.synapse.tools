# This module provides helper functions for executing tests


<#
    .SYNOPSIS
        Decrypt a Secure String back to a string.
#>
function Convert-SecureStringToString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Security.SecureString]
        $SecureString
    )

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}


function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = 'ADFTools-' + [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}


function New-SynapseObjectFromFile {
    [OutputType([SynapseObject])]
    param (
        $fileRelativePath,
        $type,
        $name
    )

    $o = [SynapseObject]::new()
    $filename = Join-Path -Path (Get-Location) -ChildPath $fileRelativePath
    $txt = Get-Content $filename -Encoding "UTF8"
    $o.Name = $name
    $o.Type = $type
    $o.FileName = $filename
    $o.Body = $txt | ConvertFrom-Json
    return $o
}

function ConvertTo-RuntimeState {
    param ($state)

    if ($state -eq 'Enabled' ) { return 'Started' }
    if ($state -eq 'Disabled' ) { return 'Stopped' }
    return $state
}

function Get-SynapseObjectFromFile {
    param ($FullPath)

    $txt = Get-Content $FullPath -Encoding "UTF8"
    $o = $o = [SynapseObject]::new()
    $o.Name = (Split-Path -Path $FullPath -Leaf)
    $o.FileName = $FullPath
    $o.Body = $txt | ConvertFrom-Json
    return $o
}


function Remove-ObjectPropertyFromFile {
    param (
        $FileName,
        $Path
    )

    $j = Get-Content -Path $FileName -Raw -Encoding 'utf8' | ConvertFrom-Json
    $j.PSObject.Properties.Remove($Path)
    $output = ($j | ConvertTo-Json -Compress:$true -Depth 100)
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines($FileName, $output, $Utf8NoBomEncoding)
}

function Backup-File {
    param (
        $FileName
    )

    $CopyFileName = "$FileName.backup"
    Copy-Item $FileName $CopyFileName
    return $CopyFileName
}

function Restore-File {
    param (
        [String] $FileName,
        $RemoveBackup = $true
    )

    if ($FileName.EndsWith('.backup')) {
        $OriginalFileName = $FileName.Substring(0, $FileName.Length - 7)
        Copy-Item $FileName $OriginalFileName
        if ($RemoveBackup) {
            Remove-Item -Path $FileName
        }
    }
}




Export-ModuleMember -Function `
    Convert-SecureStringToString, `
    New-TemporaryDirectory, `
    New-SynapseObjectFromFile, `
    Get-SynapseObjectFromFile, `
    Remove-ObjectPropertyFromFile, `
    Backup-File, Restore-File
