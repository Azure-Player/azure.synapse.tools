function Deploy-SynapseObjectOnly {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [SynapseObject] $obj
    )
    Write-Debug "BEGIN: Deploy-SynapseObjectOnly(obj=$obj)"

    if ($obj.Deployed) { 
        Write-Verbose ("The object is already deployed.")
        return; 
    }
    #Write-Host "Deploying object: $($obj.Name) ($($obj.DependsOn.Count) dependency/ies)"
    #Write-Verbose "  Type: $($obj.Type)"
    $synapse = $obj.Synapse
    $ResourceGroupName = $synapse.ResourceGroupName
    $SynapseWorkspaceName = $synapse.Name

    $type = $obj.Type
    if ($type -eq 'SqlPool') {
        Write-Warning -Message 'Deployment of (dedicated) SqlPool is not supported, object must exist prior.'
        $obj.Deployed = $true;
        Write-Debug "END: Deploy-SynapseObjectOnly"
        return;
    }

    Write-Verbose ("Ready to deploy from file: {0}" -f $obj.FileName)
    $body = (Get-Content -Path $obj.FileName | Out-String)
    Write-Debug -Message $body
    $json = $body | ConvertFrom-Json

    if ($script:PublishMethod -eq "AzResource") { $type = "AzResource" }

    
    
    switch -Exact ($type)
    {
        'integrationRuntime'
        {
            Set-StrictMode -Version 1.0
            $desc = if ($null -eq $json.properties.description) { " " } else { $json.properties.description }
            if ($json.properties.type -eq "SelfHosted") {
                $linkedIR = $json.properties.typeProperties.linkedInfo

                if ($null -eq $linkedIR) {
                    Write-Verbose -Message "Integration Runtime type detected: Self-Hosted"
                    
                    Set-AzSynapseIntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    | Out-Null
                } 
                else 
                {
                    Write-Verbose -Message "Integration Runtime type detected: Linked Self-Hosted"
                    Set-AzSynapseIntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    -SharedIntegrationRuntimeResourceId $linkedIR.resourceId `
                    | Out-Null
                }
            }
            elseif ($json.properties.type -eq "Managed") {
                Write-Verbose -Message "Integration Runtime type detected: Azure Managed"
                $computeIR = $json.properties.typeProperties.computeProperties
                $dfp = $computeIR.dataFlowProperties
                Set-AzSynapseIntegrationRuntime `
                -ResourceGroupName $ResourceGroupName `
                -WorkspaceName $SynapseWorkspaceName `
                -Name $json.name `
                -Type $json.properties.type `
                -Description $desc `
                -DataFlowComputeType $dfp.computeType `
                -DataFlowTimeToLive $dfp.timeToLive `
                -DataFlowCoreCount $dfp.coreCount `
                -Location $computeIR.location `
                | Out-Null
            }
            else {
                Write-Error "Deployment for this kind of Integration Runtime is not supported yet."
            }
        }
        'linkedService'
        {
            Set-AzSynapseLinkedService `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'pipeline'
        {
            Set-AzSynapsePipeline `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'dataset'
        {
            Set-AzSynapseDataset `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'dataflow'
        {
            Set-AzSynapseDataFlow `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'trigger'
        {
            Set-AzSynapseTrigger `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'sqlscript'
        {
            # Must write *.sql file as the method accepts the SQL script only 
            $fileSQL = $obj.FileName.Substring(0, $obj.FileName.Length-'json'.Length) + 'sql'
            Set-Content -Path $fileSQL -Value $json.properties.content.query -Encoding 'utf8'
            Set-AzSynapseSqlScript `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $fileSQL `
            | Out-Null
        }
        'AzResource'
        {
            $resType = Get-AzureResourceType $obj.Type

            Write-Verbose $resType
            Write-Verbose "$SynapseWorkspaceName/$($obj.Name)"

            New-AzResource `
            -ResourceType $resType `
            -ResourceGroupName $resourceGroupName `
            -Name "$SynapseWorkspaceName/$($obj.Name)" `
            -ApiVersion "2019-06-01-preview" `
            -Properties $json `
            -IsFullObject -Force | Out-Null
        }






        default
        {
            Write-Error "Type $($obj.Type) is not supported."
        }
    }

    $obj.Deployed = $true;

    Write-Debug "END: Deploy-SynapseObjectOnly"

}
