<#
.SYNOPSIS
    Ferramenta de Diagnostico e Suporte Tecnico para Windows
.DESCRIPTION
    Script com menu interativo para tarefas de manutencao e diagnostico do sistema
.AUTHOR
    Tecnico de Suporte
.VERSION
    3.0 - Versao refatorada e intuitiva
.NOTES
    Execute como administrador para todas as funcionalidades
#>

# ============================================
# BIBLIOTECA DE FUNCOES AUXILIARES
# ============================================

# Variavel global com nome do script
$NOME_FERRAMENTA = "Ferramenta de Suporte Tecnico v3.0"

# Funcao para exibir mensagens coloridas na tela
# Status pode ser: INFO, SUCESSO, ERRO, AVISO
function Escrever-Mensagem {
    param(
        [string]$Texto,
        [string]$Tipo = "INFO"
    )
    
    switch ($Tipo) {
        "SUCESSO"   { Write-Host "[OK] $Texto" -ForegroundColor Green }
        "ERRO"      { Write-Host "[ERRO] $Texto" -ForegroundColor Red }
        "AVISO"     { Write-Host "[AVISO] $Texto" -ForegroundColor Yellow }
        "INFO"      { Write-Host "[INFO] $Texto" -ForegroundColor Cyan }
        default     { Write-Host "  $Texto" }
    }
}

# Funcao para pausar a tela e aguardar o usuario ler
function Aguardar-Enter {
    Write-Host ""
    Read-Host "Pressione Enter para continuar"
    Mostrar-Menu
}

# ============================================
# FUNCOES DE SISTEMA (LIMPEZA E INFORMACOES)
# ============================================

# 1. Limpar arquivos temporarios do sistema
function Limpar-ArquivosTemporarios {
    Escrever-Mensagem "Iniciando limpeza de arquivos temporarios" "INFO"
    
    # Lista de pastas temporarias do Windows
    $pastasTemporarias = @(
        "$env:TEMP\*",                    # Temp do usuario atual
        "$env:WINDIR\Temp\*",             # Temp do sistema
        "$env:WINDIR\Prefetch\*"          # Prefetch (acelera programas)
    )
    
    foreach ($pasta in $pastasTemporarias) {
        Remove-Item -Path $pasta -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Limpo: $pasta" -ForegroundColor Gray
    }
    
    Escrever-Mensagem "Limpeza de temporarios concluida" "SUCESSO"
}

# 2. Limpar cache de DNS (resolve problemas de resolucao de nomes)
function Limpar-CacheDNS {
    Escrever-Mensagem "Limpando cache DNS" "INFO"
    ipconfig /flushdns | Out-String | Write-Host
    Escrever-Mensagem "Cache DNS limpo com sucesso" "SUCESSO"
}

# 3. Exibir configuracoes de rede (IP, DNS, Gateway)
function Exibir-ConfiguracaoIP {
    Escrever-Mensagem "Exibindo configuracoes de IP" "INFO"
    ipconfig /all | Write-Host -ForegroundColor Green
    Escrever-Mensagem "Configuracoes exibidas" "SUCESSO"
}

# 4. Exibir lista de processos em execucao
function Exibir-Processos {
    Escrever-Mensagem "Listando processos em execucao" "INFO"
    Get-Process | Format-Table -Property Id, Nome=ProcessName, CPU, Memoria=WorkingSet64 -AutoSize | Out-String | Write-Host
    Escrever-Mensagem "Processos listados" "SUCESSO"
}

# 5. Exibir usuarios logados no sistema
function Exibir-UsuariosLogados {
    Escrever-Mensagem "Verificando usuarios logados" "INFO"
    quser | Write-Host -ForegroundColor Green
    Escrever-Mensagem "Usuarios exibidos" "SUCESSO"
}

# 6. Exibir portas de rede abertas (aguardando conexoes)
function Exibir-PortasAbertas {
    Escrever-Mensagem "Verificando portas abertas" "INFO"
    netstat -an | Select-String "LISTENING" | Write-Host -ForegroundColor Green
    Escrever-Mensagem "Portas abertas exibidas" "SUCESSO"
}

# ============================================
# FUNCOES DE REDE
# ============================================

