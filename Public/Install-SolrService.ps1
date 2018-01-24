function Install-SolrService {
    [CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$Path,
		[string]$Name = "solr662",
		[ValidateRange(0, 65535)]
		[int]$Port = 8983,
		[string]$ServiceDisplayName = "Solr 6.6.2",
		[string]$ServiceDescription = "Service for Solr 6.6.2"
	)

	$activity = "Installing Solr Service..."

	if ($PSCmdlet.ShouldProcess($Name, "Install service")) {
		if (-not (Get-Service $Name)) {
			Write-Progress -Activity $activity -Status "Installing Solr service ($Name) to Solr instance at $Path..."
			New-Service -Name $Name -BinaryPathName "$Path\bin\solr.cmd start -f -p $Port" -DisplayName $ServiceDisplayName -Description $ServiceDescription
		}
		else {
			Write-Progress -Activity $activity -Status "Windows service ($Name) already exists, skipping service install..."
		}
	}

	Write-Progress -Activity $activity -Status "Starting Solr service ($Name)..."
	if ($PSCmdlet.ShouldProcess($Name, "Start service")) {
		Set-Service $Name -Status Running
	}
}