function fetch_data(){
  try{
    $Host.UI.RawUI.WindowTitle = "Setup Host"
    # $dataUrl = "http://169.254.169.254/latest/meta-data"
    # $hostNameRaw = Invoke-WebRequest "$dataUrl/local-hostname" | foreach {$_.Content.split(".")[0]}
    # $hostName = $hostNameRaw.toUpper()

    $finishFlag = "$ENV:SystemRoot\System32\finish.flg"
    # if ((${env:computerName} -ne $hostName) -and ($hostName -ne $null)){
    if ((Test-Path $finishFlag) -ne $true){
      Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoLogonCount
      Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name AutoAdminLogon -value 0

      # Expire Administrator password
      $user = [ADSI]'WinNT://localhost/Administrator'
      $user.passwordExpired = 1
      $user.setinfo()

      Set-Content -Path "$finishFlag" -Value "done"
      Set-Service -name puppet -startupType Automatic
      $services = Get-WMIObject win32_service | Where-Object {$_.description -imatch "puppet" -and $_.startmode -eq "Auto"}; foreach ($service in $services){sc.exe failure $service.name reset= 86400 actions= restart/5000}
      Remove-Item "hklm:\Software\Cloudbase Solutions\Cloudbase-Init" -Recurse
      Restart-Computer -Force
    }
    } catch {
      Start-Sleep -s 30
      fetch_data
    }
}

fetch_data
