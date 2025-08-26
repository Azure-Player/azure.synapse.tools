function Get-RequestHeader {
    $Version = (Get-Command -Name Get-AzAccessToken).Version
    $SynapseToken = Get-AzAccessToken -ResourceUrl 'https://dev.azuresynapse.net'
    if ($Version -ge '5.0.0') {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SynapseToken.Token)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
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
