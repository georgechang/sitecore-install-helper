function Remove-WindowsService {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Name
	)
	
	if ($service = Get-Service $Name -ErrorAction SilentlyContinue) {
		if ($service.Status -eq "Running") {
			Write-Verbose ("Stopping service " + $service.Name + "...")
			Stop-Service $Name
		}
		Write-Verbose ("Removing service " + $service.Name + "...")
		Start-Process "sc.exe" -ArgumentList "delete", $Name -NoNewWindow -Wait
	}
}