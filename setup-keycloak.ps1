# Obtener token de admin
$adminToken = (Invoke-WebRequest -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body @{grant_type="password"; client_id="admin-cli"; username="admin"; password="admin123"} | ConvertFrom-Json).access_token
Write-Host "[OK] Token de admin obtenido"

# Crear realm
$realmJson = @{ realm = "tpi-realm"; enabled = $true; displayName = "TPI Realm" } | ConvertTo-Json
try {
    $realmResp = Invoke-WebRequest -Uri "http://localhost:8090/admin/realms" -Method Post -Headers @{Authorization="Bearer $adminToken"; "Content-Type"="application/json"} -Body $realmJson
    Write-Host "[OK] Realm tpi-realm creado"
} catch {
    Write-Host "[OK] Realm tpi-realm ya existe"
}

# Crear cliente
$clientJson = @{ clientId = "tpi-api"; enabled = $true; publicClient = $false; directAccessGrantsEnabled = $true; redirectUris = @("http://localhost:*", "*"); webOrigins = @("*") } | ConvertTo-Json
try {
    $clientResp = Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/tpi-realm/clients" -Method Post -Headers @{Authorization="Bearer $adminToken"; "Content-Type"="application/json"} -Body $clientJson
    Write-Host "[OK] Cliente tpi-api creado"
} catch {
    Write-Host "[OK] Cliente tpi-api ya existe"
}

# Crear usuarios
$users = @("cliente1", "operador1", "transportista1")
foreach ($user in $users) {
    $userData = @{ username = $user; enabled = $true; credentials = @(@{ type = "password"; value = "password123"; temporary = $false }) } | ConvertTo-Json
    try {
        $userResp = Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/tpi-realm/users" -Method Post -Headers @{Authorization="Bearer $adminToken"; "Content-Type"="application/json"} -Body $userData
        Write-Host "[OK] Usuario $user creado"
    } catch {
        Write-Host "[OK] Usuario $user ya existe"
    }
}

Write-Host ""
Write-Host "[OK] Setup completado"
