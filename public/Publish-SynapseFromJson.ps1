<#
.SYNOPSIS
Publishes all Synapse Workspace objects from JSON files into target Synapse Workspace service.

.DESCRIPTION
Publishes all Synapse Workspace objects from JSON files into target Synapse Workspace service.
Creates a Synapse Workspace with the specified resource group name and location, if that doesn't exist.
Takes care of creating Synapse Workspace, appropriate order of deployment, deleting objects not in the source anymore, replacing properties environment-related based on CSV config file, and more.

.PARAMETER RootFolder
Source folder where all Synapse Workspace objects are kept. The folder should contain subfolders like pipeline, linkedservice, etc.

.PARAMETER ResourceGroupName
Resource Group Name of target instance of Synapse Workspace

.PARAMETER SynapseWorkspaceName
Name of target Synapse Workspace instance

.PARAMETER Stage
Optional parameter. When defined, process will replace all properties defined in (csv) configuration file.
The parameter can be either full path to csv file (must ends with .csv) or just stage name.
When you provide parameter value 'UAT' the process will try open config file located .\deployment\config-UAT.csv

.PARAMETER Location
Azure Region for target Synapse Workspace. Used only for create new Synapse Workspace instance.

.PARAMETER Option
This objects allows to define certain behaviour of deployment process. Use cmdlet "New-SynapsePublishOption" to create new instance of objects and set required properties.

.PARAMETER Method
Optional parameter. Currently this cmdlet contains two method of publishing: AzSynapse, AzResource (default).
AzResource method has been introduced due to bugs in Az.Synapse PS module.

.EXAMPLE
# Publish entire Synapse Workspace
$ResourceGroupName = 'rg-devops'
$SynapseWorkspaceName = "SQLPlayerSynapseDemo"
$Location = "NorthEurope"
$RootFolder = "c:\GitHub\SynapseName\"
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location"

.EXAMPLE
# Publish entire Synapse Workspace with specified properties (different environment stage name provided)
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Stage "UAT"

.EXAMPLE
# Publish entire Synapse Workspace with specified properties (different environment config full path file provided)
$configCsvFile = 'c:\myCode\mySynapse\deployment\config-UAT.csv'
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Stage "$configCsvFile"

.EXAMPLE
# Including objects by type and name pattern
$opt = New-SynapsePublishOption
$opt.Includes.Add("pipeline.Copy*", "")
$opt.DeleteNotInSource = $false
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Stage "UAT" -Option $opt

.EXAMPLE
# Including only one object to deployment and do not stop/start triggers
$opt = New-SynapsePublishOption
$opt.Includes.Add("pipeline.Wait1", "")
$opt.StopStartTriggers = $false
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Stage "UAT" -Option $opt

.EXAMPLE
# Publish incremental deployment of Synapse Workspace
$opt = New-SynapsePublishOption
$opt.IncrementalDeployment = $true
$opt.StorageAccountName = 'storageaccount1'
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Stage "UAT" -Option $opt

.EXAMPLE
# Publish entire Synapse Workspace via Az.Synapse module instead of Az.Resources
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Method "AzSynapse"

