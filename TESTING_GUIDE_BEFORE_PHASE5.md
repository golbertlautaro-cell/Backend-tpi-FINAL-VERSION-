# 🧪 GUÍA COMPLETA DE PRUEBAS - ANTES DE FASE 5

**Fecha**: 10 de Noviembre, 2025  
**Estado**: ✅ LISTO PARA PROBAR  
**Tests Totales**: 57/57 PASANDO  

---

## 📋 Tabla de Contenidos

1. [Verificación de Tests](#verificación-de-tests)
2. [Ejecutar Servicios](#ejecutar-servicios)
3. [Pruebas de Endpoints](#pruebas-de-endpoints)
4. [Swagger UI](#swagger-ui)
5. [Logs y Debugging](#logs-y-debugging)
6. [Solución de Problemas](#solución-de-problemas)

---

## ✅ Verificación de Tests

### Ya Realizado (Confirmado)

```
ms-solicitudes:  25 tests ✅
ms-logistica:    32 tests ✅
TOTAL:           57 tests ✅ (100% éxito)
```

### Ejecutar Tests Nuevamente

```bash
# ms-solicitudes
cd ms-solicitudes
mvn clean test

# ms-logistica
cd ms-logistica
mvn clean test
```

### Compilar sin Tests

```bash
# ms-solicitudes
mvn clean compile

# ms-logistica
mvn clean compile
```

---

## 🚀 Ejecutar Servicios

### Opción 1: Scripts (RECOMENDADO)

#### Windows PowerShell
```powershell
# Navega a la carpeta raíz
cd d:\Users\Usuario\Desktop\backend1

# Ejecuta el script
.\start-and-test.ps1
```

#### Linux/Mac Bash
```bash
cd ~/desktop/backend1
bash start-and-test.sh
```

**Ventajas**: 
- ✅ Inicia ambos servicios automáticamente
- ✅ Muestra URLs de prueba
- ✅ Maneja logs automáticamente
- ✅ Control+C para detener todo

---

### Opción 2: Terminal Separadas (MANUAL)

#### Terminal 1 - ms-logistica
```bash
cd d:\Users\Usuario\Desktop\backend1\ms-logistica
mvn spring-boot:run
```

Espera a ver:
```
Tomcat started on port(s): 8081
```

#### Terminal 2 - ms-solicitudes
```bash
cd d:\Users\Usuario\Desktop\backend1\ms-solicitudes
mvn spring-boot:run
```

Espera a ver:
```
Tomcat started on port(s): 8080
```

---

### Opción 3: IDE (IntelliJ/VS Code)

1. Abre el proyecto en tu IDE
2. Click derecho en `MsLogisticaApplication.java` → Run
3. Espera inicio (5-10 segundos)
4. Click derecho en `MsSolicitudesApplication.java` → Run
5. Espera inicio (5-10 segundos)

---

## 🔗 Pruebas de Endpoints

### 1️⃣ Health Check

Verifica que los servicios estén activos:

```bash
# ms-solicitudes
curl http://localhost:8080/actuator/health

# Respuesta esperada:
# {"status":"UP"}
```

```bash
# ms-logistica
curl http://localhost:8081/actuator/health

# Respuesta esperada:
# {"status":"UP"}
```

---

### 2️⃣ GeoController (Google Maps - Temporal)

**IMPORTANTE**: Necesitas API Key configurada en `application.yml`

#### Obtener Distancia

```bash
# Forma sencilla
curl "http://localhost:8081/api/distancia?origen=Buenos%20Aires&destino=C%C3%B3rdoba"

# Forma con jq (pretty print)
curl -s "http://localhost:8081/api/distancia?origen=Buenos%20Aires&destino=C%C3%B3rdoba" | jq .
```

#### Respuesta Esperada (200 OK)
```json
{
  "origen": "Buenos Aires, Argentina",
  "destino": "Córdoba, Argentina",
  "kilometros": 704.5,
  "duracionTexto": "7 hours 15 mins"
}
```

#### Errores Comunes

**Sin API Key**:
```json
{
  "error": "Google Maps API error: REQUEST_DENIED"
}
```
**Solución**: Configura `google.maps.api-key` en `application.yml`

**Ubicación no encontrada**:
```json
{
  "error": "Google Maps element error: NOT_FOUND"
}
```
**Solución**: Verifica que las ubicaciones sean válidas

---

### 3️⃣ Clientes (ms-solicitudes)

#### Listar Clientes
```bash
curl http://localhost:8080/api/clientes?page=0&size=10
```

#### Crear Cliente
```bash
curl -X POST http://localhost:8080/api/clientes \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Juan Pérez","email":"juan@example.com"}'
```

#### Obtener Cliente por ID
```bash
curl http://localhost:8080/api/clientes/1
```

---

### 4️⃣ Solicitudes (ms-solicitudes)

#### Listar Solicitudes
```bash
curl http://localhost:8080/api/solicitudes?page=0&size=10
```

#### Crear Solicitud
```bash
curl -X POST http://localhost:8080/api/solicitudes \
  -H "Content-Type: application/json" \
  -d '{
    "clienteId": 1,
    "estado": "PENDIENTE",
    "descripcion": "Solicitud de prueba"
  }'
```

---

### 5️⃣ Tramos (ms-solicitudes)

#### Listar Tramos
```bash
curl http://localhost:8080/api/tramos?page=0&size=10
```

#### Crear Tramo
```bash
curl -X POST http://localhost:8080/api/tramos/1 \
  -H "Content-Type: application/json" \
  -d '{
    "origen": "Buenos Aires",
    "destino": "La Plata",
    "estado": "PENDIENTE"
  }'
```

---

### 6️⃣ Camiones (ms-logistica)

#### Listar Camiones
```bash
curl http://localhost:8081/api/camiones?page=0&size=10
```

#### Crear Camión
```bash
curl -X POST http://localhost:8081/api/camiones \
  -H "Content-Type: application/json" \
  -d '{
    "patente": "ABC-123",
    "marca": "Volvo",
    "pesoMaximo": 10000,
    "volumenMaximo": 50,
    "costoBaseKm": 50.0
  }'
```

---

### 7️⃣ Depósitos (ms-logistica)

#### Listar Depósitos
```bash
curl http://localhost:8081/api/depositos?page=0&size=10
```

#### Crear Depósito
```bash
curl -X POST http://localhost:8081/api/depositos \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Depósito Centro",
    "latitud": -34.6037,
    "longitud": -58.3816,
    "costoEstadiaXHora": 50.0
  }'
```

---

## 🌐 Swagger UI

Interfaz gráfica para probar endpoints:

### ms-logistica
```
http://localhost:8081/swagger-ui/index.html
```

### ms-solicitudes
```
http://localhost:8080/swagger-ui/index.html
```

### Cómo usar Swagger:
1. Abre URL en navegador
2. Busca el endpoint que quieres probar
3. Click en "Try it out"
4. Ingresa parámetros
5. Click "Execute"
6. Ve respuesta en "Response body"

---

## 📊 Logs y Debugging

### Ver Logs en Tiempo Real

#### Windows PowerShell
```powershell
# ms-logistica
Get-Content -Path logs/ms-logistica.log -Wait

# ms-solicitudes
Get-Content -Path logs/ms-solicitudes.log -Wait
```

#### Linux/Mac
```bash
# ms-logistica
tail -f logs/ms-logistica.log

# ms-solicitudes
tail -f logs/ms-solicitudes.log
```

### Últimas líneas de logs
```bash
# Últimas 50 líneas
tail -n 50 logs/ms-logistica.log
```

### Buscar errores
```bash
# Errores en logs
grep -i error logs/ms-logistica.log
grep -i error logs/ms-solicitudes.log

# Cambios en logs (en tiempo real)
tail -f logs/ms-logistica.log | grep -i "google\|error\|exception"
```

---

## 🔍 Solución de Problemas

### Puerto ya en uso

```
ERROR: Port 8080 is already in use
```

**Solución**:
```bash
# Windows - Matar proceso en puerto 8080
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :8080
kill -9 <PID>
```

### Error de Compilación

```
[ERROR] BUILD FAILURE
```

**Soluciones**:
1. Limpiar caché: `mvn clean`
2. Actualizar dependencias: `mvn dependency:resolve`
3. Verificar Java: `java -version`
4. Verificar Maven: `mvn -version`

### Error al conectar a Base de Datos

```
Cannot connect to database
```

**Soluciones**:
1. Verificar que PostgreSQL esté corriendo
2. Verificar credenciales en `application.yml`
3. Verificar puerto PostgreSQL (default: 5432)

### Google Maps Error

```
Google Maps API error: REQUEST_DENIED
```

**Soluciones**:
1. Verificar que API Key esté configurada
2. Verificar que API Key sea válida
3. Verificar que Google Maps Distance Matrix API esté habilitada
4. Verificar que no hayas excedido cuota

### Servicios Lentos

**Causas**:
- Primera compilación toma más tiempo (~30 segundos)
- Maven descargando dependencias
- PostgreSQL sin optimizar

**Soluciones**:
- Esperar 10-15 segundos después del startup
- Usar `mvn install -DskipTests` primera vez
- Verificar recursos disponibles (CPU, RAM)

---

## ✅ Checklist de Pruebas

Antes de continuar con Fase 5, verifica:

- [ ] ✅ 57 tests pasando (25 + 32)
- [ ] ✅ Ambos servicios compilan sin errores
- [ ] ✅ ms-logistica en puerto 8081
- [ ] ✅ ms-solicitudes en puerto 8080
- [ ] ✅ Health check responde OK
- [ ] ✅ Swagger UI accesible
- [ ] ✅ GeoController funciona (si API Key configurada)
- [ ] ✅ Listar endpoints funcionan (Clientes, Solicitudes, Tramos, Camiones, Depósitos)
- [ ] ✅ Logs se escriben correctamente
- [ ] ✅ GoogleMapsService integrado en TramoService

---

## 📚 Documentación Disponible

1. **VERIFICATION_ALL_TESTS_PASSING.md** - Resumen de tests
2. **GOOGLE_MAPS_IMPLEMENTATION.md** - Integración ms-logistica
3. **GOOGLE_MAPS_TRAMO_INTEGRATION.md** - Integración ms-solicitudes
4. **PHASE5_GOOGLE_MAPS_TRAMO_FINAL.md** - Resumen completo
5. **TESTING_GEO_CONTROLLER.md** - Guía de pruebas GeoController

---

## 🚀 Próximo Paso

Una vez que hayas validado que todo funciona:

1. ✅ Prueba tests
2. ✅ Prueba endpoints
3. ✅ Verifica logs
4. ✅ Confirma Google Maps (si tienes API Key)

**Entonces**: Procede a **Fase 5**

- 🐳 Docker Compose Override
- 📊 Spring Boot Actuator
- 🔄 GitHub Actions CI/CD
- 📈 Prometheus + Grafana

---

## 💡 Tips Útiles

### Instalación de herramientas
```bash
# jq para pretty-print JSON
# Windows: choco install jq
# Mac: brew install jq
# Linux: apt install jq
```

### Alias de comandos útiles
```bash
# Agregar a .bashrc o .powershell_profile

# Test services
alias test-services="curl http://localhost:8080/actuator/health && curl http://localhost:8081/actuator/health"

# View logs
alias logs-logistica="tail -f logs/ms-logistica.log"
alias logs-solicitudes="tail -f logs/ms-solicitudes.log"

# Kill processes
alias kill-8080="taskkill /F /IM java.exe | findstr 8080"
alias kill-8081="taskkill /F /IM java.exe | findstr 8081"
```

---

**Status**: 🎉 LISTO PARA PROBAR  
**Próximo**: Fase 5 (Docker, Actuator, CI/CD)
