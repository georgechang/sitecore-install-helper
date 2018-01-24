function Install-SolrSslCertificates {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$Path,
		[Parameter(Mandatory)]
		[string]$KeyPass,
		[Parameter(Mandatory)]
		[string]$StorePass,
		[string]$HostName = "localhost",
		[string]$IpAddress = "127.0.0.1",
		[string]$DistinguishedName = "CN=localhost, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country",
		[Parameter(Mandatory)]
		[string]$ServiceName,
		[string]$JksFileName = "solr-ssl.keystore.jks",
		[string]$P12FileName = "solr-ssl.keystore.p12"
	)
	$activity = "Setting up SSL for Solr..."

	Write-Verbose "Adding JRE bin folder to path temporarily..."
	Write-Progress -Activity $activity -Status "Generating SSL keys..."
	$env:Path += ";$env:programfiles\Java\jre-9.0.1\bin"
	if ($PSCmdlet.ShouldProcess($Path, "Creating keys")) {
		& keytool.exe -genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass $KeyPass -storepass $StorePass -validity 365 -keystore $JksFileName -ext SAN=DNS:$HostName,IP:$IpAddress -dname "$DistinguishedName"
		& keytool.exe -importkeystore -srcalias solr-ssl -destalias solr-ssl -srckeystore $JksFileName -destkeystore $P12FileName -srcstoretype jks -deststoretype pkcs12 -srcstorepass $StorePass -deststorepass $StorePass -srckeypass $KeyPass -destkeypass $KeyPass -noprompt
		Copy-Item solr-ssl.keystore.jks $Path\server\etc
	}

	Write-Progress -Activity $activity -Status "Updating Solr configuration for SSL..."
	if ($PSCmdlet.ShouldProcess($Path, "Updating Solr config")) {
		$solrincmdContent = Get-Content $Path\bin\solr.in.cmd
		$newContent = ""
		foreach($content in $solrincmdContent)
		{
			if ($content -match "^REM set SOLR_SSL_(?!CLIENT)")
			{
				Write-Verbose "Old content: $content"
				$content = $content.replace("REM ", "")
				if ($content -match " SOLR_SSL_(KEY|TRUST)_STORE=")
				{
					$content = $content.Substring(0, $content.IndexOf('=')) + "=$Path\server\etc\solr-ssl.keystore.jks"
				}
				elseif ($content -match " SOLR_SSL_(KEY|TRUST)_STORE_PASSWORD=")
				{
					$content = $content.Substring(0, $content.IndexOf('=')) + "=$StorePass"
				}
				Write-Verbose "New content: $content"
			}

			$newContent += $content
			$newContent += "`r`n"
		}
		Set-Content -Path $Path\bin\solr.in.cmd -Value $newContent
	}

	Write-Progress -Activity $activity -Status "Import SSL certificate to certificate store"
	if ($PSCmdlet.ShouldProcess($Path, "Import certificate")) {
		$secureKeystoreSecret = ConvertTo-SecureString $KeyPass -AsPlainText -Force
		Import-PfxCertificate -FilePath $P12FileName -CertStoreLocation "cert:\localmachine\root" -Password $secureKeystoreSecret
	}

	Set-Service $ServiceName -Status Stopped
	Set-Service $ServiceName -Status Running
}