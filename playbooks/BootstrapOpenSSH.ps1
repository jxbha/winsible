# Very basic script to bootstrap WinRM for Ansible on a Windows Server 2016 and older.

# Enable OpenSSH
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Configure ssh daemon to automatically start (NOTE: This may not be necessary if you don't want to remotely manage the system after bootstrapping)
Set-Service sshd -StartupType Automatic

# Configure ssh agent to automatically start (NOTE: This may not be necessary if you don't want to remotely manage the system after bootstrapping)
Set-Service ssh-agent -StartupType Automatic

# Start SSH daemon
Start-Service sshd

# Start SSH agent
Start-Service ssh-agent

# Set powershell as the default shell for OpenSSH
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
