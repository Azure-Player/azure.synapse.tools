class SynapseDeploymentState {
    [datetime] $LastUpdate 
    [hashtable] $Deployed = @{}
    [string] $synapsetoolsVer = ''
    [string] $Algorithm = 'MD5'

    SynapseDeploymentState ([string] $ver)
    {
        $this.synapsetoolsVer = $ver
    }

    [int] SetStateFromSynapse ([Synapse] $synapse)
    {
        $cnt = 0
        $synapse.AllObjects() | ForEach-Object {
            $hash = $_.GetHash()
            $name = $_.FullName()
            if ($_.Deployed) {
                if ($this.Deployed.ContainsKey($name))
                {
                    $this.Deployed[$name] = $hash
                    Write-Verbose "[UPDATED] hash for $name = $hash"
                    $cnt++
                } else {
                    $this.Deployed.Add($name, $hash)
                    Write-Verbose "  [ADDED] hash for $name = $hash"
                    $cnt++
                }
            }
        }
        # Remove deleted objects from Deployment State
        $synapse.DeletedObjectNames | ForEach-Object {
            $this.Deployed = Remove-ItemFromCollection -col $this.Deployed -item $_
            Write-Verbose "[DELETED] hash for $_"
        }
        $this.LastUpdate = [System.DateTime]::UtcNow
        return $cnt;
    }


    [Boolean] IsTriggerDisabled([string] $ObjectName)
    {
        return $this.DisabledTriggerNames -contains $ObjectName
    }

}

function Get-StateFromService {
    [CmdletBinding()]
    param ($targetSynapse)

        try {
            $StorageContext = New-AzStorageContext -StorageAccountName $targetSynapse.StorageAccountName -ErrorAction Stop
            $StorageContainer = Get-AzStorageContainer -Name azure-synapse-tools -Context $StorageContext -ErrorAction Stop
            $DeploymentStateFile = $StorageContainer.CloudBlobContainer.GetBlockBlobReference("$($targetSynapse.name)_deployment_state.json")
            $res = $DeploymentStateFile.DownloadText()
            if ($res) {
                $res = $res |ConvertFrom-Json
            }
        }
        catch {
            
        }

        $d = @{}

        try {
            $InputObject = $res.Deployed
            $d = Convert-PSObjectToHashtable $InputObject
        }
        catch {
            Write-Verbose $_.Exception
        }

        return $d
}

function Set-StateFromService {
    [CmdletBinding()]
    param ($targetSynapse, $content)

    try {
        $StorageContext = New-AzStorageContext -StorageAccountName $targetSynapse.StorageAccountName -ErrorAction Stop
        $StorageContainer = Get-AzStorageContainer -Name azure-synapse-tools -Context $StorageContext -ErrorAction Stop
        $DeploymentStateFile = $StorageContainer.CloudBlobContainer.GetBlockBlobReference("$($targetSynapse.name)_deployment_state.json")
        $res = $DeploymentStateFile.UploadText($content)
    }
    catch {
        throw $_.Exception
    }
}



class SynapseGlobalParam {
    $type = "Object"
    $value = $null

    SynapseGlobalParam ($value) 
    {
        $this.value = $value
    }

}