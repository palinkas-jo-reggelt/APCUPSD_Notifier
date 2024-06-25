# APCUPSD Notifier
Powershell script to notify on APCUPSD events and shut down computer.

Uses Twilio SMS and System.Net.Mail.Mailmessage for delivering notifications.

Copy apccontrol.bat and apcupsd.ps1 to C:\apcupsd\etc\apcupsd (or your apcupsd script dir) then change the variables in apcupsd.ps1. 

Note: review path in apccontrol.bat.
