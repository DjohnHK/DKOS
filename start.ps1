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

# Solicitar ao usuario para escolher o disco a ser formatado
$diskSelecionado = $null
do {
    Clear-Host
    # Texto de solicitacao com formatacao e cor chamativa
    Write-Host "`nSelecione o numero do disco que deseja formatar!" -ForegroundColor White -BackgroundColor DarkBlue 
    Write-Host "Exemplo: 0 (para o primeiro disco) ou 1, 2, etc." -ForegroundColor Yellow

    $discos = (Get-Disk)

    # Mostrar discos disponíveis com o tamanho em GB
    $discos | ForEach-Object {
    $tamanhoGB = [math]::round($_.Size / 1GB, 2)  # Converte o tamanho para GB com 2 casas decimais
    Write-Host "`n$($_.Number): $($_.FriendlyName) - $tamanhoGB GB" -BackgroundColor DarkGreen  
}

    # Solicitar entrada do usuario
    $entrada = Read-Host "`nDigite o numero do disco (ex: 0)" | Out-String
    $entrada = $entrada.Trim()

    # Verificar se a entrada e um numero inteiro valido
    if (-not [int]::TryParse($entrada, [ref]$diskSelecionado)) {
        Write-Host "Entrada invalida! Por favor, digite um numero inteiro valido." -ForegroundColor Red
        Start-Sleep 5
        $diskSelecionado = $null
    } else {
        # Verificar se o numero do disco existe na lista
        $discoSelecionado = $discos | Where-Object { $_.Number -eq $diskSelecionado }
        if (-not $discoSelecionado) {
            Write-Host "Numero de disco invalido! Tente novamente." -ForegroundColor Red
            start-sleep 5
        }
    }
} while (-not $discoSelecionado)

Write-Host "`nVoce selecionou o disco $diskSelecionado. Procedendo com a formatacao..." -ForegroundColor Green

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

Clear-Host
Write-Host "Instalando Windows..." -ForegroundColor Green
dism /Apply-Image /ImageFile:$InstallEsd /Index:1 /ApplyDir:C:\

# ===============================================================
# Parte 6: Copiar o unattend.xml para automação da instalação
# ===============================================================
Clear-Host
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
Clear-Host
Write-Host "Configurando o boot..."
if ($IsUEFI) {
    bcdboot "C:\Windows" /s S: /f UEFI
} else {
    bcdboot "C:\Windows" /s C: /f BIOS
}

# ===============================================================
# Parte 9: Finalizar e reiniciar
# ===============================================================
Clear-Host

Write-Host "Instalacao concluida! Reiniciando..." -ForegroundColor Yellow

wpeutil reboot
