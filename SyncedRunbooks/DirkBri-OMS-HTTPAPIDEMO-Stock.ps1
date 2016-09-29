#requires -version 3.0


#region variables
# Replace with your Workspace ID
$CustomerID = Get-AutomationVariable -Name "DirkBri-OMS-WorkspaceID"
# Replace with your Primary Key
$SharedKey = Get-AutomationVariable -Name "DirkBri-OMS-WorkspaceKey"
#Specify the name of the record type that we'll be creating.
$LogType = Get-AutomationVariable -Name "DirkBri-OMS-StockDemo-LogName"
#Specify a time in the format YYYY-MM-DDThh:mm:ssZ to specify a created time for the records.
$TimeStampField = Get-AutomationVariable -Name "DirkBri-OMS-StockDemo-TimeStampField"
#Specify the name of the Stock we want to retrieve.
$StockName = Get-AutomationVariable -Name "DirkBri-OMS-StockDemo-StockName"
#Create Array
$StockName = $StockName.Split(",")
#endregion

#region functions
# Function to retrieve Stock value information
function Get-StockPrice
{
  [CmdletBinding()]
  Param
  (
    # Stockname(s)
    [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
    Position = 0)]
    $StockName
  )

  Process
  {
    $HttpRequestUrl = 'http://finance.google.com/finance/info?client=ig&q={0}'-f $StockName

    $stockvalue = Invoke-WebRequest -Uri $HttpRequestUrl -UseBasicParsing

    #Fixing output. ONLY works with one STOCK PRICE!
    $stockprice = ((($stockvalue.content).Replace('//','')).Replace('[','')).Replace(']','') | ConvertFrom-Json

    #Convert to correct types

    $stockprice.id = [int]$stockprice.id
    $stockprice.l = [double]$stockprice.l
    $stockprice.l_fix = [double]$stockprice.l_fix
    $stockprice.l_cur = [double]$stockprice.l_cur
    $stockprice.c = [double]$stockprice.c
    $stockprice.c_fix = [double]$stockprice.c_fix
    $stockprice.cp = [double]$stockprice.cp
    $stockprice.cp_fix = [double]$stockprice.cp_fix
    $stockprice.pcls_fix = [double]$stockprice.pclx_fix

    ConvertTo-Json -InputObject @($stockprice)

  }
}

# Function to create the authorization signature.
Function New-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
  $xHeaders = 'x-ms-date:' + $date
  $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

  $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
  $keyBytes = [Convert]::FromBase64String($sharedKey)

  $sha256 = New-Object -TypeName System.Security.Cryptography.HMACSHA256
  $sha256.Key = $keyBytes
  $calculatedHash = $sha256.ComputeHash($bytesToHash)
  $encodedHash = [Convert]::ToBase64String($calculatedHash)
  $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
  return $authorization
}

# Function to create and post the request
Function Send-OMSData($customerId, $sharedKey, $body, $logType) 
{
  $method = 'POST'
  $contentType = 'application/json'
  $resource = '/api/logs'
  $rfc1123date = [DateTime]::UtcNow.ToString('r')
  $contentLength = $body.Length
  $signature = New-Signature `
  -customerId $customerId `
  -sharedKey $sharedKey `
  -date $rfc1123date `
  -contentLength $contentLength `
  -fileName $fileName `
  -method $method `
  -contentType $contentType `
  -resource $resource
  $uri = 'https://' + $customerId + '.ods.opinsights.azure.com' + $resource + '?api-version=2016-04-01'

  $headers = @{
    'Authorization'      = $signature
    'Log-Type'           = $logType
    'x-ms-date'          = $rfc1123date
    'time-generated-field' = $TimeStampField
  }

  $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
  return $response.StatusCode
} 
#endregion

# Main
# Submit the data to the API endpoint
# Iterate through the configured StockNames.
Foreach($Stock in $StockName) {
    $json = Get-StockPrice -StockName $Stock
    Write-Output $json
    Send-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType 
}
