#Gets the API token and creates the headers for subsiquent calls
$ClientID = ""
$ClientSecret = ""

#Gets Monitoring token to get info
$bodyMo = @{
    grant_type = "client_credentials"
    client_id = "$ClientID"
    client_secret = "$ClientSecret"
    redirect_uri = "https://localhost"
    scope = "monitoring"
}

$API_AuthHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$API_AuthHeaders.Add("accept", 'application/json')
$API_AuthHeaders.Add("Content-Type", 'application/x-www-form-urlencoded')

$auth_tokenMo = Invoke-RestMethod -Uri https://eu.ninjarmm.com/oauth/token -Method POST -Headers $API_AuthHeaders -Body $bodyMo
$access_tokenMo = $auth_tokenMo | Select-Object -ExpandProperty 'access_token' -EA 0

$headersMo = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headersMo.Add("Accept", "application/json")
$headersMo.Add("Authorization", "Bearer $access_tokenMo")

#Gets Management token to change info
$bodyMa = @{
    grant_type = "client_credentials"
    client_id = "$ClientID"
    client_secret = "$ClientSecret"
    redirect_uri = "https://localhost"
    scope = "management"
}

$auth_tokenMa = Invoke-RestMethod -Uri https://eu.ninjarmm.com/oauth/token -Method POST -Headers $API_AuthHeaders -Body $bodyMa
$access_tokenMa = $auth_tokenMa | Select-Object -ExpandProperty 'access_token' -EA 0

$headersMa = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headersMa.Add("Accept", "application/json")
$headersMa.Add("Authorization", "Bearer $access_tokenMa")

#Gets Control token to change info
$bodyC = @{
    grant_type = "client_credentials"
    client_id = "$ClientID"
    client_secret = "$ClientSecret"
    redirect_uri = "https://localhost"
    scope = "control"
}

$auth_tokenC = Invoke-RestMethod -Uri https://eu.ninjarmm.com/oauth/token -Method POST -Headers $API_AuthHeaders -Body $bodyC
$access_tokenC = $auth_tokenC | Select-Object -ExpandProperty 'access_token' -EA 0

$headersC = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headersC.Add("Accept", "application/json")
$headersC.Add("Authorization", "Bearer $access_tokenC")

## Main

#Gets the detailed info of all organizations
$organizations = Invoke-RestMethod 'https://eu.ninjarmm.com/api/v2/organizations-detailed' -Method 'GET' -Headers $headersMo

# Difine the policy changes
#nodeRoleId is the ID of the role you are wanting to change, this can be found by running the /api/v2/roles api call
#policyId is the ID of the Policy you want to make default, this can be found by going to the portal and editing the policy and looking at the last number in the URL or by running the /api/v2/policies api call
$newPolicy = '[
    {
        "nodeRoleId": 1008,
        "policyId": 64
    }
]'

ForEach ($org in $organizations){
    $id = $org.id
    Invoke-RestMethod -Uri "https://eu.ninjarmm.com/api/v2/organization/$id/policies" -Method PUT -Headers $headersMa -ContentType 'application/json' -Body $newPolicy
}
