function Remove-SynapseObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [synapse] $synapseSource,
        [parameter(Mandatory = $true)] $obj,
        [parameter(Mandatory = $true)] $synapseInstance
    )

    Write-Debug "BEGIN: Remove-SynapseObject()"

    $name = $obj.Name
    $err = $null
    $ErrorMessage = $null
    $simtype = Get-SimplifiedType -Type $obj.GetType().Name

    [SynapseObjectName] $oname = [SynapseObjectName]::new("$simType.$name")
    $IsExcluded = $oname.IsNameExcluded($SynapseSource.PublishOptions)
    if (-not $IsExcluded) {
        Write-Host "Removing object: [$simtype].[$name]"
        $action = $simtype
    } else {
        if ($synapseSource.PublishOptions.DoNotDeleteExcludedObjects) {
            Write-Verbose "Object [$simtype].[$name] won't be deleted as publish option 'DoNotDeleteExcludedObjects' = true."
            $action = "DoNothing"
        } else {
            Write-Host "Removing excluded object: [$simtype].[$name] as publish option 'DoNotDeleteExcludedObjects' = false."
            $action = $simtype
        }
    }

    Try 
    {
        switch -Exact ($action)
        {
            "Dataset" {
                Remove-AzSynapseDataset `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "DataFlow" {
                Remove-AzSynapseDataFlow `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "Pipeline" {
                Remove-AzSynapsePipeline `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "LinkedService" {
                Remove-AzSynapseLinkedService `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "IntegrationRuntime" {
                Remove-AzSynapseIntegrationRuntime `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "Trigger" {
                # Stop trigger if enabled before delete it
                if ($obj.RuntimeState -eq 'Started') {
                    Write-Verbose "Disabling trigger: $name..." 
                    Stop-AzSynapseTrigger `
                        -WorkspaceName $SynapseWorkspaceName `
                        -Name $name `
                        -Force -ErrorVariable err -ErrorAction Stop | Out-Null
                }
                Remove-AzSynapseTrigger `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "Credential" {
                Remove-SynapseObjectRestAPI `
                    -type_plural 'credentials' `
                    -name $name `
                    -synapseInstance $synapseInstance `
                    -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "Notebook" {
                Remove-AzSynapseNotebook `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $name `
                    -Force -ErrorVariable err -ErrorAction Stop | Out-Null
            }
            "DoNothing" {

            }
            default
            {
                Write-Error "SYNT0018: Type $($obj.GetType().Name) is not supported."
            }
        }
    }
    Catch {
        Write-Debug "Error caught when deleting:`n$err"
        $ErrorMessage = $_.Exception.Message
    }

    if ($ErrorMessage -match 'deleted since it is referenced by (?<RefName>.+)\.')
    {
        Write-Verbose "The document cannot be deleted since it is referenced by $($Matches.RefName)."
        #$Matches.RefName
        $refobj = $synapseInstance.AllObjects() | Where-Object { $_.Name -eq $Matches.RefName }
        $refobj | ForEach-Object {
            Remove-SynapseObject -synapseSource $synapseSource -obj $_ -synapseInstance $synapseInstance
        }
        Remove-SynapseObject -synapseSource $synapseSource -obj $obj -synapseInstance $synapseInstance
    } elseif ($null -ne $ErrorMessage) {
        #Rethrow exception
        throw $ErrorMessage
    }

    Write-Debug "END: Remove-SynapseObject()"

}