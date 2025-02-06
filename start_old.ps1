Remove-Variable * -ErrorAction SilentlyContinue
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
Clear-Host
""
Write-Host Carregando arquivos de automação. Aguarde... -f Yellow

$drive = (get-volume).DriveLetter
foreach ($d in $drive){
$d += ':'
Get-ChildItem "$d\Windows\sources\install.esd" -ErrorAction SilentlyContinue | Out-Null
if ($?) {
$penDrive = $d
break
    }
}

Start-Process $d\Windows\setup.exe -ArgumentList "/unattend:autoconfig.xml"

Start-Sleep 100

$drive = (get-volume).DriveLetter
foreach ($d in $drive){
$d += ':'
$winPath = Get-ChildItem $d | Where-Object {$_.name -like "*~BT*"}
if ($null -ne $winPath) {
$winPath = $d
break
    }
}

Copy-Item $penDrive\Windows\sw -Recurse -Destination $winPath\Temp\sw
Copy-Item script.ps1 $winPath\Temp\sw
Copy-Item remove-onedrive.ps1 $winPath\Temp\sw\Scripts
Copy-Item cleandisk.ps1 $winPath\Temp\sw\Scripts
Copy-Item temp-delete.ps1 $winPath\Temp\sw\Scripts

Clear-Host
""
Write-Host Reiniciando... -f Yellow
