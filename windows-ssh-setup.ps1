# Copyright (c) Joseph Hale, 2026
# SPDX-License-Identifier: MPL-2.0

using namespace System.Security.Principal

param(
	[string]$User = (Read-Host 'GitHub username whose ssh keys to trust')
)

$ErrorActionPreference = 'Stop'
$source = $MyInvocation.MyCommand.ScriptBlock
$administrators = [SecurityIdentifier]::new([WellKnownSidType]::BuiltinAdministratorsSid, $null).Value
$system = [SecurityIdentifier]::new([WellKnownSidType]::LocalSystemSid, $null).Value

function Main {
	$keys = Get-GitHubKeys $User
	if (Test-Elevated) {
		Enable-Sshd
		Enable-GitBash
		Grant-AdministratorKeys $keys
	} elseif (Test-AdministratorAccount) {
		Restart-AsAdministrator
	} else {
		Assert-Sshd
		Grant-UserKeys $keys
	}
}

function Get-GitHubKeys($user) {
	if (-not $user) {
		throw "No GitHub username given.`nRerun and enter the username whose ssh keys to trust."
	}
	$keys = ([string](Request-GitHubKeys $user)).Trim()
	if (-not $keys) {
		throw "GitHub lists no ssh keys for $user.`nAdd one at https://github.com/settings/keys, then rerun."
	}
	$keys
}

function Request-GitHubKeys($user) {
	try {
		Invoke-RestMethod "https://github.com/${user}.keys"
	} catch {
		if ($_.Exception.Response.StatusCode -eq 404) {
			throw "GitHub has no user named $user.`nCheck the spelling, then rerun."
		} else {
			throw "Could not reach github.com: $($_.Exception.Message)`nCheck the internet connection, then rerun."
		}
	}
}

function Test-Elevated {
	$principal = [WindowsPrincipal][WindowsIdentity]::GetCurrent()
	$principal.IsInRole([WindowsBuiltInRole]::Administrator)
}

function Enable-Sshd {
	Install-Sshd
	Start-Sshd
	Disable-SshPasswords
	Open-SshPort
}

function Install-Sshd {
	$capability = Get-WindowsCapability -Online -Name 'OpenSSH.Server*'
	if (-not $capability) {
		throw "This version of Windows has no OpenSSH Server feature.`nUpdate to Windows 10 version 1809 or later, then rerun."
	} elseif ($capability.State -eq 'Installed') {
		Write-Host "$($capability.Name) is already installed"
	} else {
		Add-Capability $capability.Name
	}
}

function Add-Capability($name) {
	Write-Host "Installing $name"
	try {
		Add-WindowsCapability -Online -Name $name | Out-Null
	} catch {
		throw "Windows could not install ${name}: $($_.Exception.Message)`nAdd $name in Settings > System > Optional features, then rerun."
	}
}

function Start-Sshd {
	Set-Service -Name sshd -StartupType Automatic
	try {
		Start-Service sshd
	} catch {
		throw "sshd would not start: $($_.Exception.Message)`nStop any other program using port 22, or read Event Viewer > Applications and Services Logs > OpenSSH > Operational, then rerun."
	}
	Write-Host 'sshd is running and starts with Windows'
}

function Disable-SshPasswords {
	$path = "$env:ProgramData\ssh\sshd_config"
	$settings = 'PasswordAuthentication no', 'KbdInteractiveAuthentication no'
	$config = Get-Content $path
	if ($config[0] -ne $settings[0]) {
		Set-Content -Path $path -Value ($settings + $config) -Encoding ascii
		Restart-Service sshd
	}
	Write-Host 'sshd accepts keys only, not passwords'
}

function Open-SshPort {
	$rule = 'OpenSSH-Server-In-TCP'
	if (-not (Get-NetFirewallRule -Name $rule -ErrorAction SilentlyContinue)) {
		New-NetFirewallRule -Name $rule -DisplayName 'OpenSSH Server (sshd)' -Enabled False | Out-Null
	}
	$scope = @{
		Name          = $rule
		Enabled       = 'True'
		Direction     = 'Inbound'
		Action        = 'Allow'
		Protocol      = 'TCP'
		LocalPort     = 22
		Profile       = 'Private'
		RemoteAddress = 'LocalSubnet'
	}
	Set-NetFirewallRule @scope
	Write-Host 'The firewall allows ssh on port 22 from the local subnet of private networks'
}

