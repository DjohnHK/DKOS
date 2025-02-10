# Limpar variáveis, configurar powercfg e limpar a tela
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
Clear-Host
Write-Host "Carregando arquivos de automacao. Aguarde..." -ForegroundColor Yellow

# ===============================================================
# Parte 1: Procurar o drive que contém o install.esd
# ===============================================================
$drive = (Get-Volume).DriveLetter
foreach ($d in $drive) {
    $d += ':'
    Get-ChildItem "$d\install.esd" -ErrorAction SilentlyContinue | Out-Null
    if ($?) {
        $penDrive = $d
        break
    }
}

# Verificar se o arquivo install.esd foi encontrado
if (-not $penDrive) {
    Write-Host "Arquivo install.esd não encontrado!" -ForegroundColor Red
    exit
}

Write-Host "Arquivo install.esd encontrado em: $penDrive\install.esd"

# ===============================================================
# Parte 2: Definir variáveis para os arquivos e pastas
# ===============================================================
$InstallEsd   = "$penDrive\install.esd"
$UnattendPath = "$penDrive\autoconfig.xml"       # Seu unattend (autoconfig.xml)
$DestinoPastaSW = "C:\Temp\SW"                   # Destino para copiar a pasta SW

# ===============================================================
# Parte 3: Identificar o modo de boot (BIOS ou UEFI)
# ===============================================================
$FirmwareType = (Get-ComputerInfo).BiosFirmwareType
$IsUEFI = $FirmwareType -eq "UEFI"
Write-Host "Modo de boot: $FirmwareType"

# ===============================================================
# Parte 4: Mostrar discos e permitir seleção para formatação
# ===============================================================

Write-Host "Exibindo discos disponíveis..."
$discos = (Get-Disk)

# Mostrar discos disponíveis
$discos | ForEach-Object {
    Write-Host "$($_.Number): $($_.FriendlyName) - $($_.Size)"
}

# Solicitar ao usuário para escolher o disco a ser formatado
$diskSelecionado = Read-Host "Digite o número do disco que deseja formatar (ex: 0)"

# Verificar se o número do disco é válido
$discoSelecionado = $discos | Where-Object { $_.Number -eq [int]$diskSelecionado }
if (-not $discoSelecionado) {
    Write-Host "Número de disco inválido!" -ForegroundColor Red
    exit
}

Write-Host "Você selecionou o disco $diskSelecionado. Procedendo com a formatação..."

# Formatar o disco selecionado com diskpart
$DiskPartScript = if ($IsUEFI) {
    @"
select disk $diskSelecionado
clean
convert gpt
create partition efi size=100
format fs=fat32 quick
assign letter=S
create partition primary
format fs=ntfs quick
assign letter=C
exit
"@
} else {
    @"
select disk $diskSelecionado
clean
convert mbr
create partition primary
format fs=ntfs quick
assign letter=C
exit
"@
}
$DiskPartScript | diskpart

# Aguardar alguns segundos para que o volume C seja reconhecido
Start-Sleep -Seconds 5

Write-Host "Instalando Windows..."
dism /Apply-Image /ImageFile:$InstallEsd /Index:1 /ApplyDir:C:\

# ===============================================================
# Parte 6: Copiar o unattend.xml para automação da instalação
# ===============================================================
Write-Host "Copiando unattend.xml..."
New-Item -ItemType Directory -Path "C:\Windows\Panther" -Force | Out-Null
Copy-Item -Path $UnattendPath -Destination "C:\Windows\Panther\unattend.xml" -Force

# ===============================================================
# Parte 7: Copiar a pasta SW para C:\Temp
# ===============================================================
Write-Host "Copiando pasta SW para C:\Temp..."
New-Item -ItemType Directory -Path $DestinoPastaSW -Force | Out-Null
Copy-Item -Path "$penDrive\SW\*" -Destination $DestinoPastaSW -Recurse -Force

# ===============================================================
# Parte 8: Configurar o boot
# ===============================================================
Write-Host "Configurando o boot..."
if ($IsUEFI) {
    bcdboot "C:\Windows" /s S: /f UEFI
} else {
    bcdboot "C:\Windows" /s C: /f BIOS
}

# ===============================================================
# Parte 9: Finalizar e reiniciar
# ===============================================================
Write-Host "Instalacao concluida! Reiniciando..." -ForegroundColor Yellow

wpeutil reboot
