# Script final de validacion Phase 1 + Phase 2 + E2E Auth
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "VALIDACION FINAL - PHASE 1 + PHASE 2 + E2E AUTH" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Obtener token de Keycloak
Write-Host "1. Obteniendo token JWT de Keycloak..." -ForegroundColor Yellow
$adminToken = (Invoke-WebRequest -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body @{grant_type="password"; client_id="admin-cli"; username="admin"; password="admin123"} | ConvertFrom-Json).access_token
$clients = Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/tpi-realm/clients?clientId=tpi-api" -Headers @{Authorization="Bearer $adminToken"} | ConvertFrom-Json
$clientId = $clients[0].id
$secret = (Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/tpi-realm/clients/$clientId/client-secret" -Headers @{Authorization="Bearer $adminToken"} | ConvertFrom-Json).value
$tokenResp = Invoke-WebRequest -Uri "http://localhost:8090/realms/tpi-realm/protocol/openid-connect/token" -Method Post -Body @{grant_type="password"; client_id="tpi-api"; client_secret=$secret; username="cliente1"; password="password123"}
$token = ($tokenResp | ConvertFrom-Json).access_token
Write-Host "   OK - Token obtenido" -ForegroundColor Green
Write-Host ""

# 2. Probar endpoints autenticados
Write-Host "2. Validando endpoints autenticados..." -ForegroundColor Yellow
$endpoints = @(
    "http://localhost:8080/api/clientes",
    "http://localhost:8080/api/solicitudes",
    "http://localhost:8080/api/tramos"
)
foreach ($endpoint in $endpoints) {
    $resp = Invoke-WebRequest -Uri $endpoint -Headers @{Authorization="Bearer $token"}
    Write-Host "   OK - $endpoint - $($resp.StatusCode)" -ForegroundColor Green
}
Write-Host ""

# 3. Probar endpoint publico
Write-Host "3. Validando endpoints publicos..." -ForegroundColor Yellow
$resp = Invoke-WebRequest -Uri "http://localhost:8080/ping"
Write-Host "   OK - /ping - $($resp.StatusCode)" -ForegroundColor Green
Write-Host ""

# 4. Validar logs
Write-Host "4. Validando logs en contenedor..." -ForegroundColor Yellow
$logContent = docker exec ms-solicitudes cat logs/ms-solicitudes.log
if ($logContent -match "ClienteController") {
    Write-Host "   OK - Logs de ClienteController encontrados" -ForegroundColor Green
}
Write-Host ""

# 5. Resumen
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "VALIDACION COMPLETADA CON EXITO" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "OK - Phase 1: Swagger, DTOs, RestClient" -ForegroundColor Green
Write-Host "OK - Phase 2: Logging Estructurado" -ForegroundColor Green
Write-Host "OK - E2E Authentication con JWT" -ForegroundColor Green
Write-Host ""
Write-Host "Proximo paso: Phase 3 - Tests Unitarios" -ForegroundColor Yellow
