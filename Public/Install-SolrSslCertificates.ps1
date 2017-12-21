function Install-SolrSslCertificates {
	param(
		[string]$Path,
		[string]$KeyPass,
		[string]$StorePass
	)
	$env:Path += ";$env:programfiles\Java\jre-9.0.1\bin"
	& keytool.exe -genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass $KeyPass -storepass $StorePass -validity 365 -keystore solr-ssl.keystore.jks -ext SAN=DNS:localhost,IP:127.0.0.1 -dname "CN=localhost, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country"
	& keytool.exe -importkeystore -srcalias solr-ssl -destalias solr-ssl -srckeystore solr-ssl.keystore.jks -destkeystore solr-ssl.keystore.p12 -srcstoretype jks -deststoretype pkcs12 -srcstorepass $SrcKeystoreSecret -deststorepass $DestKeystoreSecret -srckeypass $SrcKeystoreSecret -destkeypass $DestKeystoreSecret -noprompt
	Copy-Item solr-ssl.keystore.jks $Path\server\etc

	$solrincmdContent = Get-Content $Path\bin\solr.in.cmd.bat

	foreach($content in $solrincmdContent)
	{
		if ($content -match "^REM set SOLR_SSL_(?!CLIENT)")
		{
			Write-Verbose "Old content: $content"
			$content = $content.replace("REM ", "")
			if ($content -match " SOLR_SSL_(KEY|TRUST)_STORE=")
			{
				$content = $content.Substring(0, $content.IndexOf('=')) + "=$solrServerKeystorePath"
			}
			elseif ($content -match " SOLR_SSL_(KEY|TRUST)_STORE_PASSWORD=")
			{
				$content = $content.Substring(0, $content.IndexOf('=')) + "=$SrcKeystoreSecret"
			}
			Write-Verbose "New content: $content"
		}
		Set-Content $solrincmdContent $content
	}

	$secureKeystoreSecret = ConvertTo-SecureString "secret" -AsPlainText -Force
	Import-PfxCertificate -FilePath "solr-ssl.keystore.p12" -CertStoreLocation "cert:\localmachine\root" -Password $secureKeystoreSecret
}