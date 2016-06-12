param ([Object]$Webhookdata)

[String]$Reportfolder="C:\Temp"

if ($Webhookdata -ne $null)
{
	$WebhookBody = convertfrom-json $Webhookdata.RequestBody

	foreach ($Result in $WebhookBody.SearchResults.value)
	{
		$FileName = "{0:yyyy-MM-dd_HH-mm-ss}_{1}_SearchResult.txt" -f (get-date), $Result.ID
		$FilePath = join-path $Reportfolder $FileName	
		$Result | out-file $FilePath
		
	}
}
else
{
	write-output "No Webhookdata received"
	
}