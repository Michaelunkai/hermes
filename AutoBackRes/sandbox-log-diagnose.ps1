[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new()
chcp 65001 > $null
$ErrorActionPreference='Continue'
$patterns = 'Containers-DisposableClientVM|DisposableClientVM|Sandbox|800f0922|0x800f0922|CBS_E_INSTALLERS_FAILED|Failed execution|Error|failure'
Write-Output '--- CBS tail matching ---'
$cbsPaths = @('C:\Windows\Logs\CBS\CBS.log') + (Get-ChildItem C:\Windows\Logs\CBS\CbsPersist*.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3 -ExpandProperty FullName)
foreach($p in $cbsPaths){
  if(Test-Path $p){
    Write-Output ("### $p")
    try { Select-String -Path $p -Pattern $patterns -CaseSensitive:$false -ErrorAction Continue | Select-Object -Last 120 | ForEach-Object { $_.Line } } catch { Write-Output ('READ_ERR '+$_.Exception.Message) }
  }
}
Write-Output '--- DISM log matching ---'
$d='C:\Windows\Logs\DISM\dism.log'
if(Test-Path $d){ Select-String -Path $d -Pattern $patterns -CaseSensitive:$false -ErrorAction Continue | Select-Object -Last 120 | ForEach-Object { $_.Line } }
Write-Output '--- Packages matching Sandbox/Containers OptionalFeatures ---'
Get-WindowsPackage -Online | Where-Object { $_.PackageName -match 'Containers|Sandbox|HyperV|OptionalFeatures' } | Sort-Object PackageName | ForEach-Object { Write-Output ($_.PackageName+' | '+$_.PackageState+' | '+$_.ReleaseType) }
