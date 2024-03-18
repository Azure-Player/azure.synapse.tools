function Remove-SynapseObjectIfNotInSource {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [synapse] $synapseSource,
        [parameter(Mandatory = $true)] $synapseTargetObj,
        [parameter(Mandatory = $true)] $synapseInstance
    )
    
    Write-Debug "BEGIN: Remove-SynapseObjectIfNotInSource()"
    
    $name = $synapseTargetObj.Name
    $type = $synapseTargetObj.GetType().Name
    $simtype = Get-SimplifiedType -Type "$type"
    $src = Get-SynapseObjectByName -synapse $synapseSource -name $name -type $type
    if (!$src) 
    {
        Write-Verbose "Object [$simtype].[$name] hasn't been found in the source - to be deleted."
        Remove-SynapseObject -synapseSource $synapseSource -obj $synapseTargetObj -synapseInstance $synapseInstance
        $synapseSource.DeletedObjectNames.Add("$simtype.$name")
    }
    else {
        Write-Verbose "Object [$simtype].[$name] is in the source - won't be delete."
    }

    Write-Debug "END: Remove-SynapseObjectIfNotInSource()"
}