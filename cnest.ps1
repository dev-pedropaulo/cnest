# Verifica se o script está sendo executado com privilégios de administrador
function VerificarAdmin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (VerificarAdmin)) {
    # Se não estiver executando como administrador, reinicia o script com privilégios elevados
    $arguments = "& '" + $myinvocation.MyCommand.Definition + "'"
    Start-Process powershell -ArgumentList $arguments -Verb RunAs
    exit
}

# Se estiver executando como administrador, continue com o resto do script


# Definições iniciais
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$programName64 = 'cnest.msi'
$programName32 = 'cnest32.msi'
$path64 = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes('C:\Program Files\Certa Soluções Informática\CNest'))
$path32 = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes('C:\Program Files (x86)\Certa Soluções Informática\CNest'))
$localPath = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes('C:\Suporte Certa\SUPORTE REMOTO\inventory'))
$serverURL = "https://cnest.certasolucoes.com"
$downloadURL64 = "https://www.certasolucoes.com/downloads/inventory/cnest.msi"
$downloadURL32 = "https://www.certasolucoes.com/downloads/inventory/cnest32.msi"

# Defina a TAG aqui, se desejar uma TAG padrão. Caso contrário, deixe vazio.
$tag = "RBAMAQ-243293"

# Prepara o ambiente
if (-not (Test-Path -Path $localPath)) {
    New-Item -ItemType Directory -Path $localPath -Force | Out-Null
}

# Define variáveis baseadas na arquitetura
if ([Environment]::Is64BitOperatingSystem) {
    $programName = $programName64
    $installPath = $path64
    $downloadURL = $downloadURL64
} else {
    $programName = $programName32
    $installPath = $path32
    $downloadURL = $downloadURL32
}

$localFilePath = Join-Path -Path $localPath -ChildPath $programName

# Pergunta a TAG ao usuário se não estiver definida
if (-not $tag) {
    $tag = Read-Host -Prompt "Por favor, digite a TAG para o agente CNest"
}

# Verifica se o sistema atende às condições prévias para instalação
function CondiçõesInstalaçãoSatisfeitas {
    $pastaCNest = Join-Path -Path $installPath -ChildPath "CNest"
    $arquivosNecessarios = @("ConectaCertaAgenteRemoto.exe", "ConectaCertaAgenteRemoto.msh", "ConectaCertaAgenteRemoto.db")

    if (-not (Test-Path -Path $pastaCNest) -or -not ($arquivosNecessarios | ForEach-Object { Test-Path (Join-Path -Path $pastaCNest -ChildPath $_) })) {
        return $false
    }

    $servico = Get-Service -Name "conectacertaremoto_agent" -ErrorAction SilentlyContinue
    if (-not $servico -or $servico.Status -ne 'Running') {
        return $false
    }

    return $true
}

#Configura a politica para instalação
Write-Host "[+] Configuring HKEY_LOCAL_MACHINE registry`n"

# Verifica se a chave já existe
if (Test-Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer") {
    Write-Host "A chave já existe. Atualizando o valor..."
    # Atualiza o valor da propriedade
    Set-ItemProperty -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -Value 0x00000001 -force
} else {
    Write-Host "A chave não existe. Criando a chave e definindo o valor..."
    # Cria a chave e define o valor
    New-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer"
    New-ItemProperty -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -PropertyType DWORD -Value 0x00000001
}

Write-Host "`n[+] Configuring HKEY_CURRENT_USER registry`n"

# Verifica se a chave já existe
if (Test-Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer") {
    Write-Host "A chave já existe. Atualizando o valor..."
    # Atualiza o valor da propriedade
    Set-ItemProperty -Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -Value 0x00000001
} else {
    Write-Host "A chave não existe. Criando a chave e definindo o valor..."
    # Cria a chave e define o valor
    New-Item -Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer"
    New-ItemProperty -Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -PropertyType DWORD -Value 0x00000001
}


# Baixa o instalador do CNest
function BaixarInstalador {
    param ($url, $destino)

    Write-Host "Baixando $url para $destino"
    Invoke-WebRequest -Uri $url -OutFile $destino -UseBasicParsing
}

# Verifica a versão do MSI local e remoto
function VerificarVersao {
    param ($localFilePath, $downloadURL)

    if (Test-Path -Path $localFilePath) {
        $localVersion = (Get-ItemProperty -Path $localFilePath).VersionInfo.ProductVersion
        $remoteFile = Join-Path -Path $env:TEMP -ChildPath $programName
        BaixarInstalador -url $downloadURL -destino $remoteFile
        $remoteVersion = (Get-ItemProperty -Path $remoteFile).VersionInfo.ProductVersion
        Remove-Item -Path $remoteFile -Force

        if ($localVersion -eq $remoteVersion) {
            Write-Host "A versão local e a versão remota são iguais ($localVersion)."
            return $false
        } else {
            Write-Host "A versão local ($localVersion) e a versão remota ($remoteVersion) são diferentes. Substituindo..."
            return $true
        }
    } else {
        Write-Host "O arquivo local não existe. Realizando download..."
        return $true
    }
}

