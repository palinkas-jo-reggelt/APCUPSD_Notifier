<#
	+-+-+-+-+-+-+-+-+-+
	|  A P C U P S D  |
	+-+-+-+-+-+-+-+-+-+
 
.SYNOPSIS
	APCUPSD Powershell Event Scripts

.DESCRIPTION
	Common Code for APCUPSD Powershell Event Scripts

.FUNCTIONALITY
	Called from apccontrol.bat.

.PARAMETER 

	
.NOTES

	
.EXAMPLE


#>

Param([string]$Event)
$Event = $Event.Trim()

<###   TWILIO VARIABLES   ###>
$SID       = "AC..............................2c"
$Token     = "27............................23"
$SMSFrom   = "+12125551212"

<###   EMAIL VARIABLES   ###>
$FromAddress      = 'notify@mydomain.tld'
$Subject          = 'APCUPSD Power Event Notification'
$SMTPServer       = 'mydomain.tld'
$SMTPAuthUser     = 'notify@mydomain.tld'
$SMTPAuthPass     = 'supersecretpassword'
$SMTPPort         = 587
$SSL              = $True
$UseHTML          = $False
$Recipients = @{
	"admin@mydomain.tld" = "+17185551718"
	"user@gmail.com" = "+16465551646"
}

<###   FUNCTIONS   ###>

Function Debug ($DebugOutput) {
	Write-Output "$(Get-Date -f G) : $DebugOutput" | Out-File "$PSScriptRoot/apcupsd-debug.log" -Encoding ASCII -Append
}

# Function to send SMS notification via Twilio
Function SendSMS ($Num, $Msg) {
	# Try to send message
	Try {
		$URL = "https://api.twilio.com/2010-04-01/Accounts/" + $SID + "/Messages.json"
		$Params = @{ To = $Num; From = $SMSFrom; Body = $Msg }
		$TokenSecureString = $Token | ConvertTo-SecureString -asPlainText -Force
		$Credential = New-Object System.Management.Automation.PSCredential($SID, $TokenSecureString)
		$Request = Invoke-WebRequest $URL -Method Post -Credential $Credential -Body $Params -UseBasicParsing
		$SentMsg = $Request | ConvertFrom-Json
		$StatusCode = $Request | Select-Object -Expand StatusCode
	}

	# If error, then throw error that script will pick up 
	Catch {
		Debug "ERROR : Twilio Send : $($Error[0])"
		Throw $Error[0]
	}

	# If status code indicates message not sent, then throw error that script will pick up 
	If ($StatusCode -ne 201) {
		Debug "ERROR : Twilio Send : StatusCode: $StatusCode"
		Throw $StatusCode
	}
}

# Function to send email notification
Function SendEmail ($Body, $Recipient) {
	Try {
		$Message = New-Object System.Net.Mail.Mailmessage $FromAddress, $Recipient, $Subject, $Body
		$Message.IsBodyHTML = $UseHTML
		$SMTP = New-Object System.Net.Mail.SMTPClient $SMTPServer,$SMTPPort
		$SMTP.EnableSsl = $SSL
		$SMTP.Credentials = New-Object System.Net.NetworkCredential($SMTPAuthUser, $SMTPAuthPass); 
		$SMTP.Send($Message)
	}
	Catch {
		Debug "Email ERROR : $($Error[0])"
	}
}

# Function to return event notification message  
Function EventMessage ($Event) {
	Switch ($Event) {
		"commfailure"   {Return "UPS communication error"; Break}
		"commok"        {Return "UPS communication restored"; Break}
		"powerout"      {Return "The power is out!"; Break}
		"onbattery"     {Return "Network on battery power"; Break}
		"offbattery"    {Return "Network power restored"; Break}
		"mainsback"     {Return "The power is restored"; Break}
		"failing"       {Return "UPS battery power exhausted - doing shutdown"; Break}
		"timeout"       {Return "UPS battery runtime limit exceeded - doing shutdown"; Break}
		"loadlimit"     {Return "UPS battery discharge limit reached - doing shutdown"; Break}
		"runlimit"      {Return "UPS battery runtime percent reached - doing shutdown"; Break}
		"doshutdown"    {Return "Initiating server shutdown due to UPS runtime exceeded"; Break}
		"annoyme"       {Return "UPS power problems - please logoff"; Break}
		"emergency"     {Return "Emergency UPS shutdown initiated"; Break}
		"changeme"      {Return "Emergency! UPS batteries have failed: Change them NOW"; Break}
		"remotedown"    {Return "Shutdown due to master state or comms lost"; Break}
		"startselftest" {Return "UPS self-test starting"; Break}
		"endselftest"   {Return "UPS self-test completed"; Break}
		"battdetach"    {Return "UPS battery disconnected"; Break}
		"battattach"    {Return "UPS battery reattached"; Break}
		Default {
			Debug "Unsupported Event : $Event : Quitting Script"
			Exit
		}
	}
}	

<###   START SCRIPT   ###>

# Create message
$Msg = EventMessage $Event

# Send to recipients
ForEach ($Key in $Recipients.Keys) {
	Try {SendSMS $($Recipients[$Key]) $Msg}
	Catch {SendEmail $($Key) $Msg}
}

# Send messagage to debug log
Debug $Msg

# If doshutdown command, then shut down the computer
If ($Event -eq "doshutdown") {
	Start-Sleep -seconds 7
	& shutdown /s /f /t 7
	Exit 99
}
