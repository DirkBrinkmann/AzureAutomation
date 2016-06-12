workflow DirkBri-OMSAlertDemo-01
{
		param([object]$WebhookData)
		
		if ($WebhookData -ne $null)
		{
			$WebHookBody = convertfrom-json $WebhookData.Requestbody
			
			foreach ($SearchResult in $WebHookBody.Searchresults.value)
			{
				write-output $SearchResult
			}
		}
		else
		{
			write-error "Webhookdata object is empty"
			
		}
}