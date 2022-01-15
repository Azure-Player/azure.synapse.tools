function Stop-Trigger {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [parameter(Mandatory = $true)] [string] $SynapseWorkspaceName,
        [parameter(Mandatory = $true)] [string] $Name
    )

    Write-host "- Disabling trigger: $Name" 
    
    Stop-AzSynapseTrigger `
    -WorkspaceName $SynapseWorkspaceName `
    -Name $Name `
    -Force | Out-Null

}
