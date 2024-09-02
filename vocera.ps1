	$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$a= @()
	$m=0
	$c=0
	$EncryptionKeyData = Get-Content "D:\Vocera_log_monitoring\s.key"
	$PasswordSecureString = Get-Content "D:\Vocera_log_monitoring\voc.encrypted" | ConvertTo-SecureString -Key $EncryptionKeyData
	$pass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordSecureString))

	$directoryPath = "D:\vocera\logs"
	$pattern = "vtg*.txt"
	$lastRunFilePath = "D:\Vocera_log_monitoring\Timestamp.txt"
	$lastRunTimestamp = Get-Content -Path $lastRunFilePath
	$dateTime = ([DateTime]::Parse($lastRunTimestamp))
	$logFiles = Get-ChildItem -Path $directoryPath -Filter $pattern | Where-Object { $_.LastWriteTime -gt $dateTime }
if($logFiles.Count -gt 0){
	foreach ($logFile in $logFiles) {
	$s="D:\vocera\logs\$logFile"
	$logContent = Get-Content -Path $s
	foreach ($line in $logContent) {
		if ($line -like "*Is NOT alive*") {
			$comment="Phrase *Is NOT alive* found"
			$c++
			$a+=@"
Log file name: $logFile
"@		
			break
   		}
				
	}
}
	if($c -gt 0){
		$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
		$headers.Add("Content-Type", "application/json")
		$user = 'sn.sre'
		$pair = "$($user):$($pass)"
		$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
		$basicAuthValue = "Basic $encodedCreds"
		$headers.Add("Authorization", $basicAuthValue )
$body = @"
{
`"u_caller`": `"`",
`"u_callback_number`": `"5672417400`",
`"u_impact`": `"1`",
`"u_urgency`": `"1`",
`"u_best_time_to_call`":`"54`",
`"u_channel`": `"Email`",
`"u_assignment_group`": `"ACN-Voice App`",
`"u_short_description`": `Vocera-TG -"Is Not alive"`",
`"u_category`": `"Applications`",
`"u_sub_category`": `"Other`",
`"u_description`": `"The phrase "Is NOT alive" found in the logs - $a`"
}
"@
	$response = Invoke-RestMethod 'https://ohiohealth.service-now.com/api/now/import/u_sre_automation' -Method 'POST' -Headers $headers -Body $body
	$m = $response.result.display_value 
	Write-Host "Incident# : $m"
		
	}
}
}
$result = "Script run successful - $m" 
Add-Content -Path "D:\Vocera_log_monitoring\Vocera_log\log_$timestamp.csv" -Value $result
Get-Date | Out-File -FilePath $lastRunFilePath -Force
