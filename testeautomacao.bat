@ECHO OFF

    ECHO _________________________________________________________________________________________________
    ECHO #											                                                                                                   
    ECHO #	Utilitarios - Certa Solucoes 								     
    ECHO #												    
    ECHO #											             
    ECHO # 	!!!Antes de dar prosseguimento, feche todos os programas abertos atualmente na maquina       
    ECHO #	do usuario!!!                                                                                
    ECHO #	!!!Certifique-se de estar rodando esse arquivo em modo Administrador!!!											     
    ECHO #											             
    ECHO #	Podemos dar prosseguimento?                                                                  
    ECHO #                                                                                                
    ECHO #_______________________________________________________________________________________________
    

PAUSE

cls

:menu
    ECHO _________________________________________________________________________________________________
    ECHO #                                                                 
    ECHO #      Escolha uma categoria:
    ECHO #      1. Ativacoes 
    ECHO #      2. Rotina DISM e Scannow    
    ECHO # 
    ECHO #                                                                     
    ECHO #
    ECHO #											             
    ECHO #                                                              
    ECHO #                                                                                                
    ECHO #_______________________________________________________________________________________________

    choice /c:12 /n /m "Digite o numero da opcao que deseja: "
    set erl=%errorlevel%
    if %erl%==1 goto menu-ativacao
    if %erl%==2 goto dism-scannow 


Rem ---------------------------------------------------------------------------------------------------------------
Rem ---------------------------------------------------------------------------------------------------------------
:menu-ativacao
cls
    ECHO _________________________________________________________________________________________________
    ECHO #											                                                                                                   
    ECHO #	 	Escolha uma opcao:							     
    ECHO #      1. Ativacao Office (Ohook)					    
    ECHO #      2. Ativacao Windows (HWID)									             
    ECHO #      3. Ativacao Office + Windows    
    ECHO #	                                                                             
    ECHO #												     
    ECHO #											             
    ECHO #	                                                              
    ECHO #                                                                                                
    ECHO #_______________________________________________________________________________________________
    ECHO.

Rem Menu para selecionar a ativacao desejadav
    choice /c:123 /n /m "Digite o numero da opcao que deseja: "
    set erl=%errorlevel%
    if %erl%==1 goto office-ohook
    if %erl%==2 goto windows-hwid
    if %erl%==3 goto office-windows

Rem Ativacao office utilizando Ohook 
:office-ohook
    echo Ativando...
    powershell -Command "& ([ScriptBlock]::Create((irm https://get.activated.win))) /Ohook "
    echo Processo de ativacao do Office concluido!
    goto finalizacao-ativacao

Rem Ativacao Windows utilizando  HWID
:windows-hwid
    echo Ativando...
    powershell -Command "& ([ScriptBlock]::Create((irm https://get.activated.win))) /HWID "
    echo Processo de ativacao do Windows utilizando HWID concluido
    goto finalizacao-ativacao

Rem Ativacao Office + Windows 
:office-windows
    echo Ativando Windows....
    powershell -Command "& ([ScriptBlock]::Create((irm https://get.activated.win))) /HWID "
    echo Processo de ativacao do Windows concluido
    echo Ativando Office....
    powershell -Command "& ([ScriptBlock]::Create((irm https://get.activated.win))) /Ohook "
    echo Processo de ativacao do Office concluido!
    goto finalizacao-ativacao

:finalizacao-ativacao
    cls
    ECHO _________________________________________________________________________________________________
    ECHO #											                                                                                                   
    ECHO #	Ativacao realizada com sucesso! 
    ECHO # 								     
    ECHO #	Escolha uma opcao:											    
    ECHO #                      1. Menu						             
    ECHO #                      2. Exit
    ECHO #	                                                                             
    ECHO #												     
    ECHO #											             
    ECHO #	                                                                 
    ECHO #                                                                                                
    ECHO #_______________________________________________________________________________________________

    choice /c:12 /n /m "Digite o numero da opcao que deseja: "
    set erl=%errorlevel%
    if %erl%==1 goto menu
    if %erl%==2 goto exit

Rem ---------------------------------------------------------------------------------------------------------------
Rem ---------------------------------------------------------------------------------------------------------------

:dism-scannow   

Rem Esse bloco cria o .bat que vai rodar o scannow apos a reinicializacao, e tambem vai excluir a tarefa criada.
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
    schtasks /create /sc once /st 00:00 /tn "sfc" /tr "C:\Windows\System32\testebat.bat" /f /rl highest /delay 0000:10 /it

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
    
