function Remove-SqlServerDatabases {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Prefix,
		[string]$Username,
		[securestring]$Password
	)
	
	if (-not (Get-Module SqlServer -ListAvailable)) {
		Import-Module SqlServer
	}

	#$credential = New-SqlCredential -Name "sqlcredential" -Identity $Username -Secret $Password
	
	$databases = Get-SqlInstance -Path "SQLSERVER:\SQL\$env:computername\DEFAULT" | Get-SqlDatabase | ? { $_.Name.StartsWith($Prefix + "_") }

	for ($i = 0; $i -lt $databases.Count; $i++) {
		Write-Verbose ("Dropping database " + $databases[$i].Name + "...")
		$databases[$i].Drop()
	}
}