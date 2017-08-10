#This function was used in a network migration in which we had around 900 HP printers we needed to manually RE-IP. There was a similar function for a Ricoh Printer that I wrote (but seem to have lost).
# I would use this function in an interactive session. I would import a csv file of all the printers with their OLD IP, NEW IP, and Printer Name. This function would be called from a foreach loop to each printer on the subnet we were working on That night.
#After all the printers were migrated, I used a similar script I found online and tweaked slightly to create a new IP based port on the server with the NEW ip address desired from the printer, then reassign that socket to the correct printer based on the name in the csv. 
Function Change-HPIP(){
 Param (
        [String]$OldIP,
		[String]$NewIP
		)
Write-Host -Foreground Cyan "Initiating PreTest for $OldIP"
if(Test-Connection -errorAction SilentlyContinue -Count 2 $OldIP){
	Write-Host -Foreground Cyan "PreTest Passed"
}else{
	return
}
$WaitTime = 5000
$Port = "23"
$subnetMask = "255.255.255.0"
$gateway = "192.168.0.1"
$Commands = @("ip $NewIP","subnet-mask $subnetMask","default-gw $gateway","save")
$Socket = New-Object System.Net.Sockets.TcpClient($RemoteHost, $Port)
If ($Socket)
{  $Stream = $Socket.GetStream()
   $Writer = New-Object System.IO.StreamWriter($Stream)
   $Buffer = New-Object System.Byte[] 1024
   $Encoding = New-Object System.Text.AsciiEncoding
   
ForEach ($Command in $Commands)
   {  $Writer.WriteLine($Command)
      $Writer.Flush()
	  Start-Sleep -Millisecond ($WaitTime)
   }
}
$Writer.Close()
$Socket.Close()
}
