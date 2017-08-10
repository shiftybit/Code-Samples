#Author - Devon Dieffenbach
#Logon Script
#Automatically Assigns outlook signatures based on Active Directory Properties through the use of outlook and microsoft office interop COM objects. 
#Designed so that no popups alert the user

#Other Notes:
#I've written a new version of this program and refactored the code entirely into python to mitigate a lot of the issues I found when writing this.
# For one, if they are client computers, there is no telling what version of Powershell they are running, and often times you won't have control over the Execution Policy.
# I have a python program that compiles into a single executable file to perform these tasks. I'm currently working on finishing it before I upload to github. It works far better than this.
#I shared this script to demonstrate powershell ability, rather than just python. 
#Credits - The launch payload function is composed mostly of something I found online, the rest of the program I wrote from scratch.
#Apply this with group policy

# How it works:
# 1. It looks to see if outlook is running
# 2. If outlook is running, it opens the COM interface to it to check if there is a signature or not.
# 3. It checks active directory and compares that against it's own registry to determine if one of the desired AD properties have changed.
param ([Switch]$force = $false)
$SignatureEnforcing = $true
$AppData=(Get-Item env:appdata).value
$SigPath = '\Microsoft\Signatures'
$SignatureName = 'Siggy Standard' 
$DomainName = 'siggy.com' 
$SigSource = "\\siggy1\Signatures\$SignatureName" 
$LocalLogFile = "C:\Siggy\Siggy\siggy_" + $ENV:Username + ".txt"
$LocalSignaturePath = $AppData+$SigPath
$RemoteSignaturePathFull = $SigSource+'\'+$SignatureName+'.docx'
$CompanyRegPath = "HKCU:\Siggy\"
$SignatureRegPath = $CompanyRegPath+'\'+$SignatureName
$SiggyVersion = "1.80.4"
$SiggySystemLog = [System.Collections.ArrayList]@()
$UserName = $env:username
$Filter = "(&(objectCategory=User)(samAccountName=$UserName))"
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter = $Filter
$ADUserPath = $Searcher.FindOne()
$ADUser = $ADUserPath.GetDirectoryEntry()
$ADDisplayName = $ADUser.DisplayName
$ADEmailAddress = $ADUser.mail
$ADTitle = $ADUser.title
$ADDescription = $ADUser.description
$ADTelePhoneNumber = $ADUser.TelephoneNumber
$ADFax = $ADUser.facsimileTelephoneNumber
$ADMobile = $ADUser.mobile
$ADStreetAddress = $ADUser.streetaddress
$ADCity = $ADUser.l
$ADPOBox = $ADUser.postofficebox
$ADCustomAttribute1 = $ADUser.extensionAttribute1
$ADModify = $ADUser.whenChanged
$ADFirst = $ADUser.givenName
$ADLast = $ADUser.sn
$ADInitials = $ADUser.Initials
$ADPostal = $ADUser.postalcode
$ADDepartment = $ADUser.physicalDeliveryOfficeName
$ADState = $ADUser.st
$ADSignatureQuote = $ADUser.signatureQuote
$ADProfessionalCredentials = $ADUser.professionalCredentials
function Check-LocalLogging{
	if (!(Test-Path -path "C:\Siggy\Siggy")) {
		New-Item "C:\Siggy\Siggy" -Type Directory
	}
}
function Local-Log($message){
	Check-LocalLogging
	$stream = New-Object System.IO.StreamWriter $LocalLogFile, "Append"
	$output = "[" + (Get-Date).toString() + "]: " + $message
	$stream.WriteLine($output)
	$stream.close()
}
function Write-Log($message){
	Local-Log($message)
	if($SiggySystemLog.count -eq 0){
		$LocalScopedUser = $ENV:username
		$SiggySystemLog.Add("---------------------------") | Out-Null
		Local-Log("---------------------------")
		$SiggySystemLog.Add("Starting Siggy $SiggyVersion ") | Out-Null
		Local-Log("Starting Siggy $SiggyVersion ") 
		$SiggySystemLog.Add,("Siggy Evaluating $LocalScopedUser for signature") | Out-Null
		Local-Log("Siggy Evaluating $LocalScopedUser for signature") 
	}
	$output = "[" + (Get-Date).toString() + "]: " + $message
	Write-Host($output)
	$SiggySystemLog.Add($output) | Out-Null
}
function Finalize-Log{
	$LogFile = "\\SC1\Reporting\Siggy\$ENV:COMPUTERNAME.txt" 
	$stream = New-Object System.IO.StreamWriter $LogFile, "Append"
	foreach($message in $SiggySystemLog){
		Write-Output $message
		$stream.WriteLine($message)
	}
	$stream.close()
}
function Check-ValidMAPIAddress{
	$UserName = $env:username
	$Filter = "(&(objectCategory=User)(samAccountName=$UserName))"
	$Searcher = New-Object System.DirectoryServices.DirectorySearcher
	$Searcher.Filter = $Filter
	$ADUserPath = $Searcher.FindOne()
	$ADUser = $ADUserPath.GetDirectoryEntry()
	if(!$ADUser.mail -or $ADuser.mail -notmatch "yourdomain.com"){
		return $false
	}else{
		return $true
	}
}
function Check-ValidCompanyRegistry{
	#Return True if Valid, False if Invalid
	$Validations = $true
	if (Test-Path $SignatureRegPath) {
		Write-Log('Company Registry Valid')
	}else{
		New-Item -path "HKCU:\" -name "Siggy"
		New-Item -path $CompanyRegPath -name $SignatureName
		Write-Log('Company Registry Not Found.')
		$Validations = $false
	}

	if (Test-Path $SignatureRegPath'\Outlook Signature Settings') {
		Write-Log('Outlook Registry Settings Exist')
	}else{
		New-Item -path $SignatureRegPath -name "Outlook Signature Settings"
		Write-Log('Outlook Signature Settings Not Found.')
		$Validations = $false
	}
	return $Validations
}
function Synchronize-AD{
	Write-Log("Synchronizing Active Directory.")
	$ValidateProperties = [System.Collections.ArrayList]@()
	$ValidateProperties.Add("ADDisplayName") | Out-Null
	$ValidateProperties.Add("ADTitle")  | Out-Null
	$ValidateProperties.Add("ADEmailAddress") | Out-Null
	$ValidateProperties.Add("ADFirst") | Out-Null
	$ValidateProperties.Add("ADLast") | Out-Null
	$ValidateProperties.Add("ADInitials") | Out-Null
	$ValidateProperties.Add("ADPostal") | Out-Null
	$ValidateProperties.Add("ADState") | Out-Null
	$ValidateProperties.Add("ADDepartment") | Out-Null
	$ValidateProperties.Add("ADStreetAddress") | Out-Null
	$ValidateProperties.Add("ADCity") | Out-Null
	$ValidateProperties.Add("ADTelephoneNumber") | Out-Null
	$ValidateProperties.Add("ADMobile") | Out-Null
	$ValidateProperties.Add("ADFax") | Out-Null
	$ValidateProperties.Add("SiggyVersion") | Out-Null
	$ValidateProperties.Add("ADSignatureQuote") | Out-Null
	$ValidateProperties.Add("ADProfessionalCredentials") | Out-Null
	$key = Get-Item -Path $SignatureRegPath'\Outlook Signature Settings'
	foreach ($prop in $ValidateProperties){
		$CurrentValue = (Get-Variable $prop).Value
		if($key.GetValue($prop) -ne (Get-Variable $prop).Value){
			Write-Log("Updating Registry Item: $prop to $CurrentValue")
			Set-ItemProperty $SignatureRegPath'\Outlook Signature Settings' -Name $prop -Value $CurrentValue
		}
	}	
}
function Check-ADSync{
	#Returns False if Desynchronized, and True if Synchronized
	Write-Log("Checking AD Properties against Registry")
	$synchronized = $true 
	if((Check-ValidCompanyRegistry) -eq $false){
		$synchronized = $false
	}
	$ValidateProperties = [System.Collections.ArrayList]@()
	$ValidateProperties.Add("ADDisplayName") | Out-Null
	$ValidateProperties.Add("ADTitle")  | Out-Null
	$ValidateProperties.Add("ADEmailAddress") | Out-Null
	$ValidateProperties.Add("ADFirst") | Out-Null
	$ValidateProperties.Add("ADLast") | Out-Null
	$ValidateProperties.Add("ADInitials") | Out-Null
	$ValidateProperties.Add("ADPostal") | Out-Null
	$ValidateProperties.Add("ADState") | Out-Null
	$ValidateProperties.Add("ADDepartment") | Out-Null
	$ValidateProperties.Add("ADStreetAddress") | Out-Null
	$ValidateProperties.Add("ADCity") | Out-Null
	$ValidateProperties.Add("ADTelephoneNumber") | Out-Null
	$ValidateProperties.Add("ADMobile") | Out-Null
	$ValidateProperties.Add("ADFax") | Out-Null
	$ValidateProperties.Add("SiggyVersion") | Out-Null
	$ValidateProperties.Add("ADSignatureQuote") | Out-Null
	$ValidateProperties.Add("ADProfessionalCredentials") | Out-Null
	$key = Get-Item -Path $SignatureRegPath'\Outlook Signature Settings'
	foreach ($prop in $ValidateProperties){
		$CurrentValue = (Get-Variable $prop).Value
		if($key.GetValue($prop) -ne (Get-Variable $prop).Value){
			$synchronized = $false
			Write-Log("$prop is ne to $CurrentValue, setting synchronization status to false")
		}
	}
	if($synchronized){
		Write-Log "Active Directory information is Synchronized to local cache"
	}
	return $synchronized
	
	
}
function Check-SignatureSync{
	
	$LocalSignatureVersion = (Get-ItemProperty $SignatureRegPath'\Outlook Signature Settings').SignatureVersion
	$MasterSignatureVersion = (gci $RemoteSignaturePathFull).LastWriteTime.toString()
	if (!(Test-Path -path $LocalSignaturePath)) {
		New-Item $LocalSignaturePath -Type Directory
	}
	Copy-Item "$SigSource\*" $LocalSignaturePath -Recurse -Force
	if ($MasterSignatureVersion -eq $LocalSignatureVersion){
		Write-Log("Local Signature Version Matches Master Signature")
		return $true
	}else{
		Write-Log("Local Signature Mismatch.")
		Set-ItemProperty $SignatureRegPath'\Outlook Signature Settings' -name SignatureVersion -Value $MasterSignatureVersion
		return $false
	}
}
Function Get-OutlookProcess(){
	$process = Get-Process "Outlook" -ErrorAction SilentlyContinue
	if ($process -ne $null){
		$Application = [Runtime.InteropServices.Marshal]::GetActiveObject('Outlook.Application') 
		return $Application
	}else{
		Return $null
	}
}
Function WaitFor-Outlook(){
	$Application = $null
	while($true){
		if($force){
			Write-Log("Bypassing Outlook-Wait: Force Mode detected.")
			break
		}
		$Application = Get-OutlookProcess
		if($Application -ne $null){
			$profname = $Application.Application.DefaultProfileName
				Write-Log("Outlook Process Detected")
			if($profname -ne $null){
				Write-Log("Default Outlook Profile Detected")
				break
			}
		}
		Write-Log("No Outlook Profile Detected")
		start-sleep -s 120
	}
	Write-Log("Outlook Profile Detected")
}
function EndProgram{
	param([string]$Reason)
	Write-Log("Gracefully Ending Program: $Reason")
	Finalize-Log
}
function Set-OutlookDefaults{
	WaitFor-Outlook
	$MSWord = New-Object -com word.application
	$EmailOptions = $MSWord.EmailOptions
	$EmailSignature = $EmailOptions.EmailSignature
	$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
	if ($SignatureEnforcing -eq $false)
	{
		if ($EmailSignature.NewMessageSignature -eq "(none)")
		{
			Write-Log("New Message Signature Not Detected. Setting $SignatureName as Default.")
			$EmailSignature.NewMessageSignature = $SignatureName
		}
		if ($EmailSignature.ReplyMessageSignature -eq "(none)")
		{
			Write-Log("Reply Signature Not Detected. Setting $SignatureName as Default Reply.")
			$EmailSignature.ReplyMessageSignature = $SignatureName
		}
	}
	else
	{
		Write-Log ("SignatureEnforcing is `$true")
		Write-Log("Forcing $SignatureName as Default.")
		$EmailSignature.NewMessageSignature = $SignatureName
		Write-Log("Forcing $SignatureName as Default Reply.")
		$EmailSignature.ReplyMessageSignature = $SignatureName
	}
	$MSWord.Quit()
}
function Launch-Payload{

    Write-Log('Payload Triggered.')
	$Doctor = $false
	$ReplaceAll = 2
	$FindContinue = 1
	$MatchCase = $False
	$MatchWholeWord = $True
	$MatchWildcards = $False
	$MatchSoundsLike = $False
	$MatchAllWordForms = $False
	$Forward = $True
	$Wrap = $FindContinue
	$Format = $False
	
	#Insert variables from Active Directory to rtf signature-file
	$MSWord = New-Object -com word.application
	$fullPath = $LocalSignaturePath+'\'+$SignatureName+'.docx'
	$MSWord.Documents.Open($fullPath)
	
	#Begin Find and Replace
	#Check if Doctor
	if($ADDisplayName.ToString().substring(0,3) -match "Dr."){
		Write-Log "Display Name contains DR. In the first three characters. Switching to Doctor Mode."
		$Doctor = $true
	}
	
	#User Name 
	$FindText = "DisplayName" 
    $ReplaceText = $ADDisplayName.ToString() 

	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)	

	#Title		
	$FindText = "Title"
	$ReplaceText = $ADTitle.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
	#Email	
	$FindText = "Contosomail"
	$ReplaceText = $ADEmailAddress.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
	#FirstName
	$FindText = "FirstName"
	$ReplaceText = $ADFirst.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
	#LastName
	$FindText = "LastName"
	$Unclean = $ADLast.ToString()
	$ReplaceText = $Unclean -replace "Dr. ", ""
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
	#Middle Initials
    If ($ADInitials -ne '') { 
	   	$FindText = "MiddleInitial"
	   	$ReplaceText = $ADInitials.ToString()
	}
	Else {
		$FindText = "MiddleInitial. "
	   	$ReplaceText = "".ToString()
	}
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
   	
	
	#Postal
	$FindText = "Postal"
	$ReplaceText = $ADPostal.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
	#State
	$FindText = "State"
	$ReplaceText = $ADState.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)

	#Department
	$FindText = "Department"
	$ReplaceText = $ADDepartment.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
	#Description
    If ($ADDescription -ne '') { 
	   	$FindText = "Description"
	   	$ReplaceText = $ADDescription.ToString()
	}
	Else {
		$FindText = " | Description "
	   	$ReplaceText = "".ToString()
	}
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
   	
	#Professional Credentials (Job titles)
    If ($ADProfessionalCredentials -ne '') { 
	   	$FindText = "ProfessionalCredentials"
	   	$ReplaceText = $ADProfessionalCredentials.ToString()
	}
	Else {
		$FindText = ", ProfessionalCredentials"
	   	$ReplaceText = "".ToString()
	}
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	#Street Address
	If ($ADStreetAddress -ne '') { 
        $FindText = "StreetAddress"
	    $ReplaceText = $ADStreetAddress.ToString()
    }
    Else {
	    $FindText = "StreetAddress"
	    $ReplaceText = $DefaultAddress
    }
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
		
	#PostofficeBox
	If ($ADPOBox -ne '') { 
        $FindText = "PostofficeBox"
        $ReplaceText = $ADPOBox.ToString()
    }
    Else {
	    $FindText = "PostofficeBox"
	    $ReplaceText = $DefaultPOBox 
    }
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)

	#City
	If ($ADCity -ne '') { 
	    $FindText = "City"
        $ReplaceText = $ADCity.ToString()
    }
    Else {
	    $FindText = "City"
	    $ReplaceText = $DefaultCity 
    }
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
	#Telephone
	If ($ADTelephoneNumber -ne "") { 
		$FindText = "TelephoneNumber"
		$Number = $ADTelephoneNumber.ToString() -replace "-", "."
		$ReplaceText = $Number
    }
	Else {
		$FindText = "Office TelephoneNumber"
	    $ReplaceText = "".ToString()
 	}
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
	#Mobile
	If ($ADMobile -ne "") { 
		$FindText = "MobileNumber"
		$Number = $ADMobile.ToString() -replace "-", "."
		$ReplaceText = $Number
    }
	Else {
		$FindText = "| Cell MobileNumber"
	    $ReplaceText = "".ToString()
 	}
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)

	#Fax
    If ($ADFax -ne '') { 
    	$FindText = "FaxNumber"
		$Number = $ADFax.ToString() -replace "-", "."
        $ReplaceText = $Number 
    }
    Else {
	    $FindText = "| Fax FaxNumber"
        $ReplaceText = "".ToString() 
    }
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)

	#END: Find And Replace
    #Save new message signature 
    Write-Log('Saving Signatures')
	#Save HTML
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatHTML");
	$path = $LocalSignaturePath+'\'+$SignatureName+".htm"
	$MSWord.ActiveDocument.saveas([ref]$path, [ref]$saveFormat)
    
    #Save RTF 
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatRTF");
	$path = $LocalSignaturePath+'\'+$SignatureName+".rtf"
	$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$saveFormat)
	
	#Save TXT    
    $saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatText");
	$path = $LocalSignaturePath+'\'+$SignatureName+".txt"
	$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$SaveFormat)
	$MSWord.ActiveDocument.Close()
	$MSWord.Quit()
	Write-Log('Signature Saved...')

} #End Payload
function Launch-Missile{
	WaitFor-Outlook
	Launch-Payload
}
Function Main{
	$payload = $false
	if($force){
		Write-Log("Force Mode!")
		$payload = $true
	}else{
		Write-Log("Initiating 3 Minute Sleep before continuing.")
		Start-Sleep -s 180
	}
	if((Check-ValidMapiAddress) -eq $false){
		EndProgram -Reason "Invalid MAPI Address for " + $ENV:Username
	}
	if((Check-ADSync) -eq $false){
		Write-Log("Active Directory is Not Synchronized. Missile Armed.")
		$payload = $true
	}
	if((Check-SignatureSync) -eq $false){
		Write-Log("Local Signature is Not Synchronized. Missile Armed.")
		$payload = $true
	}
	if($payload -eq $true){
		Write-Host "Launching Missile."
		Launch-Missile
		Set-OutlookDefaults
		Synchronize-AD
		EndProgram -Reason "Missile Launched"
	}else{
		EndProgram -Reason "Signature modification not needed. All Settings are Clear"
	}
}
Main