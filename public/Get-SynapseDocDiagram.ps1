<#
.SYNOPSIS
Generates mermaid diagram of dependencies between Synapse Workspace objects.

.DESCRIPTION
Generates mermaid diagram of dependencies between Synapse Workspace objects.

.PARAMETER synapse
Object of Synapse class represents all synapse objects from code.

.PARAMETER direction
Diagram direction: LR - Left to Right (default), TD - Top to Down

.EXAMPLE
$RootFolder = "c:\GitHub\SynapseCode\"
$synapse = Import-SynapseFromFolder -RootFolder $RootFolder -FactoryName 'whatever'
Get-SynapseDocDiagram -synapse $synapse 

.EXAMPLE
Get-SynapseDocDiagram -synapse $synapse -direction 'TD'

.EXAMPLE
Get-SynapseDocDiagram -synapse $synapse | Set-Content -Path 'synapse-diagram.md'

.LINK
Online version: https://github.com/SQLPlayer/azure.synapse.tools/
#>
function Get-SynapseDocDiagram {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)] 
        [Synapse] $synapse,

        [ValidateSet("LR", "TD")]
        [String] $direction = 'LR'
    )
    Write-Debug "BEGIN: Get-SynapseDocDiagram(synapse=$synapse, direction=$direction)"

    $diag = ""
    $line = "::: mermaid`ngraph $direction`n"
    $diag += $line
    
    $synapse.AllObjects() | ForEach-Object {
        $o = $_
        foreach ($d in $o.DependsOn) {
            $n1 = $o.FullName().Replace(' ', '_')
            $n2 = $d.Replace(' ', '_')
            $n2 = $n2.ToLower()[0] + $n2.Substring(1)
            $line = "$n1 --> $n2"
            $diag += $line + "`n"
        }
    }
    $diag += ":::"
    
    Write-Debug "END: Get-SynapseDocDiagram()"
    return $diag
}
