function Get-SitecoreInstallation {
	param(
		[string]$Path,
		[string]$Url,
		[string]$UserName,
		[string]$Password		
	)
	$loginRequest = Invoke-RestMethod -Uri https://dev.sitecore.net/api/authorization -Method Post -ContentType "application/json" -Body "{username: '$UserName', password: '$Password'}" -SessionVariable session -UseBasicParsing
	Invoke-WebRequest -Uri $url -WebSession $session -OutFile $Path -UseBasicParsing
}

function Install-JavaRuntime {
	param(
		[string]$Path,
		[string]$Url
	)

	#download the installer
	$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
	$cookie = New-Object System.Net.Cookie
	$cookie.Name = "oraclelicense"
	$cookie.Value = "accept-securebackup-cookie"
	$cookie.Domain = ".oracle.com"
	$session.Cookies.Add($cookie)
	Invoke-WebRequest -Uri $Url -WebSession $session -OutFile $Path -UseBasicParsing

	#install JRE
	& $FilePath /s

	#set environment vars
	[Environment]::SetEnvironmentVariable("PATH", "$env:programfiles\Java\jre-9.0.1\bin", [System.EnvironmentVariableTarget]::Machine)
	[Environment]::SetEnvironmentVariable("JAVA_HOME", "$env:programfiles\Java\jre-9.0.1", [System.EnvironmentVariableTarget]::Machine)
}

function Install-SolrServer {
	param(
		[string]$Path,
		[string]$DestinationPath
	)
	Invoke-WebRequest -Uri "http://mirrors.gigenet.com/apache/lucene/solr/6.6.2/solr-6.6.2.zip" -OutFile  $FilePath -UseBasicParsing
	Expand-Archive $FilePath -DestinationPath $InstallPath
}

