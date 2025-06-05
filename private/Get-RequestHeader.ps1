function Get-RequestHeader {
    $Version = (Get-Command -Name Get-AzAccessToken).Version
    $SynapseToken = Get-AzAccessToken -ResourceUrl 'https://dev.azuresynapse.net'
    if ($Version -ge '5.0.0') {
        $token = ConvertFrom-SecureString $SynapseToken.Token -AsPlainText   
    }
    else {
        $token = $SynapseToken.token
    }
    #$token = Get-AzAccessToken -ResourceUrl 'https://management.azure.com'   #audience
    $Header = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token
    }
    return $Header
}
