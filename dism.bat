@echo off 
 set pathvar="C:\Windows\System32\testebat.bat"
(
    echo @echo off
    echo echo Rodando sfc /scannow.
    echo sfc /scannow
    echo schtasks /delete /tn "sfc" /f 
    echo O computador vai ser reiniciado em breve 
    echo timeout 10
    echo shutdown /r /t 10
) > %pathvar%

Rem cria a tarefa para execucao do .bat
    schtasks /create /sc onstart /delay 0000:05 /tn "sfc" /tr "C:\Windows\System32\testebat.bat" /f /rl highest 

Rem Executa os comandos DISM 
    cls
    echo Etapa 1/3
    DISM /Online /Cleanup-Image /ScanHealth
    echo ---------------------------------------------------------------------------------------------------------------
    echo ---------------------------------------------------------------------------------------------------------------
    echo Etapa 2/3
    DISM /Online /Cleanup-Image /CheckHealth
    echo ---------------------------------------------------------------------------------------------------------------
    echo ---------------------------------------------------------------------------------------------------------------
    echo Etapa 3/3
    DISM /Online /Cleanup-Image /RestoreHealth

    echo A maquina vai ser reiniciada em breve e executara o sfc /scannow apos o login do usuario.
    timeout 10
    shutdown /r /t 10

Rem ---------------------------------------------------------------------------------------------------------------
Rem ---------------------------------------------------------------------------------------------------------------  