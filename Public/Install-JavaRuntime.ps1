function Install-JavaRuntime {
    [CmdletBinding()]
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