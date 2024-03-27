class SynapseObject {
    [string] $Name
    [string] $Type
    [string] $FileName
    [System.Collections.ArrayList] $DependsOn = @()
    [Boolean] $Deployed = $false
    [Boolean] $ToBeDeployed = $true
    [Synapse] $Synapse
    [PSCustomObject] $Body

    [Boolean] AddDependant ([string]$name, [string]$refType)
    {
        $objType = $refType
        if ($refType.EndsWith('Reference')) {
            $objType = $refType.Substring(0, $refType.Length-9)
        }
        [SynapseObject]::AssertType($objType)
        $fullName = "$objType.$name"
        if (!$this.DependsOn.Contains($fullName)) {
            $this.DependsOn.Add( $fullName ) | Out-Null
        }
        return $true
    }

    [String] FullName ([boolean] $quoted)
    {
        $simtype = Get-SimplifiedType -Type $this.Type
        if ($quoted) {
            return "[$simtype].[$($this.Name)]"
        } else {
            return "$simtype.$($this.Name)"
        }
    }

    [String] AzureResourceName ()
    {
        $resType = Get-AzureResourceType $this.Type
        $SynapseWorkspaceName = $this.Synapse.Name
        if ($resType -like '*managedPrivateEndpoints') {
            return "$SynapseWorkspaceName/default/$($this.Name)"
        } else {
            return "$SynapseWorkspaceName/$($this.Name)"
        }
    }

    [String] FullName ()
    {
        return $this.FullName($false)
    }

    [String] FullNameQuoted ()
    {
        return $this.FullName($true)
    }

    [Boolean] IsNameMatch ([string]$wildcardPattern)
    {
        $folder = $this.GetFolderName()
        $fullname = $this.FullName($false)
        $arr = $wildcardPattern.Split('@')
        $namePattern = $arr[0]
        if ($arr.Count -le 1)
        {
            $r = ($fullname -like $namePattern) 
        } else {
            $folderPattern = $arr[1]
            $r = ($fullname -like $namePattern) -and ( $folder -like $folderPattern )
        }
        return $r
    }

    [String] GetFolderName()
    {
        $ofn = ''
        if ($this.Body.PSObject.Properties.Name -contains "properties")
        {
            $o = $this.Body.Properties
            if ($o.PSobject.Properties -ne $null -and $o.PSobject.Properties.Name -contains "folder")
            {
                $ofn = $this.Body.Properties.folder.name
            }
        }
        return $ofn
    }

    [String] GetHash()
    {
        $hash = Get-FileHash -Path $this.FileName -Algorithm 'MD5'
        return $hash.Hash
    }

    static $AllowedTypes = @('integrationRuntime', 'pipeline', 'dataset', 'dataflow', 'linkedService', 'trigger', 'kqlscript', 'sqlscript', 'notebook', 'managedVirtualNetwork', 'managedPrivateEndpoint', 'sqlpool', 'BigDataPool', 'SparkJobDefinition')

    static AssertType ([string] $Type)
    {
        if ($Type -notin [SynapseObject]::allowedTypes ) { 
            throw "ASWT0029: Unknown object type: $Type."
        }
    }

}

if (!(Get-Variable SYNAPSE_FOLDERS -ErrorAction:SilentlyContinue)) {
    Set-Variable SYNAPSE_FOLDERS -option ReadOnly -value ([SynapseObject]::AllowedTypes)
}    
