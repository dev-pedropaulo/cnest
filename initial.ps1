# Define o URL do arquivo e o caminho temporário para salvar
$url = "https://raw.githubusercontent.com/dev-pedropaulo/cnest/main/testeautomacao.bat"
$tempPath = "$env:TEMP\testeautomacao.bat"

# Baixa o arquivo e salva no caminho temporário
Invoke-WebRequest -Uri $url -OutFile $tempPath

# Executa o arquivo .bat baixado
& $tempPath

# Remove o arquivo após a execução
Remove-Item $tempPath