function Install-SolrSSLCertificates {
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

function Install-SolrService {
	param(
		[string]$Path,
		[string]$Name
	)
	./nssm.exe install $Name "$Path\bin\solr.cmd" start -f -p 8983
	./nssm.exe set $Name DisplayName "Solr 6.6.2"
	./nssm.exe set $Name Description "Service for Solr 6.6.2"
}

function Install-ServerPrerequisities {
	#for WMF
	Write-Host "Checking server for Windows Features - IIS..."
	$feature = Get-WindowsFeature Web-Server
	if (!$feature.Installed) {
		Write-Host "Windows Feature - IIS is not installed. Installing..."
		Install-WindowsFeature Web-Server
		Write-Verbose "IIS Web Server feature has been installed."
		Install-WindowsFeature Web-Mgmt-Console
		Write-Verbose "IIS Management Console feature has been installed."
		#restart
	}
	else {
		Write-Host "Windows Feature - IIS has been detected. Skipping..."
	}

	Write-Host "Checking server for Windows Features - ASP.NET 4.5..."
	$feature = Get-WindowsFeature Web-Asp-Net45
	if (!$feature.Installed) {
		Write-Host "Windows Feature - ASP.NET 4.5 has not been installed. Installing..."
		Install-WindowsFeature Web-Asp-Net45
		Write-Verbose "ASP.NET 4.5 has been installed."
	}
	else {
		Write-Host "Windows Feature - ASP.NET 4.5 has been detected. Skipping..."
	}

	#install webpi
	Write-Host "Checking server for Web Platform Installer..."
	if (!Test-Path "C:\Program Files\Microsoft\Web Platform Installer\WebpiCmd-x64.exe")
	{
		$webpi = "https://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi"
		Write-Host "Web Platform Installer was not detected. Installing..."
		Write-Verbose "Downloading Web Platform Installer from $webpi..."
		Invoke-WebRequest -Uri $webpi -OutFile WebPlatformInstaller_amd64_en-US.msi
		Write-Verbose "Installing Web Platform Installer..."
		.\WebPlatformInstaller_amd64_en-US.msi /quiet
		Write-Verbose "Web Platform Installer installed successfully."
	}
	else {
		Write-Host "Web Platform Installer has been detected. Skipping..."
	}

	#install web deploy
	Write-Host "Checking server for Web Deploy 3.6..."
	if (!Test-Path "hklm:software\microsoft\iis extensions\msdeploy" -and Get-ChildItem "hklm:software\microsoft\iis extensions\msdeploy" -eq $null)
	{
		Write-Host "Web Deploy 3.6 was not detected. Installing with Web PI..."
		& "$env:programfiles\Microsoft\Web Platform Installer\WebpiCmd-x64.exe" /install /products:WDeploy36 /AcceptEULA
		Write-Host "Web Deploy 3.6 has been successfully installed."
	}
	else {
		Write-Host "Web Deploy 3.6 has been detected. Skipping..."
	}

	#install dacfx
	Write-Host "Checking server for SQL Server 2016 Data-Tier Application Framework..."
	if (!Test-Path "${env:programfiles(x86)}\Microsoft SQL Server\140\DAC\bin\Microsoft.SqlServer.Dac.dll")
	{
		Write-Host "SQL Server 2016 Data-Tier Application Framework was not detected. Installing..."
		#2017
		#Invoke-WebRequest -Uri "https://download.microsoft.com/download/F/9/3/F938FCDD-3FAF-40DF-A530-778898E2E5EE/EN/x64/DacFramework.msi" -OutFile DacFramework2017-x64.msi
		#.\DacFramework2017-x64.msi /quiet

		#Invoke-WebRequest -Uri "https://download.microsoft.com/download/5/2/8/528EE32B-A63B-462A-BF86-48EDE3DDF5A6/EN/x86/DacFramework.msi" -OutFile DacFramework2017-x86.msi
		#.\DacFramework2017-x86.msi /quiet

		#2016
		$dac64 = "https://download.microsoft.com/download/5/E/4/5E4FCC45-4D26-4CBE-8E2D-79DB86A85F09/EN/x64/DacFramework.msi"
		$dac86 = "https://download.microsoft.com/download/5/E/4/5E4FCC45-4D26-4CBE-8E2D-79DB86A85F09/EN/x86/DacFramework.msi"
		Write-Verbose "Downloading DACFx x64 from $dac64..."
		Invoke-WebRequest -Uri $dac64 -OutFile DacFramework2016-x64.msi
		Write-Verbose "Download of DACFx x64 successful."
		Write-Verbose "Installing DACFx x64..."
		.\DacFramework2016-x64.msi /quiet
		Write-Verbose "Installation of DACFx x64 successful."

		Write-Verbose "Downloading DACFx x86 from $dac86..."
		Invoke-WebRequest -Uri $dac86 -OutFile DacFramework2016-x86.msi
		Write-Verbose "Download of DACFx x86 successful."
		Write-Verbose "Installing DACFx x86..."
		.\DacFramework2016-x86.msi /quiet
		Write-Verbose "Installation of DACFx x86 successful."

		Write-Host "SQL Server 2016 Data-Tier Application Framework has been successfully installed."
	}
	else {
		Write-Host "SQL Server 2016 Data-Tier Application Framework has been detected. Skipping..."
	}

	#install CLR Types
	Write-Host "Checking server for CLR Types for SQL Server 2016..."
	if (!Test-Path "${env:programfiles(x86)}\Microsoft SQL Server\140\DAC\bin\Microsoft.SqlServer.Types.dll")
	{
		Write-Host "CLR Types for SQL Server 2016 was not detected. Installing..."
		#2017
		#Invoke-WebRequest -Uri "https://download.microsoft.com/download/C/1/9/C1917410-8976-4AE0-98BF-1104349EA1E6/x64/SQLSysClrTypes.msi" -OutFile SQLSysClrTypes2017-x64.msi
		#.\SQLSysClrTypes2017-x64.msi /quiet

		#2016
		$clr2016 = "https://download.microsoft.com/download/8/7/2/872BCECA-C849-4B40-8EBE-21D48CDF1456/ENU/x64/SQLSysClrTypes.msi"
		Write-Verbose "Downloading CLR Types 2016 from $clr2016..."
		Invoke-WebRequest -Uri  -OutFile SQLSysClrTypes2016-x64.msi
		Write-Verbose "Download of CLR Types 2016 successful."
		Write-Verbose "Installing CLR Types 2016..."
		.\SQLSysClrTypes2016-x64.msi /quiet
		Write-Host "CLR Types for SQL Server 2016has been successfully installed."
	}
	else {
		Write-Host "CLR Types for SQL Server 2016 has been detected. Skipping..."
	}

	#install SQLSMO
	Write-Host "Checking server for SQL Server 2016 Management Objects..."
	if (!Test-Path "${env:programfiles(x86)}\Microsoft SQL Server\140\DAC\bin\Microsoft.SqlServer.Types.dll")
	{
		Write-Host "SQL Server 2016 Management Objects was not detected. Installing..."
		$smo = "https://download.microsoft.com/download/8/7/2/872BCECA-C849-4B40-8EBE-21D48CDF1456/ENU/x64/SharedManagementObjects.msi"
		Write-Verbose "Downloading SMO 2016 from $smo..."
		Invoke-WebRequest -Uri  -OutFile SharedManagementObjects-x64.msi
		Write-Verbose "Download of SMO 2016 successful."
		Write-Verbose "Installing SMO 2016..."
		.\SharedManagementObjects-x64.msi /quiet
		Write-Host "SQL Server 2016 Management Objects has been successfully installed."
	}
	else {
		Write-Host "SQL Server 2016 Management Objects has been detected. Skipping..."
	}


	#install .net 4.6.2
	Write-Host "Checking server for ASP.NET 4.6.2..."
	if (Get-ChildItem "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Get-ItemPropertyValue -Name Release | ForEach-Object { $_ -lt 394802 })
	{
		Write-Host "ASP.NET 4.6.2 was not detected. Installing..."
		$aspnet462 = "https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe"
		Write-Verbose "Downloading ASP.NET 4.6.2 from $aspnet462..."
		Invoke-WebRequest -Uri  -OutFile NDP462-KB3151800-x86-x64-AllOS-ENU.exe
		Write-Verbose "Download of ASP.NET 4.6.2 successful."
		Write-Verbose "Installing ASP.NET 4.6.2..."
		.\NDP462-KB3151800-x86-x64-AllOS-ENU.exe /install /quiet
		Write-Host "ASP.NET 4.6.2 has been successfully installed."
	}
}

Register-PSRepository -Name SitecoreGallery
# run install-sitecoreinstallationmodules

Install-SitecoreConfiguration -Path ./xconnect-solr.json -SolrUrl https://localhost:8983/solr -SolrRoot C:\solr-6.6.2 -SolrService solr662 -CorePrefix sask

Install-SitecoreConfiguration -Path ./xconnect-xp0.json -Package './Sitecore 9.0.0 rev. 171002 (Hybrid)_xp0xconnect.scwdp.zip' -LicenseFile ./license.xml -XConnectCert www-dc9-cm-q1 -SqlDbPrefix "sask" -SqlServer saskpower-qadev-sqlelastic.database.windows.net -SqlAdminUser serveradmin -SqlAdminPassword saskSC9azure -SolrCorePrefix "sask" -SolrUrl "https://localhost:8983/solr"

Install-SitecoreConfiguration -Path ./sitecore-solr.json -SolrUrl https://localhost:8983/solr -SolrRoot C:\solr-6.6.2 -SolrService solr662 -CorePrefix 'sask'

Install-SitecoreConfiguration -Path ./sitecore-XP0.json -Package '.\Sitecore 9.0.0 rev. 171002 (Hybrid)_single.scwdp.zip' -LicenseFile .\license.xml -SolrCorePrefix 'sask' -SolrUrl https://localhost:8983/solr -XConnectCert www-dc9-cm-q1 -SiteName 'sask' -XConnectCollectionService https://xconnect -SqlDbPrefix 'sask' -SqlServer saskpower-qadev-sqlelastic.database.windows.net -SqlAdminUser 'serveradmin' -SqlAdminPassword 'saskSC9azure'

New-WebBinding -Name sask -Protocol https -Port 443 -HostHeader sask
#associate cert with web binding

