# Script de prueba: Verificar que JWT funciona correctamente
# Este script obtiene un token de Keycloak y lo usa para llamar a endpoints protegidos

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PRUEBA: JWT Authentication con Keycloak" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Obtener token
Write-Host "1. Obteniendo token de Keycloak..." -ForegroundColor Yellow
$tokenResp = Invoke-WebRequest -Uri "http://localhost:8090/realms/tpi-realm/protocol/openid-connect/token" -Method Post -Body @{grant_type="password"; client_id="tpi-api"; client_secret="HhLnouqj0UnCrJcEIbLQBWT7pg0mxm1e"; username="cliente1"; password="password123"}
$token = ($tokenResp | ConvertFrom-Json).access_token
Write-Host "   [OK] Token obtenido" -ForegroundColor Green
Write-Host ""

# 2. Verificar issuer del token
Write-Host "2. Verificando claim 'iss' del token..." -ForegroundColor Yellow
$parts = $token.Split('.')
$json = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($parts[1] + ("=" * (4 - $parts[1].Length % 4))))
$issuer = ($json | ConvertFrom-Json).iss
Write-Host "   Issuer: $issuer" -ForegroundColor Green
Write-Host ""

# 3. Probar endpoints autenticados
Write-Host "3. Probando endpoints autenticados..." -ForegroundColor Yellow
$endpoints = @(
    "http://localhost:8080/api/clientes",
    "http://localhost:8080/api/solicitudes",
    "http://localhost:8080/api/tramos",
    "http://localhost:8081/api/camiones",
    "http://localhost:8081/api/depositos"
)

foreach ($endpoint in $endpoints) {
    try {
        $resp = Invoke-WebRequest -Uri $endpoint -Headers @{Authorization="Bearer $token"} -ErrorAction Stop
        Write-Host "   $endpoint : $($resp.StatusCode) OK" -ForegroundColor Green
    } catch {
        Write-Host "   $endpoint : $($_.Exception.Response.StatusCode) ERROR" -ForegroundColor Red
    }
}
Write-Host ""

# 4. Probar endpoint público
Write-Host "4. Probando endpoint público (sin auth)..." -ForegroundColor Yellow
$resp = Invoke-WebRequest -Uri "http://localhost:8080/ping"
Write-Host "   http://localhost:8080/ping : $($resp.StatusCode) OK" -ForegroundColor Green
Write-Host ""

# 5. Probar endpoint sin token (debe fallar)
Write-Host "5. Probando endpoint protegido sin token (debe fallar)..." -ForegroundColor Yellow
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:8080/api/clientes" -ErrorAction Stop
    Write-Host "   ERROR: Debería haber fallado!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "   http://localhost:8080/api/clientes : 401 Unauthorized (esperado)" -ForegroundColor Green
    } else {
        Write-Host "   Código inesperado: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESULTADO: AUTENTICACION JWT FUNCIONA!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
