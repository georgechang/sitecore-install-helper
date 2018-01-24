function Install-JavaRuntime {
    [CmdletBinding(SupportsShouldProcess)]
	param(
		[string]$Url = "http://download.oracle.com/otn-pub/java/jdk/9.0.1+11/jre-9.0.1_windows-x64_bin.exe",
		[string]$Version = "9.0.1"
	)

	$tmp = New-TemporaryFile | Rename-Item -NewName {[System.IO.Path]::ChangeExtension($_.Name, ".exe")}
	#download the installer
	$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
	$cookie = New-Object System.Net.Cookie
	$cookie.Name = "oraclelicense"
	$cookie.Value = "accept-securebackup-cookie"
	$cookie.Domain = ".oracle.com"
	$session.Cookies.Add($cookie)
	Invoke-WebRequest -Uri $Url -WebSession $session -OutFile $tmp.FullName

	#install JRE
	Start-Process $tmp.FullName -ArgumentList "/s" -Wait

	#set environment vars
	[Environment]::SetEnvironmentVariable("PATH", "$env:programfiles\Java\jre-$Version\bin", [System.EnvironmentVariableTarget]::Machine)
	[Environment]::SetEnvironmentVariable("JAVA_HOME", "$env:programfiles\Java\jre-$Version", [System.EnvironmentVariableTarget]::Machine)
}