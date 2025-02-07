###############################################################################
# Script Otimizado de Configuração e Instalação – Desenvolvido por DK
###############################################################################

# Importa as classes necessárias e define o tratamento de erros
Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference = "SilentlyContinue"

# Limpa as variáveis existentes
Remove-Variable * -ErrorAction SilentlyContinue

# Configura o plano de energia
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

###############################################################################
# 1. Configurações de Telemetria, Delivery Optimization e SIUF
###############################################################################

# Para o serviço de Delivery Optimization
net stop dosvc

# Configura Delivery Optimization (modo de baixa utilização de banda)
If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 1

If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization")) {
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization" | Out-Null
}
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "SystemSettingsDownloadMode" -Type DWord -Value 3

# Desabilita o feedback do SIUF (Customer Experience Improvement Program)
If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules")) {
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0

# Desabilita sensores e serviços indesejados
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0

# Desabilita notificações de Background Access Applications
Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" | ForEach-Object {
    Set-ItemProperty -Path $_.PsPath -Name "Disabled" -Type DWord -Value 1
    Set-ItemProperty -Path $_.PsPath -Name "DisabledByUser" -Type DWord -Value 1
}

# Configura Telemetria (usando reg add para abranger todas as arquiteturas)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f

# Outras configurações de telemetria e compatibilidade
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v DontOfferThroughWUAU /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f

###############################################################################
# 2. Configurações de Tarefas Agendadas (Desabilitando tarefas indesejadas)
###############################################################################

schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\StartupAppTask" /Disable
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
schtasks /Change /TN "Microsoft\Windows\SystemRestore\SR" /Disable
schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /Disable
schtasks /Change /TN "MicrosoftEdgeUpdateTaskMachineCore" /Disable
schtasks /Change /TN "MicrosoftEdgeUpdateTaskMachineUA" /Disable

###############################################################################
# 3. Otimizações de Registro e Sistema
###############################################################################

# Diversas otimizações e ajustes de desempenho e segurança

reg add "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v start /T REG_DWORD /D 4 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /d 2 /t REG_DWORD /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v PreventDeviceMetadataFromNetwork /t REG_DWORD /d 1 /f

# Configurações do Desktop (respostas rápidas para travamentos e desempenho)
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d 1 /f
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d 1000 /f
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d 20 /f
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d 2000 /f
reg add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_SZ /d 1000 /f

# Ajusta o serviço Ndu
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v Start /t REG_DWORD /d 4 /f

# Desabilitar Game Bar, Game DVR e notificações relacionadas
reg add "HKCU\Software\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\GameBar" /v "GamePanelStartupTipIndexl" /t REG_DWORD /d 3 /f
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DSEBehavior" /t REG_DWORD /d 2 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f

# Configura o perfil multimídia para jogos
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 1 /f 
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f 
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f 
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d High /f 
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d High /f

# Ajusta valores do DXGKrnl (latência)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DXGKrnl" /v "MonitorLatencyTolerance" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DXGKrnl" /v "MonitorRefreshLatencyTolerance" /t REG_DWORD /d 0 /f

# Desabilita Windows Spotlight e conteúdo na nuvem (para HKCU)
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "ConfigureWindowsSpotlight" /t REG_DWORD /d 2 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "IncludeEnterpriseSpotlight" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightWindowsWelcomeExperience" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnActionCenter" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnSettings" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableThirdPartySuggestions" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d 1 /f

# Desabilita sugestões e notificações diversas
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f

# Desabilita o conteúdo e aplicativos pré-instalados
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RemediationRequired" /t REG_DWORD /d 0 /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions" /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps" /f

# Configura Prefetch e Superfetch
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 5 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 5 /f

# Desabilita "News and Interests, Meet Now, Task View e Search Bar" na barra de tarefas
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /d 2 /t REG_DWORD /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /d 1 /t REG_DWORD /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /d 0 /t REG_DWORD /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /d 0 /t REG_DWORD /f

###############################################################################
# 4. Configurações do Usuário e Sistema
###############################################################################

# Configuração do usuário local "DK": senha não definida e nunca expira
Set-LocalUser -Name "DK" -PasswordNeverExpires:$true

# BCD Edits – configurações diversas do boot
bcdedit /set disabledynamictick yes
bcdedit /deletevalue useplatformclock 
bcdedit /set description "DKOS 10 V3.0"
bcdedit /set hypervisorlaunchtype off
bcdedit /set tscsyncpolicy legacy
bcdedit /set useplatformclock false
bcdedit /set x2apicpolicy Enable
bcdedit /set configaccesspolicy Default
bcdedit /set MSI Default
bcdedit /set usephysicaldestination No
bcdedit /set usefirmwarepcisettings No
bcdedit /set isolatedcontext No
bcdedit /set allowedinmemorysettings 0x0

# Configura o uso de memória via fsutil
fsutil behavior set memoryusage 2

###############################################################################
# 5. Configurações de Desktop e Personalização
###############################################################################

# Define o wallpaper (certifique-se que o arquivo existe em C:\temp\sw\dk.jpg)
$Source = "C:\temp\sw"
$MyWallpaper = "$Source\dk.jpg"
$code = @'
using System.Runtime.InteropServices;
namespace Win32 {
    public class Wallpaper {
        [DllImport("user32.dll", CharSet=CharSet.Auto)]
        static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        public static void SetWallpaper(string thePath) {
            SystemParametersInfo(20, 0, thePath, 3);
        }
    }
}
'@
Add-Type $code
[Win32.Wallpaper]::SetWallpaper($MyWallpaper)

Clear-Host

###############################################################################
# 6. Instalação de Softwares
###############################################################################

