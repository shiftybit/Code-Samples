#PreReqs
# Grabs computer names from AD. Tries to ping each of them.
# Makes a list of all computers from AD that responded to ping
# Connects to each PC with WMI, grabs the sms client name and the windows version. 

#SCCM CLIENT VERSION WMI QUERY
##$wmi = (Get-WmiObject -NameSpace Root\CCM -Class Sms_Client -ComputerName $_ -ErrorAction SilentlyContinue| Select-Object ClientVersion);
$computers = Get-ADComputer -SearchBase $unit -Filter *
$computers = $computers | Out-GridView -PassThru # Do a gridview so you can deselect stuff if you want

function isUp(){
param([string]$ip)
return Test-Connection -count 1 -quiet $ip
}
function Test-HostList(){
	param($HostList)
	$up = @()
	$down = @()
	foreach($myHost in $HostList){
		if(isup($myHost)){
			Write-Host -Foreground Green "$myhost"
			$up += $myHost
		}else{
			Write-Host -Foreground Red "$myhost"
			$down += $myHost
		}
	}
	$global:up = $up
	$global:down = $down
}
Function Get-OSVersion {
Param($ComputerName)
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $all = @()
        (Get-Childitem c:\windows\system32) | ? Length | Foreach {

            $all += (Get-ItemProperty -Path $_.FullName).VersionInfo.Productversion
        }
        $version = [System.Environment]::OSVersion.Version
        $osversion = "$($version.major).0.$($version.build)"
        $minor = @()
        $all | ? {$_ -like "$osversion*"} | Foreach {
            $minor += [int]($_ -replace".*\.")
        }
        $minor = $minor | sort | Select -Last 1

        return "$osversion.$minor"
    }
}

Test-HostList -HostList $computers.name
	$global:client = @()
	$global:noclient = @()
$up | %{

	Write-Host "$_`t`t`t" -NoNewline;
	$wmi = (Get-WmiObject -NameSpace Root\CCM -Class Sms_Client -ComputerName $_ -ErrorAction SilentlyContinue| Select-Object ClientVersion);
	if($wmi.ClientVersion -eq $null){
		Write-Host "$_" -foreground Red
		$noclient += $_
	}else{
		Write-Host $wmi.ClientVersion $_ -foreground Green
		$client += $_
	}
}

$global:versions = ,@()
$add  | %{
	$version = Get-OSVersion($_)
	$versions += @($_,$version)
	Write-Host "$_ `t$version"
}