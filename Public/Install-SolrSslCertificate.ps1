function Install-SolrSslCertificate {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$Path,
		[Parameter(Mandatory)]
		[SecureString]$KeyPass,
		[Parameter(Mandatory)]
		[SecureString]$StorePass,
		[string]$HostName = "localhost",
		[string]$IpAddress = "127.0.0.1",
		[string]$DistinguishedName = "CN=localhost, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country",
		[Parameter(Mandatory)]
		[string]$ServiceName,
		[string]$JksFileName = "solr-ssl.keystore.jks",
		[string]$P12FileName = "solr-ssl.keystore.p12",
		[int]$CertificateValidityInDays = 365
	)
	$keypassBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($KeyPass)
	$keypassValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($keypassBstr)

	$storepassBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($StorePass)
	$storepassValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($storepassBstr)

	$activity = "Setting up SSL for Solr..."

	Write-Verbose "Adding Java bin folder to path temporarily..."
	$env:Path += ";$env:JAVA_HOME\bin"

	Write-Progress -Activity $activity -Status "Generating SSL keys..."
	if ($PSCmdlet.ShouldProcess($Path, "Creating keys")) {
		Start-Process "keytool.exe" -ArgumentList "-genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass $keypassValue -storepass $storepassValue -validity $CertificateValidityInDays -keystore $JksFileName -ext SAN=DNS:$HostName,IP:$IpAddress -dname ""$DistinguishedName""" -NoNewWindow -Wait
		Start-Process "keytool.exe" -ArgumentList "-importkeystore -srcalias solr-ssl -destalias solr-ssl -srckeystore $JksFileName -destkeystore $P12FileName -srcstoretype jks -deststoretype pkcs12 -srcstorepass $storepassValue -deststorepass $storepassValue -srckeypass $keypassValue -destkeypass $keypassValue -noprompt" -NoNewWindow -Wait
		Copy-Item solr-ssl.keystore.jks $Path\server\etc
	}

	Write-Progress -Activity $activity -Status "Updating Solr configuration for SSL..."
	if ($PSCmdlet.ShouldProcess($Path, "Updating Solr config")) {
		$solrincmdContent = Get-Content $Path\bin\solr.in.cmd
		$newContent = ""
		foreach ($content in $solrincmdContent) {
			if ($content -match "^REM set SOLR_SSL_(?!CLIENT)") {
				Write-Verbose "Old content: $content"
				$content = $content.replace("REM ", "")
				if ($content -match " SOLR_SSL_(KEY|TRUST)_STORE=") {
					$content = $content.Substring(0, $content.IndexOf('=')) + "=$Path\server\etc\solr-ssl.keystore.jks"
				}
				elseif ($content -match " SOLR_SSL_(KEY|TRUST)_STORE_PASSWORD=") {
					$content = $content.Substring(0, $content.IndexOf('=')) + "=$storepassValue"
				}
				Write-Verbose "New content: $content"
			}

			$newContent += $content
			$newContent += "`r`n"
		}
		Set-Content -Path $Path\bin\solr.in.cmd -Value $newContent
	}

	Write-Progress -Activity $activity -Status "Importing SSL certificate to certificate store..."
	if ($PSCmdlet.ShouldProcess($Path, "Import certificate")) {
		Import-PfxCertificate -FilePath $P12FileName -CertStoreLocation "cert:\localmachine\root" -Password $StorePass
	}

	Write-Progress -Activity $activity -Status "Restarting Solr Service..."
	if ($PSCmdlet.ShouldProcess($Path, "Restart service")) {
		Set-Service $ServiceName -Status Stopped
		Set-Service $ServiceName -Status Running
	}

	Write-Progress -Activity $activity -Completed
}