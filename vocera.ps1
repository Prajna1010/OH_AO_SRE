
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$smtpServer = "smtp.ohiohealth.com"
	$smtpPort = 25 
	$smtpUsername = "OH.AO.SRE.Automation@ohiohealth.com"    
	$from = "OH.AO.SRE.Automation@ohiohealth.com"
	$to = "OH-ACN-VoiceBoutique@ohiohealth.com"
	$subject = "Vocera Speech Port Alert - Threshold Breached"
	
	$EncryptionKeyData = Get-Content "D:\Vocera_log_monitoring\enc.key"
	$PasswordSecureString = Get-Content "D:\Vocera_log_monitoring\secret.encrypted" | ConvertTo-SecureString -Key $EncryptionKeyData
	$PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordSecureString))

	$credential = New-Object System.Management.Automation.PSCredential($smtpUsername, (ConvertTo-SecureString $PlainTextPassword -AsPlainText -Force))
	$a= @()
	$resultsArray= @()
	$s=0
	$c=0
	$directoryPath = "D:\vocera\logs"
	$pattern = "log*.txt"
	$lastRunFilePath = "D:\Vocera_log_monitoring\Timestamp.txt"
	$lastRunTimestamp = Get-Content -Path $lastRunFilePath
	$dateTime = ([DateTime]::Parse($lastRunTimestamp))
	$logFiles = Get-ChildItem -Path $directoryPath -Filter $pattern | Where-Object { $_.LastWriteTime -gt $dateTime }
if ($logFiles.Count -gt 0){	
	foreach ($logFile in $logFiles){
	$m="D:\vocera\logs\$logFile"
		
	$logContent = Get-Content -Path $m
	foreach ($line in $logContent) {
		if ($line -like "*SpeechPorts=*") {
			$match1 = [regex]::Match($line, "SpeechPorts=(\d+)")
    			if ($match1.Success) {
        			$speechPorts = $match1.Groups[1].Value
				break
    			}
   		}
	}
	for ($i = $logContent.Length - 1; $i -ge 0; $i--) {
		$line = $logContent[$i]
		if ($line -like "*Free speech ports count:*") {
			$match = [regex]::Match($line, "Free speech ports count: '(\d+)'")
    			if ($match.Success) {
        			$freePorts = $match.Groups[1].Value
				break
    			}
   		}
	}
	if($freePorts -ne $null){
		$comment = "Count found"
		$s=11
		$p=0.10*$speechPorts
		if($s -gt $freePorts -or $p -gt $freePorts){
			$status="Below threshold"
			$c++
			$a+=@"
Log file name: $logFile
Free speech port count: $freePorts
 
"@			
		}
		else{
			$status="Above threshold"
		}
	}
	else{
		$comment="Free speech ports count - not found"
	}
	
	$log_extract =  [PSCustomObject]@{
		date_time=Get-date	
		log_name=$logFile
		total_speech_port=$speechPorts
		free_ports_count=$freePorts
		status=$status
		comment=$comment
	}
		
	$resultsArray += $log_extract
	}
	$body = "$a"
	if($c -gt 0){
		Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer $smtpServer -Port $smtpPort -Credential $credential
	}

$resultsArray | Export-Csv -Path "D:\Vocera_log_monitoring\Vocera_log\log_$timestamp.csv" -NoTypeInformation
}
#Get-Date | Out-File -FilePath $lastRunFilePath -Force

-ExecutionPolicy Bypass -File D:\Vocera_log_monitoring\vocera.ps1


