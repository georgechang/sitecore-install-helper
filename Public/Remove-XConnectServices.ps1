function Remove-XConnectServices {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Prefix
	)
	
	Start-Process "net" -ArgumentList "stop", "$Prefix.xconnect-MarketingAutomationService" -NoNewWindow -Wait
	Start-Process "net" -ArgumentList "stop", "$Prefix.xconnect-IndexWorker" -NoNewWindow -Wait

	Start-Process "sc.exe" -ArgumentList "delete", "$Prefix.xconnect-MarketingAutomationService" -NoNewWindow -Wait
	Start-Process "sc.exe" -ArgumentList "delete", "$Prefix.xconnect-IndexWorker" -NoNewWindow -Wait
}