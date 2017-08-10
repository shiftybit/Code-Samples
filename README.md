Selection of Code Samples as well as my daily notebook.
Code samples are incomplete as core libraries or other portions were too lengthy to review to quickly redact any sensitive information from them. 

# Index
* siggy.ps1
  * Powershell Program / Logon Script. 
  * Sets Email Signatures based on Active Directory Properties
  * AD Schema was extended by me for some properties that weren't default. 
  * ran on over 2000 machines.
  * Quietly Updates signature to match a docx template stored somewhere on the network. 
  * Can be used to quickly adopt an email signature / standard format across the enterprise. 
  * Some functionality was not written by me, but over 80% of the code is written by me. 
 
* loaner.py
  * Though I didn't write the code, I taught the person who wrote it using this project as a way to demonstrate the concepts. Went from never having written python, to being able to write small projects like this in a matter of a few hours.
  * Helps keep track of loaner laptops for the department.
  * User interface written in tkinter.
  * Uses a barcode scanner and a wyse thin client. Application is presented as a xenapp.
  * It has security flaws (SQL Injection) but this is currently mitigated with appropriate SQL permissions and limited access to the program. 

* Telnet-HP.ps1
  * Socket based powershell script i wrote to telnet into an HP printer, and modify the IPConfig.
  * This function was used in a network migration in which we had around 900 HP printers we needed to manually RE-IP. There was a similar function for a Ricoh Printer that I wrote (but seem to have lost).
  *I would use this function in an interactive session. I would import a csv file of all the printers with their OLD IP, NEW IP, and Printer Name. This function would be called from a foreach loop to each printer on the subnet we were working on That night.
  *After all the printers were migrated, I used a similar script I found online and tweaked slightly to create a new IP based port on the server with the NEW ip address desired from the printer, then reassign that socket to the correct printer based on the name in the csv. 
  
* encrypt.ps1
  * Runs as a Logon script. 
  * Iterates over $env:userprofile and runs cipher /e on each directory to ensure it is encrypted.
  * Writes events to event logs.
  * Make sure you have recovery keys available. 
  * Much older version of the encrypt program, but this is the only one available due to sensitive information and time to redact.
 
* ScanSCCMClientVersion.ps1
  * Grabs computer names from AD. Tries to ping each of them.
  * Makes a list of all computers from AD that responded to ping
  * Connects to each PC with WMI, grabs the sms client name and the windows version. 
  * SCCM CLIENT VERSION WMI QUERY
  * $wmi = (Get-WmiObject -NameSpace Root\CCM -Class Sms_Client -ComputerName $_ -ErrorAction SilentlyContinue| Select-Object ClientVersion);
  
* SampleOneNoteSnippets.pdf
  * I take daily notes. these are mostly to myself.
  * I created a wiki for anything that I could train to others.
  * These items were somewhat randomly selected from my notebook based on finding things I could easily redact, as well as things I thought were interesting enough to want to share. 