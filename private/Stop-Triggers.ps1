function Stop-Triggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Synapse] $synapse
    )
    Write-Debug "BEGIN: Stop-Triggers()"

    Write-Host "Getting triggers..."
    $triggers = Get-AzSynapseTrigger -WorkspaceName $synapse.Name
    if ($null -ne $triggers) 
    {
        # Goal: Stop all active triggers (<>Stopped) present in Synapse service
        $triggersToStop = $triggers | Where-Object { $_.Properties.RuntimeState -ne "Stopped" } | ToArray
        $allTriggersArray = $triggers | ToArray
        Write-Host ("The number of triggers to stop: " + $triggersToStop.Count + " (out of $($allTriggersArray.Count))")

        #Stop all triggers
        if ($null -ne $triggersToStop -and $triggersToStop.Count -gt 0)
        {
            Write-Host "Stopping deployed triggers:"
            $triggersToStop | ForEach-Object { 
                [SynapseObjectName] $oname = [SynapseObjectName]::new("trigger.$($_.Name)")
                $IsMatchExcluded = $oname.IsNameExcluded($synapse.PublishOptions)
                if ($IsMatchExcluded -and $synapse.PublishOptions.DoNotStopStartExcludedTriggers) {
                    Write-host "- Excluded trigger: $($_.Name)" 
                } else {
                    Stop-Trigger `
                    -SynapseWorkspaceName $synapse.Name `
                    -Name $_.Name `
                    | Out-Null
                }
            }
            Write-Host "Complete stopping deployed triggers"
        }

    }

    Write-Debug "END: Stop-Triggers()"
}
