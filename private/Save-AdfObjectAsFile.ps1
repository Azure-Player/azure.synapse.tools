function Save-SynapseObjectAsFile {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [SynapseObject] $obj
    )
    
    $newFileName = Join-Path $obj.Synapse.Location "$($obj.Type)\~$($obj.Name).json"
    Write-Debug "Writing file: $newFileName"

    $output = ($obj.Body | ConvertTo-Json -Compress:$true -Depth 100)
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines($newFileName, $output, $Utf8NoBomEncoding)

    return $newFileName
}
