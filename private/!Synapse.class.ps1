class SynapsePublishOption {
    [hashtable] $Includes = @{}
    [hashtable] $Excludes = @{}
    [Boolean] $DeleteNotInSource = $false
    [Boolean] $StopStartTriggers = $true
    [Boolean] $CreateNewInstance = $true
    [Boolean] $DeployGlobalParams = $true
    [Boolean] $FailsWhenConfigItemNotFound = $true
    [Boolean] $FailsWhenPathNotFound = $true
    [Boolean] $IgnoreLackOfReferencedObject = $false
    [Boolean] $DoNotStopStartExcludedTriggers = $false
    [Boolean] $DoNotDeleteExcludedObjects = $true
    [Boolean] $IncrementalDeployment = $false
    [string] $StorageAccountName = ''
}

class Synapse {
    [string] $Id = ""
    [string] $Name = ""
    [string] $ResourceGroupName = ""
    [string] $Region = ""
    [System.Collections.ArrayList] $Pipelines = @{}
    [System.Collections.ArrayList] $LinkedServices = @{}
    [System.Collections.ArrayList] $DataSets = @{}
    [System.Collections.ArrayList] $DataFlows = @{}
    [System.Collections.ArrayList] $Triggers = @{}
    [System.Collections.ArrayList] $IntegrationRuntimes = @{}
    [System.Collections.ArrayList] $ManagedVirtualNetwork = @{}
    [System.Collections.ArrayList] $ManagedPrivateEndpoints = @{}
    [System.Collections.ArrayList] $KQLScripts = @{}
    [System.Collections.ArrayList] $SQLScripts = @{}
    [System.Collections.ArrayList] $Notebooks = @{}
    [System.Collections.ArrayList] $SparkJobDefinitions = @{}
    [System.Collections.ArrayList] $SqlPool = @{}
    [System.Collections.ArrayList] $DeletedObjectNames = @{}
    [string] $Location = ""
    [SynapsePublishOption] $PublishOptions

    [System.Collections.ArrayList] AllObjects()
    {
        return $this.LinkedServices + $this.Notebooks + $this.Pipelines + $this.DataSets + $this.DataFlows + $this.Triggers + $this.SQLScripts + $this.KQLScripts + $this.SparkJobDefinitions + $this.IntegrationRuntimes + $this.ManagedVirtualNetwork + $this.ManagedPrivateEndpoints
    }

    [hashtable] GetObjectsByFullName([string]$pattern)
    {
        [hashtable] $r = @{}
        $this.AllObjects() | ForEach-Object {
            $oname = $_.FullName($false);
            if ($oname -like $pattern) { 
                $null = $r.Add($oname, $_)
            }
        }
        return $r
    }

    [hashtable] GetObjectsByFolderName([string]$folder)
    {
        [hashtable] $r = @{}
        $this.AllObjects() | ForEach-Object {
            $ofn = $_.GetFolderName()
            if ($ofn -like $folder) 
            { 
                $oname = $_.FullName($false);
                $null = $r.Add($oname, $_)
            }
        }
        return $r
    }

}