# Registra informações detalhadas do processo de instalação
function GerarLogDetalhado {
    $logFolder = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes('C:\Suporte Certa\Logs'))
    $logPath = Join-Path -Path $logFolder -ChildPath ("Log-$env:COMPUTERNAME.txt")
    
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
    }

    # Obtém o nome do usuário logado (exceto serviços e sistema)
    $loggedOnUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName

    $info = @"
---------------------------------
Nome do Computador: $env:COMPUTERNAME
Domínio: $((Get-WmiObject Win32_ComputerSystem).Domain)
Endereço de IP: $((Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.InterfaceAlias -notlike "*Virtual*" } | Select-Object -First 1).IPAddress)
IP Internet: $((Invoke-RestMethod http://ipinfo.io/json -UseBasicParsing).ip)
Usuário: $loggedOnUser
Hora e Data da Instalação: $(Get-Date -Format "dd-MM-yyyy HH:mm:ss")
Executável Utilizado: $global:programName
"@

    Add-Content -Path $logPath -Value $info
}

# Tenta instalar o programa
function TentaInstalar {
    param ([String]$filePath)

    try {
        $arguments = "/i `"$filePath`" /quiet INSTALLDIR=`"$installPath`" RUNNOW=1 EXECMODE=1 SCAN_HOMEDIRS=1 SCAN_PROFILES=1 SERVER=`"$serverURL`" TAG=`"$tag`""
        Write-Host "Executando: msiexec.exe $arguments"
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
        if ($process.ExitCode -eq 0) {
            GerarLogDetalhado
            Write-Host "Instalação concluída com sucesso para $filePath."
        } else {
            Write-Host "Falha na instalação com o código de saída: $($process.ExitCode)."
        }
    } catch {
        Write-Host "Erro na tentativa de instalar o programa: $_"
    }
}

# Verifica a comunicação com o servidor
function VerificarComunicacaoServidor {
    try {
        $response = Invoke-WebRequest -Uri $serverURL -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "Comunicação com o servidor bem-sucedida."
            return $true
        } else {
            Write-Host "Falha na comunicação com o servidor. Código de status: $($response.StatusCode)"
            return $false
        }
    } catch {
        Write-Host "Erro ao tentar se comunicar com o servidor: $_"
        return $false
    }
}

# Executa o script
if (-not (Test-Path -Path $installPath) -or -not (CondiçõesInstalaçãoSatisfeitas)) {
    if (VerificarVersao -localFilePath $localFilePath -downloadURL $downloadURL) {
        BaixarInstalador -url $downloadURL -destino $localFilePath
    }
    TentaInstalar -filePath $localFilePath

    if (-not (CondiçõesInstalaçãoSatisfeitas)) {
        Write-Host "Condições ainda não satisfeitas após a primeira tentativa. Realizando nova tentativa."
        TentaInstalar -filePath $localFilePath
    }

    if (VerificarComunicacaoServidor) {
        Write-Host "Instalação e comunicação com o servidor bem-sucedidas."
    } else {
        Write-Host "Instalação concluída, mas a comunicação com o servidor falhou."
    }
} else {
    Write-Host "As condições prévias indicam que a instalação já foi realizada. Instalação não é necessária."
    if (VerificarComunicacaoServidor) {
        Write-Host "Comunicação com o servidor bem-sucedida."
    } else {
        Write-Host "Comunicação com o servidor falhou."
    }
}

Write-Host "[+] Configuring HKEY_LOCAL_MACHINE registry to 0x0`n"

# Verifica se a chave já existe
if (Test-Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer") {
    Write-Host "A chave existe. Alterando o valor para 0x0..."
    # Atualiza o valor da propriedade
    Set-ItemProperty -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -Value 0x00000000
} else {
    Write-Host "A chave não existe. Criando a chave e definindo o valor para 0x0..."
    # Cria a chave e define o valor
    New-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer"
    New-ItemProperty -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -PropertyType DWORD -Value 0x00000000
}

Write-Host "`n[+] Configuring HKEY_CURRENT_USER registry to 0x0`n"

# Verifica se a chave já existe
if (Test-Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer") {
    Write-Host "A chave existe. Alterando o valor para 0x0..."
    # Atualiza o valor da propriedade
    Set-ItemProperty -Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -Value 0x00000000
} else {
    Write-Host "A chave não existe. Criando a chave e definindo o valor para 0x0..."
    # Cria a chave e define o valor
    New-Item -Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer"
    New-ItemProperty -Path "Registry::\HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -PropertyType DWORD -Value 0x00000000
}


Write-Host "Operação concluída. Verifique o log para mais detalhes."
