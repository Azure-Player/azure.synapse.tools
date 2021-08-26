function Get-SortedTriggers {
    param(
        [string] $SynapseWorkspaceName,
        [string] $ResourceGroupName
    )
    $triggers = Get-AzSynapseTrigger -WorkspaceName $SynapseWorkspaceName
    $triggerDict = @{}
    $visited = @{}
    $stack = new-object System.Collections.Stack
    $triggers | ForEach-Object{ $triggerDict[$_.Name] = $_ }
    $triggers | ForEach-Object{ triggerSortUtil -trigger $_ -triggerNameResourceDict $triggerDict -visited $visited -sortedList $stack }
    $sortedList = new-object Collections.Generic.List[Microsoft.Azure.Commands.Synapse.Models.PSTrigger]
    
    while ($stack.Count -gt 0) {
        $sortedList.Add($stack.Pop()) | Out-Null
    }
    return $sortedList
}

