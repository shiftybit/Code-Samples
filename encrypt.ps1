#Author - Devon Dieffenbach
#Runs as a Logon script. 
#Iterates over $env:userprofile and runs cipher /e on each directory to ensure it is encrypted.
#Writes events to event logs.
#Make sure you have recovery keys available. 
#Much older version of the encrypt program, but this is the only one available due to sensitive information and time to redact.
Write-EventLog -LogName 'Contoso Data Protection' -Source 'Contoso EFS' -EntryType Information -EventID 1 -Message "Beginning EFS Cipher Update v1.4"
Write-EventLog -Computer "sysctr.contoso.com" -LogName 'Contoso Data Protection' -Source 'Contoso EFS' -EntryType Information -EventID 1 -Message "Beginning EFS Cipher Update v1.4"

mkdir -p C:\Contoso\EFS
$File = "C:\Contoso\EFS\Efs.log"
cipher /u > $File

$stream = [System.IO.StreamWriter] "C:\Contoso\EFS\Version.txt"
$stream.WriteLine("Version 1.4");
$stream.close()
$stream = [System.IO.StreamWriter] "\\contoso\g\EFS\$ENV:COMPUTERNAME"
$stream.WriteLine("Version 1.4");
$stream.close()

$Exclusions = @()
$Exclusions  += "$ENV:USERPROFILE\Windows"
$Exclusions  += "$ENV:USERPROFILE\AppData"
$SanitizedList = @() 

$files = get-childitem -path $ENV:USERPROFILE | ?{$_.PSIsContainer} | Select-Object FullName
foreach ($sanifile in $files) {
   Write-Host $sanifile.Fullname
   if($sanifile.FullName -eq "$ENV:USERPROFILE\Windows"){
		Write-Host "Skipping "  $sanifile.Fullname   "based on Exclusion List"
	}   
	elseif($sanifile.FullName -eq "$ENV:USERPROFILE\AppData"){
		Write-Host "Skipping "  $sanifile.Fullname   "based on Exclusion List"
	}
	Else{
		$SanitizedList += $sanifile.Fullname
		Write-Host $sanifile.Fullname  "set to encrypt"
	}
}
foreach ($directory in $SanitizedList)
{
	$Message = "Encrypting $directory"
	Write-EventLog -LogName 'Contoso Data Protection' -Source 'Contoso EFS' -EntryType Information -EventID 15 -Message $Message
	$command = "cipher /s:`"$directory`" /e >> $File"
	$command
	cipher /s:`"$directory`" /e >> $File
}
