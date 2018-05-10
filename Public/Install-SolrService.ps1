function Install-SolrService {
    [CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$Path,
		[Parameter(Mandatory)]
		[string]$NssmPath,
		[string]$Name = "solr662",
		[ValidateRange(0, 65535)]
		[int]$Port = 8983,
		[string]$ServiceDisplayName = "Solr 6.6.2",
		[string]$ServiceDescription = "Service for Solr 6.6.2",
		[string]$Uri = "https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip",
		[switch]$SkipNssmInstall
	)

	$activity = "Installing Solr Service..."

	if (-not $SkipNssmInstall) {
		Write-Progress -Activity $activity -Status "Downloading Nssm package..."
		if ($PSCmdlet.ShouldProcess($Uri, "Downloading package")) {
			$tmp = [IO.Path]::GetTempFileName() | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
			Invoke-WebRequest -Uri $Uri -OutFile  $tmp.FullName
		}
		Write-Progress -Activity $activity -Status "Extracting Nssm package to $NssmPath..."
		if ($PSCmdlet.ShouldProcess($tmp.FullName, "Extract package")) {
			Expand-Archive $tmp.FullName -DestinationPath $NssmPath -Force
		}
	}
	Write-Progress -Activity $activity -Status "Installing Solr service ($Name) to Solr instance at $Path..."
	Write-Verbose "Creating NSSM service to $Path..."
	if ($PSCmdlet.ShouldProcess($Name, "Install service")) {
		$NssmExePath = Get-ChildItem -Path $NssmPath -Filter nssm.exe -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1
		
		if ($NssmExePath) {
			Write-Verbose "nssm.exe found at $NssmExePath.FullName"
			if (-not (Get-Service $Name)) {
				& $NssmExePath.FullName install $Name $Path\bin\solr.cmd start -f -p $Port
				& $NssmExePath.FullName set $Name DisplayName $ServiceDisplayName
				& $NssmExePath.FullName set $Name Description $ServiceDescription
			}
			else {
				& $NssmExePath.FullName set $Name ImagePath $Path\bin\solr.cmd start -f -p $Port
				& $NssmExePath.FullName set $Name DisplayName $ServiceDisplayName
				& $NssmExePath.FullName set $Name Description $ServiceDescription
			}
		}
	}

	Write-Progress -Activity $activity -Status "Starting Solr service ($Name)..."
	if ($PSCmdlet.ShouldProcess($Name, "Start service")) {
		Set-Service $Name -Status Running
	}
}