Write-Host "Instalando softwares. Aguarde..." -ForegroundColor Yellow
$Source = "C:\temp\sw"

# [1/7] Instalação do 7-Zip
Write-Host "[1/7] Instalando 7-Zip:" -NoNewline
$Setup = Start-Process "$Source\Softwares\7z.exe" -ArgumentList "/S" -WindowStyle Hidden -PassThru -Wait
if ($Setup.ExitCode -eq 0 -or $Setup.ExitCode -eq 3010){
    Write-Host " Sucesso" -ForegroundColor Green
} else {
    Write-Host " Erro" -ForegroundColor Red
}
Remove-Variable Setup -ErrorAction SilentlyContinue

# [2/7] Instalação do Runtime dotNet
Write-Host "[2/7] Instalando Runtime dotNet:" -NoNewline
$Setup = Start-Process "$Source\Softwares\dotNet.exe" -ArgumentList "/NoSetupVersionCheck /q /norestart" -WindowStyle Hidden -PassThru -Wait
# Nota: mesmo em caso de erro, você optou por tratar como sucesso
Write-Host " Sucesso" -ForegroundColor Green
Remove-Variable Setup -ErrorAction SilentlyContinue

# [3/7] Instalação dos Runtimes C++
Write-Host "[3/7] Instalando Runtimes C++:" -NoNewline
$Setup = Start-Process "$Source\runtimes\install_all.bat" -WindowStyle Hidden -PassThru -Wait
if ($Setup.ExitCode -eq 0 -or $Setup.ExitCode -eq 3010){
    Write-Host " Sucesso" -ForegroundColor Green
} else {
    Write-Host " Erro" -ForegroundColor Red
}
Remove-Variable Setup -ErrorAction SilentlyContinue

# [4/7] Instalação do Java 32
Write-Host "[4/7] Instalando Java 32 bits:" -NoNewline
$Setup = Start-Process "$Source\runtimes\jre-8u441-windows-i586.exe" -ArgumentList '/s' -WindowStyle Hidden -PassThru -Wait
if ($Setup.ExitCode -eq 0 -or $Setup.ExitCode -eq 3010){
    Write-Host " Sucesso" -ForegroundColor Green
} else {
    Write-Host " Erro" -ForegroundColor Red
}
Remove-Variable Setup -ErrorAction SilentlyContinue

# [5/7] Instalação do Java 64
Write-Host "[5/7] Instalando Java 64 bits:" -NoNewline
$Setup = Start-Process "$Source\runtimes\jre-8u441-windows-x64.exe" -ArgumentList '/s' -WindowStyle Hidden -PassThru -Wait
if ($Setup.ExitCode -eq 0 -or $Setup.ExitCode -eq 3010){
    Write-Host " Sucesso" -ForegroundColor Green
} else {
    Write-Host " Erro" -ForegroundColor Red
}
Remove-Variable Setup -ErrorAction SilentlyContinue

# [6/7] Instalação dos General Runtimes
Write-Host "[6/7] Instalando Runtimes:" -NoNewline
$Setup = Start-Process "$Source\runtimes\General_Runtimes_Installer.exe" -ArgumentList '/verysilent /norestart' -WindowStyle Hidden -PassThru -Wait
if ($Setup.ExitCode -eq 0 -or $Setup.ExitCode -eq 3010){
    Write-Host " Sucesso" -ForegroundColor Green
} else {
    Write-Host " Erro" -ForegroundColor Red
}
Remove-Variable Setup -ErrorAction SilentlyContinue

# [7/7] Instalação dos VB6 Runtimes
Write-Host "[7/7] Instalando VB6 Runtimes:" -NoNewline
$Setup = Start-Process "$Source\runtimes\VB6.exe" -ArgumentList '/verysilent /norestart' -WindowStyle Hidden -PassThru
if ($Setup.ExitCode -eq 0 -or $Setup.ExitCode -eq 3010){
    Write-Host " Sucesso" -ForegroundColor Green
} else {
    Write-Host " Sucesso" -ForegroundColor Green
}
Remove-Variable Setup -ErrorAction SilentlyContinue

Clear-Host

###############################################################################
# 7. Exibição de Informações de Contato
###############################################################################

$publicDesktop = [System.IO.Path]::Combine($env:PUBLIC, "Desktop")
$htmlFile = "$publicDesktop\LEIA-ME.html"

$htmlContent = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Automacao DKOS</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin: 50px;
        }
        h1 {
            color: blue;
        }
        .contact {
            margin-top: 20px;
            font-size: 18px;
        }
        .email {
            color: gray;
        }
        .whatsapp {
            color: green;
        }
        .facebook {
            color: blue;
        }
        .instagram {
            color: red;
        }
        .pix {
            color: rgb(192, 18, 207);
        }
        .underline {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <h1>AUTOMACAO DESENVOLVIDA POR: <span class="underline">Djohn H. Klitzke</span></h1>
    <div class="contact">
        <p><strong>Contato:</strong></p>
        <p class="email">E-mail: <a href="mailto:djohnhermann@gmail.com">djohnhermann@gmail.com</a></p>
        <p class="whatsapp">WhatsApp: <a href="https://wa.me/5547991516592" target="_blank">(47) 99151-6592</a></p>
        <p class="facebook">Facebook: <a href="https://www.facebook.com/djohn.hermann" target="_blank">Djohn Klitzke</a></p>
        <p class="instagram">Instagram: <a href="https://www.instagram.com/djohnklitzke" target="_blank">djohn.klitzke</a></p>
        <p class="pix">Pix: djohnhermann@gmail.com</p>
    </div>
</body>
</html>
"@

$htmlContent | Set-Content -Path $htmlFile -Encoding UTF8

Start-Sleep -Seconds 10
