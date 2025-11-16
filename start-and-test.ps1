# Script para iniciar y probar microservicios en Windows
# Uso: .\start-and-test.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  INICIANDO MICROSERVICIOS - TPI LOGISTICA" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Crear directorio de logs si no existe
if (-Not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Compilar ms-logistica
Write-Host "[1/4] Compilando ms-logistica..." -ForegroundColor Blue
Set-Location ms-logistica
mvn clean compile -q
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ms-logistica compilado exitosamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error compilando ms-logistica" -ForegroundColor Red
    exit 1
}

# Compilar ms-solicitudes
Write-Host ""
Write-Host "[2/4] Compilando ms-solicitudes..." -ForegroundColor Blue
Set-Location ../ms-solicitudes
mvn clean compile -q
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ms-solicitudes compilado exitosamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error compilando ms-solicitudes" -ForegroundColor Red
    exit 1
}

Set-Location ..

# Iniciar ms-logistica en background
Write-Host ""
Write-Host "[3/4] Iniciando ms-logistica (puerto 8081)..." -ForegroundColor Blue
Write-Host "Ejecutando: mvn spring-boot:run -f ms-logistica/pom.xml" -ForegroundColor Gray
$logisticaJob = Start-Job -ScriptBlock {
    cd $args[0]
    mvn spring-boot:run -f ms-logistica/pom.xml
} -ArgumentList (Get-Location)

Start-Sleep -Seconds 3
Write-Host "✅ ms-logistica iniciado" -ForegroundColor Green
Write-Host "   Logs: logs/ms-logistica.log" -ForegroundColor Gray

# Iniciar ms-solicitudes en background
Write-Host ""
Write-Host "[4/4] Iniciando ms-solicitudes (puerto 8080)..." -ForegroundColor Blue
Write-Host "Ejecutando: mvn spring-boot:run -f ms-solicitudes/pom.xml" -ForegroundColor Gray
$solicitudesJob = Start-Job -ScriptBlock {
    cd $args[0]
    mvn spring-boot:run -f ms-solicitudes/pom.xml
} -ArgumentList (Get-Location)

Start-Sleep -Seconds 5
Write-Host "✅ ms-solicitudes iniciado" -ForegroundColor Green
Write-Host "   Logs: logs/ms-solicitudes.log" -ForegroundColor Gray

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  SERVICIOS EN EJECUCIÓN" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "ms-logistica" -ForegroundColor Green -NoNewline
Write-Host "     (Puerto 8081)" -ForegroundColor Gray
Write-Host "  - Health:  http://localhost:8081/actuator/health" -ForegroundColor Gray
Write-Host "  - Swagger: http://localhost:8081/swagger-ui/index.html" -ForegroundColor Gray
Write-Host "  - GEO API: http://localhost:8081/api/distancia" -ForegroundColor Gray
Write-Host ""

Write-Host "ms-solicitudes" -ForegroundColor Green -NoNewline
Write-Host "   (Puerto 8080)" -ForegroundColor Gray
Write-Host "  - Health:  http://localhost:8080/actuator/health" -ForegroundColor Gray
Write-Host "  - Swagger: http://localhost:8080/swagger-ui/index.html" -ForegroundColor Gray
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  PRUEBAS RECOMENDADAS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Health Check:" -ForegroundColor Yellow
Write-Host "   curl http://localhost:8080/actuator/health" -ForegroundColor Gray
Write-Host "   curl http://localhost:8081/actuator/health" -ForegroundColor Gray
Write-Host ""

Write-Host "2. GeoController (Google Maps):" -ForegroundColor Yellow
Write-Host "   curl 'http://localhost:8081/api/distancia?origen=Buenos+Aires&destino=Cordoba'" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Ver logs en tiempo real:" -ForegroundColor Yellow
Write-Host "   Get-Content -Path logs/ms-logistica.log -Wait" -ForegroundColor Gray
Write-Host "   Get-Content -Path logs/ms-solicitudes.log -Wait" -ForegroundColor Gray
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Presiona Ctrl+C para detener los servicios" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Mantener el script en ejecución
while ($true) {
    Start-Sleep -Seconds 1
    
    # Verificar si los jobs están en ejecución
    if ((Get-Job -Id $logisticaJob.Id).State -ne "Running" -or (Get-Job -Id $solicitudesJob.Id).State -ne "Running") {
        Write-Host ""
        Write-Host "Un servicio se ha detenido." -ForegroundColor Yellow
        Write-Host "Deteniendo otros servicios..." -ForegroundColor Yellow
        Stop-Job -Id $logisticaJob.Id -ErrorAction SilentlyContinue
        Stop-Job -Id $solicitudesJob.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $logisticaJob.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $solicitudesJob.Id -ErrorAction SilentlyContinue
        break
    }
}

Write-Host ""
Write-Host "Servicios detenidos" -ForegroundColor Yellow
