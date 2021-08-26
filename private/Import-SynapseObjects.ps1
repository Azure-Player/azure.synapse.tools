function Import-SynapseObjects {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] $synapse,
        [parameter(Mandatory = $true)] $All,
        [parameter(Mandatory = $true)] [String] $RootFolder,
        [parameter(Mandatory = $true)] [String] $SubFolder
    )

    Write-Verbose "Analyzing $SubFolder dependencies..."

    $folder = Join-Path $RootFolder "$SubFolder"
    if (-Not (Test-Path -Path "$folder" -ErrorAction Ignore))
    {
        Write-Verbose "Folder: '$folder' does not exist. No objects to be imported."
        return
    }

    Write-Verbose "Folder: $folder"
    Get-ChildItem "$folder" -Filter "*.json" | Where-Object { !$_.Name.StartsWith('~') } |
    Foreach-Object {
        Write-Verbose "- $($_.Name)"
        $txt = Get-Content $_.FullName -Encoding "UTF8"
        $o = New-Object -TypeName SynapseObject 
        $o.Name = $_.BaseName
        $o.Type = $SubFolder
        $o.FileName = $_.FullName
        $o.Body = $txt | ConvertFrom-Json

        # Discover all referenced objects
        $refs = Get-ReferencedObjects -obj $o
        foreach ($r in $refs) {
            $oname = [SynapseObjectName]::new($r)
            $o.AddDependant( $oname.Name, $oname.Type )
        }

        $o.Synapse = $Synapse
        $All.Add($o)
        Write-Verbose ("- {0} : found {1} dependencies." -f $_.BaseName, $o.DependsOn.Count)
    }

}