function Enable-GitBash {
	$bash = "$env:ProgramFiles\Git\bin\bash.exe"
	Install-Git $bash
	Set-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value $bash
	Write-Host "ssh sessions start in $bash"
}

function Install-Git($bash) {
	if (Test-Path $bash) {
		Write-Host 'Git is already installed'
	} else {
		Add-Package 'Git.Git'
		Assert-Git $bash
	}
}

function Add-Package($id) {
	Write-Host "Installing $id"
	Assert-Winget
	winget install `
		--id $id `
		--exact `
		--silent `
		--scope machine `
		--accept-package-agreements `
		--accept-source-agreements
}

function Assert-Winget {
	if (-not (Test-Winget)) {
		Register-Winget
	}
	if (-not (Test-Winget)) {
		throw "winget is missing.`nUpdate App Installer from https://apps.microsoft.com/detail/9NBLGGH4NNS1, then rerun."
	}
}

function Test-Winget {
	[bool](Get-Command winget -ErrorAction SilentlyContinue)
}

function Register-Winget {
	Write-Host 'Registering winget'
	try {
		Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
	} catch {
		Write-Host "Could not register winget: $($_.Exception.Message)"
	}
}

function Assert-Git($bash) {
	if (-not (Test-Path $bash)) {
		throw "Git did not install to $bash.`nInstall Git from https://git-scm.com/download/win in its default location, then rerun."
	}
}

function Grant-AdministratorKeys($keys) {
	$path = "$env:ProgramData\ssh\administrators_authorized_keys"
	Save-Keys $keys $path
	icacls $path `
		/inheritance:r `
		/grant "*${administrators}:F" `
		/grant "*${system}:F" |
		Out-Null
}

function Test-AdministratorAccount {
	[bool](whoami /groups | Select-String $administrators)
}

function Restart-AsAdministrator {
	$path = Save-Script
	Write-AdministratorSteps
	try {
		Start-Elevated $path "-User '$User'"
	} finally {
		Remove-Item $path
	}
}

function Save-Script {
	$path = Join-Path ([IO.Path]::GetTempPath()) 'windows-ssh-setup.ps1'
	Set-Content -Path $path -Value $source -Encoding utf8
	$path
}

function Write-AdministratorSteps {
	Write-Host @'
Windows will ask for administrator approval to:
  - install the ssh server and Git
  - turn off password login
  - open port 22 to the local network
  - make Git Bash the ssh shell
  - trust these keys for administrators
'@
}

function Start-Elevated($path, $arguments) {
	$log = "$path.log"
	try {
		$exitCode = Wait-Elevated "& { try { & '$path' $arguments } catch { `$_; exit 1 } } *> '$log'"
		Get-Content $log
	} finally {
		Remove-Item $log -ErrorAction SilentlyContinue
	}
	if ($exitCode -ne 0) {
		throw 'The administrator PowerShell stopped early. Its messages above say why.'
	}
}

function Wait-Elevated($command) {
	$launch = @{
		FilePath     = (Get-Process -Id $PID).Path
		ArgumentList = '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command
		Verb         = 'RunAs'
		WindowStyle  = 'Hidden'
		Wait         = $true
		PassThru     = $true
	}
	try {
		(Start-Process @launch).ExitCode
	} catch {
		throw "Windows did not get administrator approval.`nRerun and choose Yes when asked, or run this from an administrator PowerShell."
	}
}

function Assert-Sshd {
	if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
		throw "sshd is not installed on this machine.`nAsk an administrator to run this script once, then rerun it from this account."
	}
}

function Grant-UserKeys($keys) {
	$path = "$env:USERPROFILE\.ssh\authorized_keys"
	New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
	Save-Keys $keys $path
}

function Save-Keys($keys, $path) {
	Set-Content -Path $path -Value $keys -Encoding ascii
	Write-Host "$path now trusts these keys:"
	ssh-keygen -l -f $path
}

Main
