## ask
- installing .NET (reboot flag)
- format drives
- coreFTP
- 7zip
- MSSQL
- application configuration
- network configuration
- provision new host
- run a few steps after MS MQ(?) craps out network

## solution - Ansible
1. Enable connectivity:
  [WinRM](https://learn.microsoft.com/en-us/troubleshoot/windows-client/system-management-components/configure-winrm-for-https)
  [SSH](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration)
  [SSH 2](https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/ssh-on-windows-server-2019/ba-p/570740)
2. Configure Ansible for use with WinRM
  [General](https://docs.ansible.com/ansible/latest/os_guide/windows_winrm.html)

- PowerShell

## trackdown
### Environmental

### Connecting
>= Windows 2019? ssh
< Windows 2019? WinRM
> WinRM over HTTPS and Windows Firewall configuration is annoyingly frustrating to get right. Look for the long PS1 script that will help set this up for you. It's floating around the Ansible docs and/or GitHub repos


### Capabilities
- Gather facts on Windows hosts
- Install and uninstall MSIs
- Enable and disable Windows Features
- Start, stop, and manage Windows services
- Create and manage local users and groups
- Manage Windows packages via the Chocolatey package manager
- Manage and install Windows updates
- Fetch files from remote sites
- Push and execute any PowerShell scripts you write

### How
Winget or Chocolatey for applications
 - Winget for MSI, MSIX

---

# The Plan:
Use cloud_init for initial Virtual server deployment to enable win-rm (if 2016) and then use Ansible to do post configs. 

1. Use cloud_init for initial Virtual server deployment to enable WinRM or OpenSSH and potentially some powershell work. (Powershell Version 5.1 is on Windows Server 2016. Ansible requires 3.0, so 2016 or later will be fine.)
https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1
powershell.exe -ExecutionPolicy ByPass -File $file (-DisableBasicAuth) (-SkipNetworkProfileCheck) (-ForceNewSSLCert)
    # Create a basic auth
    ## windows
    echo y | winrm quickconfig (-transport:https)   

    ## mgmt node
    session2 = winrm.Session('0.0.0.0',auth=('Administratii','U1TBNwT97CQ1VQqyxuyX'))
    result = session2.run_ps("(Get-WindowsFeature).Where{$PSItem.Installed}")
    

    # Create a Cerficiate auth
    ## windows
    New-SelfSignedCertificate -DnsName <your_server_dns_name_or_whatever_you_like> -CertStoreLocation Cert:\LocalMachine\My
    New-SelfSignedCertificate -DnsName jxwina -CertStoreLocation Cert:\LocalMachine\My

    winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=”<your_server_dns_name_or_whatever_you_like>”; CertificateThumbprint=”<certificate_from_prev_cmd>”}
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=”jxwina”; CertificateThumbprint=”74CA04A0A1D58AB91123C1D33F24785AE54A2A17”}


    ## mgmt node
    $so = New-PsSessionOption –SkipCACheck -SkipCNCheck
    Enter-PSSession -ComputerName <ip_address_or_dns_name_of_server>  -Credential <local_admin_username> -UseSSL -SessionOption $so
    Enter-PSSession -ComputerName 0.0.0.0  -Credential Administratii -UseSSL -SessionOption $so

    # Remove all winrm listeners
    Remove-Item -Path WSMan:\localhost\Listener\* -Recurse -Force

2. Use Ansible for post configs

        // PowerShell way
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        //Ansible Way
        - name: Ensure Chocolatey itself is installed, using community repo for the bootstrap
          win_chocolatey:
            name: chocolatey
            #bootstrap_script: https://internal-web-server/files/custom-chocolatey-install.ps1



3. Use Choco | scoop | powershell for package installations
 > Winget won't work because it requires more up-to-date than even 2022
    - Choco
        echo Y | choco install openssh
    - Powershell
        Invoke-WebRequest -Method GET -uri https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile "C:\Users\Administrator\DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        add-appxpackage -Path ".\DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"





----------------------------
#Windows 2016
Windows:
 1.
 
       [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
       (get-ChildItem Cert:\LocalMachine\My).Thumbprint
       winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=”<your_server_dns_name_or_whatever_you_like>”; CertificateThumbprint=”<certificate_from_prev_cmd>”}
      
      
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=”<your_server_dns_name_or_whatever_you_like>”; CertificateThumbprint=”<certificate_from_prev_cmd>”}
      
      $thumbprint=(get-ChildItem Cert:\LocalMachine\My).Thumbprint
      0705EF813F026C964466A137F4B7851800C70FFD
      
      $pcname=$env:ComputerName
      JXWINC
      winrm create winrm/config/Listener?Address=*+Transport-HTTPS @{Hostname="$pcname"; CertificateThumbprint="$thumbprint"}

