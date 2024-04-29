function ApplyExclusionOptions {
    param(
        [Parameter(Mandatory=$True)] [Synapse] $synapse
    )

    Write-Debug "BEGIN: ApplyExclusionOptions()"
    
    $option = $synapse.PublishOptions
    if ($option.Excludes.Keys.Count -gt 0 -and $option.Includes.Keys.Count -eq 0)
    {
        Write-Debug "ENTRY: ApplyExclusionOptions()::Excludes"
        $synapse.AllObjects() | ForEach-Object {
            [SynapseObject] $o = $_
            $o.ToBeDeployed = $true
        }
        $option.Excludes.Keys | ForEach-Object {
            $key = $_
            $synapse.AllObjects() | ForEach-Object {
                [SynapseObject] $o = $_
                $nonDeployable = $o.IsNameMatch($key)
                if ($nonDeployable) { $o.ToBeDeployed = $false }
                #Write-Verbose "- $($o.FullName($true)).ToBeDeployed = $($o.ToBeDeployed)"
            }
        }
    }
    
    if ($option.Includes.Keys.Count -gt 0)
    {
        Write-Debug "ENTRY: ApplyExclusionOptions()::Includes"
        $synapse.AllObjects() | ForEach-Object {
            [SynapseObject] $o = $_
            $o.ToBeDeployed = $false
        }
        $option.Includes.Keys | ForEach-Object {
            $key = $_
            $synapse.AllObjects() | ForEach-Object {
                [SynapseObject] $o = $_
                $deployable = $o.IsNameMatch($key)
                if ($deployable) { $o.ToBeDeployed = $true }
                #Write-Verbose "- $($o.FullName($true)).ToBeDeployed = $($o.ToBeDeployed)"
            }
        }
    }

    Write-Debug "END: ApplyExclusionOptions()"
}

function ToBeDeployedStat {
    param(
        [Parameter(Mandatory=$True)] [Synapse] $synapse
    )

    $ToBeDeployedList = ($synapse.AllObjects() | Where-Object { $_.ToBeDeployed -eq $true } | ToArray)
    $i = $ToBeDeployedList.Count
    Write-Host "# Number of objects marked as to be deployed: $i/$($synapse.AllObjects().Count)"
    $ToBeDeployedList | ForEach-Object {
        Write-Host "- $($_.FullName($true))"
    }

}