# 7. Testar ping com opcoes interativas
function Testar-Conexao {
    param(
        [string]$Destino = "",
        [int]$Quantidade = 4
    )
    
    # Se nenhum destino foi informado, mostra menu interativo
    if ($Destino -eq "") {
        
        # Detecta informacoes da rede atual
        $gateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1
        $ipsLocais = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
            $_.InterfaceAlias -notlike "*Loopback*" -and $_.PrefixOrigin -ne "WellKnown" 
        }).IPAddress
        
        # Limpa tela e mostra menu
        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "         TESTE DE CONEXAO" -ForegroundColor White
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        # Mostra informacoes atuais da rede
        Write-Host "[INFORMACOES DA REDE ATUAL]" -ForegroundColor Yellow
        if ($gateway) {
            Write-Host "  Gateway padrao: $($gateway.NextHop)" -ForegroundColor Gray
        } else {
            Write-Host "  Gateway padrao: NAO DETECTADO" -ForegroundColor Red
        }
        
        if ($ipsLocais) {
            Write-Host "  IPs locais: $($ipsLocais -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "  IPs locais: NAO DETECTADO" -ForegroundColor Red
        }
        
        # Opcoes de teste
        Write-Host "`n[OPCOES DE TESTE]" -ForegroundColor Yellow
        Write-Host " 1. Internet (Google DNS - 8.8.8.8)"
        Write-Host " 2. Rede local (Gateway: $($gateway.NextHop))"
        Write-Host " 3. Placa de rede (Loopback - 127.0.0.1)"
        Write-Host " 4. Digitar um IP manualmente"
        Write-Host " 5. Pingar o proprio IP desta maquina"
        Write-Host " 6. Diagnostico completo (testa tudo)"
        Write-Host " 7. Voltar ao menu principal"
        
        $escolha = Read-Host "`nEscolha (1-7)"
        
        switch ($escolha) {
            "1" { $Destino = "8.8.8.8" }
            "2" { 
                if ($gateway) { 
                    $Destino = $gateway.NextHop 
                    Write-Host "`nTestando gateway: $Destino" -ForegroundColor Cyan
                } else {
                    Escrever-Mensagem "Gateway nao detectado!" "ERRO"
                    Aguardar-Enter
                    return
                }
            }
            "3" { $Destino = "127.0.0.1" }
            "4" { 
                $Destino = Read-Host "Digite o IP ou hostname"
                if ([string]::IsNullOrWhiteSpace($Destino)) { 
                    Escrever-Mensagem "IP invalido!" "ERRO"
                    return
                }
            }
            "5" { 
                if ($ipsLocais) {
                    $Destino = $ipsLocais[0]
                    Write-Host "`nTestando IP local: $Destino" -ForegroundColor Cyan
                } else {
                    Escrever-Mensagem "Nao foi possivel detectar o IP local!" "ERRO"
                    Aguardar-Enter
                    return
                }
            }
            "6" { 
                # Chama funcao de diagnostico completo de rede
                Diagnostico-CompletoRede
                return
            }
            "7" { return }
            default { 
                Escrever-Mensagem "Opcao invalida!" "ERRO"
                return
            }
        }
    }
    
    # Executa o ping
    Escrever-Mensagem "Testando ping para $Destino" "INFO"
    Write-Host "`n>>> Testando conexao com $Destino <<<" -ForegroundColor Cyan
    
    $resultadoPing = Test-Connection -ComputerName $Destino -Count $Quantidade -ErrorAction SilentlyContinue
    
    if ($resultadoPing) {
        $pacotesRecebidos = ($resultadoPing | Where-Object { $_.StatusCode -eq 0 }).Count
        $tempoMedio = [math]::Round(($resultadoPing | Where-Object { $_.StatusCode -eq 0 } | Measure-Object -Property ResponseTime -Average).Average, 2)
        
        Write-Host "  Pacotes recebidos: $pacotesRecebidos de $Quantidade" -ForegroundColor Green
        if ($pacotesRecebidos -gt 0 -and $tempoMedio) {
            Write-Host "  Tempo medio de resposta: ${tempoMedio}ms" -ForegroundColor Gray
        }
        Escrever-Mensagem "Ping para $Destino realizado com sucesso" "SUCESSO"
    } else {
        Write-Host "  Falha no ping para $Destino" -ForegroundColor Red
        Escrever-Mensagem "Ping para $Destino falhou" "ERRO"
        
        # Dicas baseadas no tipo de destino
        if ($Destino -eq "8.8.8.8") {
            Write-Host "`n  [DICA] Verifique sua conexao com a internet." -ForegroundColor Yellow
            Write-Host "  [DICA] Tente desligar/ligar o adaptador de rede." -ForegroundColor Yellow
        } elseif ($Destino -eq "127.0.0.1") {
            Write-Host "`n  [DICA] Falha no loopback. Pode ser problema no driver de rede." -ForegroundColor Yellow
            Write-Host "  [DICA] Execute o comando: netsh int ip reset" -ForegroundColor Yellow
        } elseif ($gateway -and $Destino -eq $gateway.NextHop) {
            Write-Host "`n  [DICA] Falha no gateway. Verifique o cabo de rede/Wi-Fi." -ForegroundColor Yellow
            Write-Host "  [DICA] Tente reiniciar o roteador ou modem." -ForegroundColor Yellow
        } else {
            Write-Host "`n  [DICA] Verifique se o destino esta ligado e acessivel." -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# 8. Reset completo da pilha de rede
function Resetar-Rede {
    Escrever-Mensagem "Iniciando reset completo de rede" "AVISO"
    Write-Host "Este processo vai reiniciar toda a configuracao de rede do Windows" -ForegroundColor Yellow
    
    Write-Host "Liberando IP..." -ForegroundColor Yellow
    ipconfig /release
    
    Write-Host "Renovando IP..." -ForegroundColor Yellow
    ipconfig /renew
    
    Write-Host "Limpando cache DNS..." -ForegroundColor Yellow
    ipconfig /flushdns
    
    Write-Host "Resetando Winsock (pilha de rede)..." -ForegroundColor Yellow
    netsh winsock reset
    
    Write-Host "Resetando TCP/IP..." -ForegroundColor Yellow
    netsh int ip reset
    
    Escrever-Mensagem "Reset de rede concluido" "SUCESSO"
    Write-Host "`n[IMPORTANTE] Reinicie o computador para aplicar todas as alteracoes." -ForegroundColor Green
}

# Funcao auxiliar: Diagnostico completo de rede
function Diagnostico-CompletoRede {
    $gateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1
    
    Write-Host "`n========== DIAGNOSTICO COMPLETO DE REDE ==========" -ForegroundColor Magenta
    
    # Teste 1: Loopback (placa de rede)
    Write-Host "`n[1/4] Testando placa de rede (127.0.0.1)..." -ForegroundColor Yellow
    $teste1 = Test-Connection -ComputerName "127.0.0.1" -Count 2 -ErrorAction SilentlyContinue
    if ($teste1) { 
        Write-Host "  [OK] Placa de rede funcionando" -ForegroundColor Green 
    } else { 
        Write-Host "  [FALHA] Problema na placa de rede!" -ForegroundColor Red 
    }
    
    # Teste 2: Gateway
    Write-Host "`n[2/4] Testando gateway..." -ForegroundColor Yellow
    if ($gateway) {
        $teste2 = Test-Connection -ComputerName $gateway.NextHop -Count 2 -ErrorAction SilentlyContinue
        if ($teste2) { 
            Write-Host "  [OK] Gateway acessivel: $($gateway.NextHop)" -ForegroundColor Green 
        } else { 
            Write-Host "  [FALHA] Gateway inacessivel: $($gateway.NextHop)" -ForegroundColor Red 
        }
    } else { 
        Write-Host "  [ERRO] Nenhum gateway detectado!" -ForegroundColor Red 
    }
    
    # Teste 3: Internet (DNS Google)
    Write-Host "`n[3/4] Testando conexao com internet (8.8.8.8)..." -ForegroundColor Yellow
    $teste3 = Test-Connection -ComputerName "8.8.8.8" -Count 2 -ErrorAction SilentlyContinue
    if ($teste3) { 
        Write-Host "  [OK] Internet funcionando" -ForegroundColor Green 
    } else { 
        Write-Host "  [FALHA] Sem conexao com internet!" -ForegroundColor Red 
    }
    
    # Teste 4: Resolucao DNS
    Write-Host "`n[4/4] Testando resolucao de DNS (google.com)..." -ForegroundColor Yellow
    try {
        $testeDns = Resolve-DnsName -Name "google.com" -ErrorAction Stop
        Write-Host "  [OK] DNS esta resolvendo nomes" -ForegroundColor Green
        Write-Host "       IPs encontrados: $($testeDns.IPAddress -join ', ')" -ForegroundColor Gray
    } catch {
        Write-Host "  [FALHA] Problema na resolucao de DNS!" -ForegroundColor Red
        Write-Host "  [DICA] Tente usar DNS alternativo como 8.8.8.8" -ForegroundColor Yellow
    }
    
    Write-Host "`n========================================" -ForegroundColor Magenta
    Read-Host "`nPressione Enter para continuar"
}

# ============================================
# FUNCOES DE DIAGNOSTICO E REPARO DO SISTEMA
# ============================================

# 9. Executar SFC - Verificador de arquivos do sistema
function Executar-SFC {
    Escrever-Mensagem "Executando SFC (System File Checker)" "INFO"
    Write-Host "Este processo verifica e repara arquivos corrompidos do Windows" -ForegroundColor Gray
    Write-Host "Pode levar varios minutos. Aguarde...`n" -ForegroundColor Yellow
    
    sfc /scannow | Out-String | Write-Host
    
    Escrever-Mensagem "Verificacao SFC finalizada" "SUCESSO"
}

# 10. Executar CHKDSK - Verificador de disco
function Executar-CHKDSK {
    Escrever-Mensagem "Executando CHKDSK (verificador de disco)" "INFO"
    Write-Host "Verificando integridade do disco em modo somente leitura" -ForegroundColor Gray
    Write-Host "Para reparos completos, use o comando: chkdsk C: /f /r`n" -ForegroundColor Yellow
    
    chkdsk | Out-String | Write-Host
    
    Escrever-Mensagem "Verificacao CHKDSK finalizada" "SUCESSO"
}

# 11. Executar DISM - Reparo da imagem do Windows
function Executar-DISM {
    Escrever-Mensagem "Executando DISM (Deployment Imaging Service)" "INFO"
    Write-Host "Este processo repara a imagem do Windows" -ForegroundColor Gray
    Write-Host "Pode levar varios minutos. Aguarde...`n" -ForegroundColor Yellow
    
    dism /online /cleanup-image /restorehealth | Out-String | Write-Host
    
    Escrever-Mensagem "Reparo DISM finalizado" "SUCESSO"
}

# 12. Resetar servico do Windows Update
function Resetar-WindowsUpdate {
    Escrever-Mensagem "Resetando Windows Update" "AVISO"
    Write-Host "Este processo vai reiniciar o servico de atualizacoes do Windows" -ForegroundColor Yellow
    
    Write-Host "Parando servicos relacionados..." -ForegroundColor Yellow
    Stop-Service -Name wuauserv, bits, cryptsvc -Force -ErrorAction SilentlyContinue
    
    Write-Host "Limpando cache de atualizacoes..." -ForegroundColor Yellow
    Remove-Item -Path "$env:WINDIR\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Reiniciando servicos..." -ForegroundColor Yellow
    Start-Service -Name wuauserv, bits, cryptsvc -ErrorAction SilentlyContinue
    
    Escrever-Mensagem "Windows Update resetado com sucesso" "SUCESSO"
    Write-Host "Agora voce pode verificar por atualizacoes novamente." -ForegroundColor Green
}

# ============================================
# FUNCOES EXTRAS (AUTOMATICAS)
# ============================================

# 13. Diagnostico completo do sistema
function Diagnostico-Completo {
    Escrever-Mensagem "INICIANDO DIAGNOSTICO COMPLETO DO SISTEMA" "INFO"
    Write-Host "`n========== DIAGNOSTICO COMPLETO ==========" -ForegroundColor Magenta
    
    Write-Host "`n1. Configuracoes de rede:" -ForegroundColor Cyan
    Exibir-ConfiguracaoIP
    
    Write-Host "`n2. Teste de conexao com internet:" -ForegroundColor Cyan
    Testar-Conexao -Destino "8.8.8.8" -Quantidade 2
    
    Write-Host "`n3. Processos com alto consumo de CPU:" -ForegroundColor Cyan
    Get-Process | Where-Object { $_.CPU -gt 50 } | Format-Table -Property Id, ProcessName, CPU -AutoSize | Out-String | Write-Host
    
    Write-Host "`n4. Portas abertas no sistema:" -ForegroundColor Cyan
    Exibir-PortasAbertas
    
    Escrever-Mensagem "DIAGNOSTICO COMPLETO FINALIZADO" "SUCESSO"
    Write-Host "`nDiagnostico finalizado!" -ForegroundColor Green
}

# 14. Limpeza completa do sistema
function Limpeza-Completa {
    Escrever-Mensagem "INICIANDO LIMPEZA COMPLETA DO SISTEMA" "INFO"
    Write-Host "`n========== LIMPEZA COMPLETA ==========" -ForegroundColor Magenta
    
    Write-Host "`n1. Limpando arquivos temporarios..." -ForegroundColor Cyan
    Limpar-ArquivosTemporarios
    
    Write-Host "`n2. Limpando cache DNS..." -ForegroundColor Cyan
    Limpar-CacheDNS
    
    Write-Host "`n3. Limpando cache do Windows Update..." -ForegroundColor Cyan
    Stop-Service -Name wuauserv, bits -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Downloads\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv, bits -ErrorAction SilentlyContinue
    Write-Host "  Cache do Windows Update limpo" -ForegroundColor Gray
    
    Write-Host "`n4. Limpando logs antigos do sistema..." -ForegroundColor Cyan
    wevtutil el | ForEach-Object { wevtutil cl $_ -ErrorAction SilentlyContinue }
    Write-Host "  Logs do sistema limpos" -ForegroundColor Gray
    
    Escrever-Mensagem "LIMPEZA COMPLETA FINALIZADA" "SUCESSO"
    Write-Host "`nLimpeza completa finalizada!" -ForegroundColor Green
}

# ============================================
# INTERFACE DO MENU PRINCIPAL
# ============================================

function Mostrar-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    $NOME_FERRAMENTA" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "[ SISTEMA ]" -ForegroundColor Yellow
    Write-Host " 1. Limpar arquivos temporarios"
    Write-Host " 2. Limpar cache DNS"
    Write-Host " 3. Ver configuracao de IP"
    Write-Host " 4. Ver processos em execucao"
    Write-Host " 5. Ver usuarios logados"
    Write-Host " 6. Ver portas abertas"
    Write-Host ""
    
    Write-Host "[ REDE ]" -ForegroundColor Yellow
    Write-Host " 7. Testar ping (com opcoes)"
    Write-Host " 8. Reset completo de rede"
    Write-Host ""
    
    Write-Host "[ DIAGNOSTICO E REPARO ]" -ForegroundColor Yellow
    Write-Host " 9. Executar SFC (verifica arquivos do sistema)"
    Write-Host "10. Executar CHKDSK (verifica disco)"
    Write-Host "11. Executar DISM (repara Windows)"
    Write-Host "12. Resetar Windows Update"
    Write-Host ""
    
    Write-Host "[ EXTRA ]" -ForegroundColor Yellow
    Write-Host "13. Diagnostico completo do sistema"
    Write-Host "14. Limpeza completa do sistema"
    Write-Host ""
    
    Write-Host "[ SAIR ]" -ForegroundColor Red
    Write-Host " 0. Sair"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
}

# ============================================
# PROGRAMA PRINCIPAL (INICIO)
# ============================================

# Limpa a tela e mostra banner inicial
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     FERRAMENTA DE SUPORTE TECNICO" -ForegroundColor White
Write-Host "          Inicializando..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Script pronto! Use o menu abaixo." -ForegroundColor Green
Start-Sleep -Seconds 2

# Loop principal que mantem o menu funcionando
do {
    Mostrar-Menu
    $opcao = Read-Host "`nDigite o numero da opcao desejada"
    
    switch ($opcao) {
        "1"  { Limpar-ArquivosTemporarios; Aguardar-Enter }
        "2"  { Limpar-CacheDNS; Aguardar-Enter }
        "3"  { Exibir-ConfiguracaoIP; Aguardar-Enter }
        "4"  { Exibir-Processos; Aguardar-Enter }
        "5"  { Exibir-UsuariosLogados; Aguardar-Enter }
        "6"  { Exibir-PortasAbertas; Aguardar-Enter }
        "7"  { Testar-Conexao; Aguardar-Enter }
        "8"  { Resetar-Rede; Aguardar-Enter }
        "9"  { Executar-SFC; Aguardar-Enter }
        "10" { Executar-CHKDSK; Aguardar-Enter }
        "11" { Executar-DISM; Aguardar-Enter }
        "12" { Resetar-WindowsUpdate; Aguardar-Enter }
        "13" { Diagnostico-Completo; Aguardar-Enter }
        "14" { Limpeza-Completa; Aguardar-Enter }
        "0"  { 
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "Encerrando a ferramenta..." -ForegroundColor Green
            Write-Host "Obrigado por usar $NOME_FERRAMENTA!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Cyan
            break
        }
        default { 
            Write-Host "Opcao invalida! Digite um numero de 0 a 14." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($opcao -ne "0")