.LINK
Online version: https://github.com/Azure-Player/azure.synapse.tools/
#>
function Publish-SynapseFromJson {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] 
        [String] $RootFolder,
        
        [parameter(Mandatory = $true)] 
        [String] $ResourceGroupName,
        
        [parameter(Mandatory = $true)] 
        [String] $SynapseWorkspaceName,
        
        [parameter(Mandatory = $false)] 
        [String] $Stage = $null,
        
        [parameter(Mandatory = $false)] 
        [String] $Location,
        
        [parameter(Mandatory = $false)] 
        [SynapsePublishOption] $Option,

        [parameter(Mandatory = $false)] 
        [ValidateSet('AzSynapse','AzResource')] 
        [String]$Method = 'AzResource',

        $DefaultDLSAName,
        $DefaultDLSFilesystem,
        [System.Management.Automation.PSCredential] $cred
    )

    $m = Get-Module -Name "azure.synapse.tools"
    $verStr = $m.Version.ToString(2) + "." + $m.Version.Build.ToString("000");
    Write-Host "======================================================================================";
    Write-Host "### azure.synapse.tools                                            Version $verStr ###";
    Write-Host "======================================================================================";
    Write-Host "Invoking Publish-SynapseFromJson (https://github.com/SQLPlayer/azure.synapse.tools)";
    Write-Host "with the following parameters:";
    Write-Host "======================================================================================";
    Write-Host "RootFolder:         $RootFolder";
    Write-Host "ResourceGroupName:  $ResourceGroupName";
    Write-Host "Synapse Workspace:  $SynapseWorkspaceName";
    Write-Host "Location:           $Location";
    Write-Host "Stage:              $Stage";
    Write-Host "Options provided:   $($null -ne $Option)";
    Write-Host "Publishing method:  $Method";
    Write-Host "======================================================================================";

    $script:StartTime = Get-Date
    $script:PublishMethod = $Method
    $script:ds = [SynapseDeploymentState]::new($verStr)

    if ($null -ne $Option) {
        Write-Host "Publish options are provided."
        $opt = $Option
    }
    else {
        Write-Host "Publish options are not provided."
        $opt = New-SynapsePublishOption
    }

    Write-Host "STEP: Verifying whether Synapse workspace exists..."
    $targetSynapse = Get-AzSynapseWorkspace -ResourceGroupName "$ResourceGroupName" -Name "$SynapseWorkspaceName" -ErrorAction:Ignore
     
    if ($targetSynapse) {
        Write-Host "Synapse Workspace exists."
    } else {
        $msg = "Synapse Workspace instance does not exist."
        if ($opt.CreateNewInstance) {
            Write-Host "$msg"
            Write-Host "Creating a new instance of Synapse Workspace..."
            $targetSynapse = New-AzSynapseWorkspace -ResourceGroupName "$ResourceGroupName" -Name "$SynapseWorkspaceName" -Location "$Location" `
            -DefaultDataLakeStorageAccountName $DefaultDLSAName `
            -DefaultDataLakeStorageFilesystem $DefaultDLSFilesystem `
            -SqlAdministratorLoginCredential $cred
            $targetSynapse | Format-List | Out-String
        } else {
            Write-Host "Creation operation skipped as publish option 'CreateNewInstance' = false"
            Write-Error "$msg"
        }
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Reading Synapse Workspace from JSON files..."
    $synapse = Import-SynapseFromFolder -SynapseWorkspaceName $SynapseWorkspaceName -RootFolder "$RootFolder"
    $synapse.ResourceGroupName = "$ResourceGroupName";
    $synapse.Region = "$Location";
    $synapse.PublishOptions = $opt
    Write-Debug ($synapse | Format-List | Out-String)

    Write-Host "===================================================================================";
    Write-Host "STEP: Replacing all properties environment-related..."
    if (![string]::IsNullOrEmpty($Stage)) {
        Update-PropertiesFromFile -synapse $synapse -stage $Stage
    } else {
        Write-Host "Stage parameter was not provided - action skipped."
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Determining the objects to be deployed..."

    # Apply Deployment Options if applicable
    if ($null -ne $Option) {
        ApplyExclusionOptions -synapse $synapse
    }
    Write-Verbose "Incremental Deployment = $($opt.IncrementalDeployment)"
    if ($opt.IncrementalDeployment) {
        if ($opt.StorageAccountName) {
            $ds.StorageAccountName = $opt.StorageAccountName
            Write-Host "Loading Deployment State from Synapse..."
            $ds.Deployed = Get-StateFromService -targetSynapse $targetSynapse -StorageAccountName $opt.StorageAccountName
        }
        else {
            Write-Host "StorageAccountName parameter is required for Incremental Deployment"
            exit 1
        }
        Write-Verbose "The following objects will not be deployed as they have no changes since last deployment:"
        $unchanged_count = 0
        $synapse.AllObjects() | ForEach-Object {
            $fullName = $_.FullName()
            $newHash = $_.GetHash()
            $isUnchanged = $ds.Deployed.ContainsKey($fullName) -and $ds.Deployed[$fullName] -eq $newHash
            Write-Host "- $fullName ( $newHash ) = Unchanged: $isUnchanged"
            if ($isUnchanged) {
                Write-Verbose "- $fullName"
                $_.ToBeDeployed = $false
                $unchanged_count++
            }
        }
        Write-Host "Found $unchanged_count unchanged object(s)."
    }
    ToBeDeployedStat -synapse $synapse

    Write-Host "===================================================================================";
    Write-Host "STEP: Stopping triggers..."
    if ($opt.StopStartTriggers -eq $true) {
        Stop-Triggers -synapse $synapse
    } else {
        Write-Host "Operation skipped as publish option 'StopStartTriggers' = false"
    }

    # Write-Host "===================================================================================";
    # Write-Host "STEP: Deployment of all Synapse objects..."
    # if ($opt.DeployGlobalParams -eq $false) {
    #     Write-Host "Deployment of Global Parameters will be skipped as publish option 'DeployGlobalParams' = false"
    #     if ($synapse.Factories.Count -gt 0) {
    #         $synapse.Factories[0].ToBeDeployed = $false
    #     }
    # }
    # $synapse.AllObjects() | ForEach-Object {
    #     Deploy-SynapseObject -obj $_
    # }

    Write-Host "===================================================================================";
    Write-Host "STEP: Deleting objects not in source ..."
    if ($opt.DeleteNotInSource -eq $true) {
        $synapseIns = Get-SynapseFromService -WorkspaceName "$SynapseWorkspaceName"
        $synapseIns.AllObjects() | ForEach-Object {
            Remove-SynapseObjectIfNotInSource -synapseSource $synapse -synapseTargetObj $_ -synapseInstance $synapseIns
        }
        Write-Host "Deleted $($synapse.DeletedObjectNames.Count) objects from Synapse service."
    } else {
        Write-Host "Operation skipped as publish option 'DeleteNotInSource' = false"
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Updating (incremental) deployment state..."
    if ($opt.IncrementalDeployment) {
        Write-Debug "Deployment State -> SetStateFromSynapse..."
        $ds.SetStateFromSynapse($synapse)
        $dsjson = ConvertTo-Json $ds -Depth 5
        Write-Verbose "--- Deployment State: ---`r`n $dsjson"
    
        Write-Verbose "Redeploying Synapse Deployment State..."
        Set-StateFromService -targetSynapse $targetSynapse -content $dsjson -StorageAccountName $opt.StorageAccountName
        
    }
    else {
        Write-Host "Incremental Deployment State will not be saved as publish option 'IncrementalDeployment' = false"
        Write-Host "Try this new feature to speed up the deployment process. Check out more in documentation."
    }

    Write-Host "===================================================================================";
    Write-Host "STEP: Starting all triggers..."
    if ($opt.StopStartTriggers -eq $true) {
        Start-Triggers -synapse $synapse
    } else {
        Write-Host "Operation skipped as publish option 'StopStartTriggers' = false"
    }
    
    $elapsedTime = new-timespan $script:StartTime $(get-date)
    Write-Host "==============================================================================";
    Write-Host "   *****   Synapse Workspace files have been deployed successfully.   *****`n";
    Write-Host "Synapse Workspace:  $SynapseWorkspaceName";
    Write-Host "Region (Location):  $location";
    Write-Host ([string]::Format("     Elapsed time:  {0:d1}:{1:d2}:{2:d2}.{3:d3}`n", $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds, $elapsedTime.Milliseconds))
    Write-Host "==============================================================================";

    return $synapse
}
