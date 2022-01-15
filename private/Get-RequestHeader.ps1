function Get-RequestHeader {
    #$token = Get-AzAccessToken -ResourceUrl 'https://management.azure.com'   #audience
    $token = Get-AzAccessToken -ResourceUrl 'https://dev.azuresynapse.net'   
    $Header = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.Token
    }
    return $Header
}
