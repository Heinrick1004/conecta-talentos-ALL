$ErrorActionPreference = 'Stop'

$apiProcessName = 'ConectaTalentos.Api'
$apiPorts = @(5000, 7000)
$swaggerUrl = 'http://localhost:5000/swagger'

try {
    # Localiza listeners nas portas da API e filtra pelo nome exato do processo.
    $connections = @(Get-NetTCPConnection -State Listen -LocalPort $apiPorts -ErrorAction Stop)
    $apiProcesses = @(
        foreach ($ownerProcessId in ($connections | Select-Object -ExpandProperty OwningProcess -Unique)) {
            $process = Get-Process -Id $ownerProcessId -ErrorAction SilentlyContinue
            if ($process -and $process.ProcessName -ceq $apiProcessName) {
                $process
            }
        }
    )

    # Se a API já estiver ativa, oferece reutilizar a instância ou reiniciá-la.
    if ($apiProcesses.Count -gt 0) {
        Write-Host 'Já existe uma instância da ConectaTalentos API em execução:'
        foreach ($process in $apiProcesses) {
            $processPorts = @(
                $connections |
                    Where-Object { $_.OwningProcess -eq $process.Id } |
                    Select-Object -ExpandProperty LocalPort -Unique
            ) -join ', '
            Write-Host "  PID $($process.Id) - porta(s): $processPorts"
        }

        do {
            $choice = (Read-Host 'Digite 1 para encerrar e iniciar novamente, ou 2 para abrir o Swagger existente').Trim()
            if ($choice -notin @('1', '2')) {
                Write-Host 'Opção inválida. Digite 1 ou 2.' -ForegroundColor Yellow
            }
        } while ($choice -notin @('1', '2'))

        if ($choice -eq '2') {
            # Abre o Swagger da instância existente e encerra este script.
            Start-Process -FilePath $swaggerUrl
            exit 0
        }

        # Encerra somente processos cujo nome corresponda exatamente ao executável da API.
        foreach ($process in $apiProcesses) {
            $currentProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
            if ($currentProcess -and $currentProcess.ProcessName -ceq $apiProcessName) {
                Stop-Process -Id $currentProcess.Id -Force -ErrorAction Stop
            }
        }

        Start-Sleep -Seconds 2
    }

    # Inicia a API usando o perfil HTTP local e o projeto ao lado deste script.
    Write-Host 'Iniciando ConectaTalentos API em http://localhost:5000 ...' -ForegroundColor Cyan
    Push-Location -LiteralPath $PSScriptRoot
    try {
        & dotnet run --launch-profile http --project '.\ConectaTalentos.Api.csproj' 2>&1 |
            Tee-Object -Variable runOutput
        $dotnetExitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    # Em caso de falha, reapresenta a saída capturada e mantém a janela aberta.
    if ($dotnetExitCode -ne 0) {
        Write-Host "dotnet run encerrou com o código $dotnetExitCode. Saída capturada:" -ForegroundColor Red
        foreach ($line in $runOutput) {
            Write-Host $line
        }
        [void](Read-Host 'Pressione Enter para fechar esta janela')
    }

    exit $dotnetExitCode
}
catch {
    # Exibe falhas do próprio script e aguarda antes de fechar a janela.
    Write-Host "Não foi possível iniciar a ConectaTalentos API: $($_.Exception.Message)" -ForegroundColor Red
    [void](Read-Host 'Pressione Enter para fechar esta janela')
    exit 1
}