[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new()
chcp 65001 > $null
$ErrorActionPreference='Continue'
function KV($k,$v){ Write-Output ("$k=$v") }
KV 'Now' (Get-Date -Format o)
KV 'IsAdmin' ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
try { $ci=Get-ComputerInfo; KV 'Product' $ci.WindowsProductName; KV 'Edition' $ci.WindowsEditionId; KV 'Version' $ci.WindowsVersion; KV 'Build' $ci.OsBuildNumber } catch { KV 'ComputerInfoError' $_.Exception.Message }
try { KV 'HypervisorPresent' ((Get-CimInstance Win32_ComputerSystem).HypervisorPresent) } catch { KV 'HypervisorPresentError' $_.Exception.Message }
$features='Containers-DisposableClientVM','Microsoft-Hyper-V-All','VirtualMachinePlatform','Microsoft-Windows-Subsystem-Linux','Containers'
foreach($f in $features){ try { $x=Get-WindowsOptionalFeature -Online -FeatureName $f; KV "Feature_$f" $x.State } catch { KV "Feature_$f" ('ERR '+$_.Exception.Message) } }
try { $bcd=(bcdedit /enum '{current}' 2>&1 | Out-String); ($bcd -split "`r?`n" | Where-Object {$_ -match 'hypervisorlaunchtype|nx|device|path|description'}) | ForEach-Object { 'BCD '+$_ } } catch { KV 'BcdError' $_.Exception.Message }
foreach($svc in 'vmms','vmcompute','hns','vmicvmsession','vmicheartbeat') { try { $s=Get-Service $svc -ErrorAction Stop; KV "Service_$svc" ($s.Status.ToString()+','+$s.StartType.ToString()) } catch { KV "Service_$svc" 'NotFound' } }
try { KV 'PendingReboot_CBS' (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') } catch {}
try { KV 'PendingReboot_WU' (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') } catch {}
Write-Output '---Recent setup/error events---'
$filters = @(
  @{LogName='Setup'; StartTime=(Get-Date).AddDays(-3)},
  @{LogName='System'; StartTime=(Get-Date).AddDays(-3)}
)
foreach($fl in $filters){
  try {
    Get-WinEvent -FilterHashtable $fl -MaxEvents 80 | Where-Object { $_.LevelDisplayName -in @('Error','Warning') -or $_.ProviderName -match 'Servicing|DISM|Hyper-V|Kernel-Boot|WindowsUpdate|CBS|Microsoft-Windows-Hyper-V' -or $_.Message -match 'Sandbox|DisposableClientVM|0x[0-9A-Fa-f]+' } | Select-Object -First 30 | ForEach-Object { Write-Output ('EVENT '+$_.TimeCreated.ToString('s')+' ['+$_.LogName+'] '+$_.ProviderName+' ID='+$_.Id+' '+($_.Message -replace "`r?`n",' ')) }
  } catch { Write-Output ('EVENTLOG_ERR '+$fl.LogName+' '+$_.Exception.Message) }
}
Write-Output '---DISM feature info---'
dism.exe /Online /Get-FeatureInfo /FeatureName:Containers-DisposableClientVM 2>&1 | Select-Object -First 80
