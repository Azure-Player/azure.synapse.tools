class SynapseDeploymentState {
    [datetime] $LastUpdate
    [hashtable] $Deployed = @{}
    [string] $synapsetoolsVer = ''
    [string] $Algorithm = 'MD5'
    [string] $StorageAccountName = ''

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
        $this.StorageAccountName
        return $cnt;
    }


    [Boolean] IsTriggerDisabled([string] $ObjectName)
    {
        return $this.DisabledTriggerNames -contains $ObjectName
    }

}

function Get-StateFromService {
    [CmdletBinding()]
    param (
        $targetSynapse,
        [string] $StorageAccountName
    )

        try {
            $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -ErrorAction Stop
            $StorageContainer = Get-AzStorageContainer -Name azure-synapse-tools -Context $StorageContext -ErrorAction Stop
            $DeploymentStateFile = $StorageContainer.CloudBlobContainer.GetBlockBlobReference("$($targetSynapse.name)_deployment_state.json")
            Try {
                $res = $DeploymentStateFile.DownloadText()
                if ($res) {
                    Try {
                        $res = $res |ConvertFrom-Json -ErrorAction Stop
                    }
                    Catch {
                        throw $_.Exception
                    }
                }
            }
            Catch {
                Try {
                    $DeploymentStateFile.UploadText('{"Deployed": {}}')
                    Write-Host "Created placeholder $($targetSynapse.name)_deployment_state.json file"
                }
                Catch {
                    throw $_.Exception
                }
            }
        }
        catch {
            throw $_.Exception
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
    param (
        $targetSynapse,
        $content,
        [string] $StorageAccountName
    )

    try {
        $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -ErrorAction Stop
        $StorageContainer = Get-AzStorageContainer -Name azure-synapse-tools -Context $StorageContext -ErrorAction Stop
        $DeploymentStateFile = $StorageContainer.CloudBlobContainer.GetBlockBlobReference("$($targetSynapse.name)_deployment_state.json")
        $DeploymentStateFile.UploadText($content)
        Write-Output "Successfully updated $($targetSynapse.name)_deployment_state.json"
    }
    catch {
        throw $_.Exception
    }
}