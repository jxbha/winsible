# Very basic script to bootstrap WinRM for Ansible on a Windows 2016 Server. https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 is way more robust, but this does the absolute minimum to the best of my Windows knowledge.

# Disable TLS1.3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set DNS Name for certificate
$pcname=$env:ComputerName

# Create self-signed certificate
New-SelfSignedCertificate -DnsName $pcname -CertStoreLocation Cert:\LocalMachine\My

# Set certificate thumbprint for listener
$thumbprint=(get-ChildItem Cert:\LocalMachine\My).Thumbprint

# Set listener command for CMD prompt
$execute="winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=`"$pcname`";CertificateThumbprint=`"$thumbprint`"}"

# Pipe listener command to CMD
& cmd /c $execute

#Open port 5986 for WinRM HTTPS
netsh advfirewall firewall add rule profile=any name="Allow WinRM HTTPS" dir=in localport=5986 protocol=TCP action=allow

# Enable basic WinRM connectivity
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
