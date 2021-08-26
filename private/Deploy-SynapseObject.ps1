function Deploy-SynapseObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [SynapseObject] $obj
    )

    if ($obj.ToBeDeployed -eq $false) { 
        Write-Verbose ("Object $($obj.FullName($true)) is not intended to be deployed due to publish options.")
        return; 
    }
    if ($obj.Deployed) { 
        Write-Verbose ("Object $($obj.FullName($true)) is already deployed.")
        return; 
    }
    Write-Host "Start deploying object: $($obj.FullName($true)) ($($obj.DependsOn.Count) dependency/ies)"
    Write-Debug ($obj | Format-List | Out-String)

    $synapse = $obj.Synapse

    if ($obj.DependsOn.Count -gt 0)
    {
        Write-Debug "Checking all dependencies of [$($obj.Name)]..."
        $i = 1
        $obj.DependsOn | ForEach-Object {
            $on = [SynapseObjectName]::new($_)
            $name = $on.Name
            $type = $on.Type
            Write-Verbose ("$i) Depends on: [$type].[$name]")
            $depobj = Get-SynapseObjectByName -synapse $synapse -name "$name" -type "$type"
            if ($null -eq $depobj) {
                if ($synapse.PublishOptions.IgnoreLackOfReferencedObject -eq $true) {
                    Write-Warning "ASWT0006: Referenced object [$type].[$name] was not found. No error raised as user wanted to carry on."
                } else {
                    Write-Error "ASWT0005: Referenced object [$type].[$name] was not found."
                }
            } else {
                Deploy-SynapseObject -obj $depobj
            }
            $i++
        }
    }

    Deploy-SynapseObjectOnly -obj $obj

    Write-Host "Finished deploying object: $($obj.FullName($true))"

}
