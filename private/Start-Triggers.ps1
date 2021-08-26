function Start-Triggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Synapse] $synapse
    )
    Write-Debug "BEGIN: Start-Triggers()"

    [SynapseObject[]] $activeTrigger = $synapse.Triggers `
    | Where-Object { $_.Body.properties.runtimeState -eq "Started" } | ToArray
    Write-Host ("The number of triggers to start: " + $activeTrigger.Count)

    #Start active triggers - after cleanup efforts
    $activeTrigger | ForEach-Object { 
        Write-Host "- Enabling trigger: $($_.Name)"
        [SynapseObjectName] $oname = [SynapseObjectName]::new("trigger.$($_.Name)")
        $IsMatchExcluded = $oname.IsNameExcluded($synapse.PublishOptions)
        if ($IsMatchExcluded -and $synapse.PublishOptions.DoNotStopStartExcludedTriggers) {
            Write-host "- Excluded trigger: $($_.Name)" 
        } else {
            try {
                Start-AzSynapseTrigger `
                    -ResourceGroupName $synapse.ResourceGroupName `
                    -WorkspaceName $synapse.Name `
                    -Name $_.Name `
                    -Force | Out-Null
            }
            catch {
                Write-Host "Failed starting trigger."
                Write-Warning -Message $_.Exception.Message
            }
        }
    }

    Write-Debug "END: Start-Triggers()"
}
