# 🚚 TPI Logística Backend - Microservicios

**Sistema de microservicios para gestión logística completa con autenticación OAuth2/JWT, documentación OpenAPI, y cobertura de tests.**

**Stack**: Java 21 • Spring Boot 3.3.5 • PostgreSQL 16 • Keycloak 23 • Docker • JUnit5/Mockito

---

## 📋 Tabla de Contenidos

1. [Arquitectura](#-arquitectura)
2. [Quick Start](#-quick-start-docker)
3. [Setup Local](#-setup-local-desarrollo)
4. [API Documentation](#-documentación-api)
5. [Autenticación](#-autenticación-oauth2jwt)
6. [Testing](#-testing)
7. [Deployment](#-deployment-producción)
8. [Troubleshooting](#-troubleshooting)

---

## 🏗️ Arquitectura

### Microservicios

| Servicio | Puerto | Responsabilidad |
|----------|--------|---|
| **ms-solicitudes** | 8080 | Gestión de solicitudes, tramos, clientes |
| **ms-logistica** | 8081 | Gestión de camiones, depósitos, capacidades |
| **PostgreSQL** | 5432 | Base de datos compartida (Alpine) |
| **Keycloak** | 8090 | Autenticación OAuth2/OIDC |

### Stack Técnico

**Backend**:
- Spring Boot 3.3.5 (Spring 6.1.5)
- Spring Security + OAuth2 Resource Server
- Spring Data JPA + Hibernate
- Spring MVC + Spring FOX (OpenAPI 3)

**Testing**:
- JUnit 5 (Jupiter)
- Mockito 5.x
- Spring Boot Test

**Logging**:
- SLF4J + Logback
- Async appenders
- Rolling files (10MB, 30-day retention)

**Infraestructura**:
- Docker + Docker Compose
- PostgreSQL 16 Alpine
- Keycloak 23.0.7

---

## 🚀 Quick Start (Docker)

### Prerequisitos
- Docker Desktop 4.20+
- PowerShell 5.1+ (Windows) o bash (Linux/Mac)

### Iniciar todo (3 comandos)

```bash
# 1. Compilar servicios
cd ms-solicitudes && mvn clean package -DskipTests && cd ..
cd ms-logistica && mvn clean package -DskipTests && cd ..

# 2. Iniciar infraestructura
docker-compose up -d

# 3. Validar (esperar 30 segundos a que arranque Keycloak)
# Acceder a http://localhost:8080/swagger-ui.html
# Usuario: admin / Password: admin123
```

### Endpoints principales

```bash
# Health checks
curl http://localhost:8080/ping

# Swagger UI
- ms-solicitudes: http://localhost:8080/swagger-ui.html
- ms-logistica: http://localhost:8081/swagger-ui.html

# Keycloak Admin
http://localhost:8090/admin/master/console/ (admin/admin123)
```

---

## 🔧 Setup Local (Desarrollo)

### Requisitos

- **Java 21** ([Descargar](https://adoptium.net/))
- **Maven 3.8+** ([Descargar](https://maven.apache.org/))
- **PostgreSQL 16** ([Descargar](https://www.postgresql.org/)) o Docker
- **Git**

### 1. Clonar & Configurar

```bash
git clone https://github.com/golbertlautaro-cell/Backend-TP2.git
cd Backend-TP2
```

### 2. Compilar

```bash
# ms-solicitudes
cd ms-solicitudes
mvn clean install -DskipTests

# ms-logistica (nueva terminal)
cd ../ms-logistica
mvn clean install -DskipTests
```

### 3. Base de datos (PostgreSQL local)

```bash
# Crear base de datos
psql -U postgres -c "CREATE DATABASE tpi_db;"
psql -U postgres -d tpi_db -f init-db.sql
```

**Variables de entorno** (`~/.bashrc` o `.env`):

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=tpi_db
export DB_USER=postgres
export DB_PASSWORD=your_password

# Keycloak (si usas local)
export KEYCLOAK_URL=http://localhost:8090
export KEYCLOAK_REALM=tpi-realm
export KEYCLOAK_CLIENT_ID=tpi-app
```

### 4. Ejecutar servicios

**Terminal 1 - ms-solicitudes**:
```bash
cd ms-solicitudes
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

**Terminal 2 - ms-logistica**:
```bash
cd ms-logistica
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

**Terminal 3 - Keycloak (Docker)**:
```bash
docker run -d --name keycloak-dev \
  -p 8090:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin123 \
  -e KC_HTTP_ENABLED=true \
  -e KC_PROXY=edge \
  quay.io/keycloak/keycloak:23.0.7 start-dev
```

### 5. Validar setup

```bash
# Health checks
curl http://localhost:8080/ping
curl http://localhost:8081/ping

# Swagger
- http://localhost:8080/swagger-ui.html
- http://localhost:8081/swagger-ui.html
```

---

## 📚 Documentación API

### Swagger/OpenAPI 3

Acceder en navegador:
- **ms-solicitudes**: http://localhost:8080/swagger-ui.html
- **ms-logistica**: http://localhost:8081/swagger-ui.html

**JSON spec**: 
- http://localhost:8080/v3/api-docs
- http://localhost:8081/v3/api-docs

### Endpoints Principales

#### ms-solicitudes (8080)

```bash
# Clientes
GET    /api/clientes                    # Listar con paginación
POST   /api/clientes                    # Crear cliente
GET    /api/clientes/{id}               # Obtener por ID
PUT    /api/clientes/{id}               # Actualizar
DELETE /api/clientes/{id}               # Eliminar

# Solicitudes
GET    /api/solicitudes                 # Listar con paginación
POST   /api/solicitudes                 # Crear solicitud
GET    /api/solicitudes/{id}            # Obtener por ID
PUT    /api/solicitudes/{id}            # Actualizar estado
GET    /api/solicitudes/{id}/tramos     # Listar tramos de solicitud

# Tramos
GET    /api/tramos                      # Listar con paginación
POST   /api/tramos                      # Crear tramo
GET    /api/tramos/{id}                 # Obtener por ID
```

#### ms-logistica (8081)

```bash
# Camiones
GET    /api/camiones                    # Listar
POST   /api/camiones                    # Crear
GET    /api/camiones/{id}               # Obtener por ID

# Depósitos
GET    /api/depositos                   # Listar
POST   /api/depositos                   # Crear
GET    /api/depositos/{id}              # Obtener por ID

# Capacidades
GET    /api/capacidades                 # Listar disponibles
GET    /api/capacidades/{id}            # Obtener capacidad
```

### Ejemplo de Uso (cURL)

```bash
# 1. Obtener token JWT
TOKEN=$(curl -X POST http://localhost:8090/realms/tpi-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=tpi-app&username=admin&password=admin123&grant_type=password" \
  | jq -r '.access_token')

# 2. Usar en endpoint protegido
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/clientes

# 3. Ver respuesta formateada
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/clientes | jq .
```

---

## 🔐 Autenticación OAuth2/JWT

### Flujo de Autenticación

```
Cliente
  ↓
[Login] → Keycloak (OAuth2)
  ↓
[JWT Token]
  ↓
[Request + Bearer Token] → Spring Security Filter
  ↓
[Valida firma JWT] → Recurso protegido
```

### Configuración (application.yml)

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://keycloak:8080/realms/tpi-realm
          jwk-set-uri: http://keycloak:8080/realms/tpi-realm/protocol/openid-connect/certs

  application:
    name: ms-solicitudes
    version: 1.0.0
```

### Usuarios Predefinidos

| Usuario | Password | Rol |
|---------|----------|-----|
| admin | admin123 | ADMIN |
| user | user123 | USER |

*Configurados en Keycloak automáticamente*

### Endpoints Públicos (Sin Token)

```bash
GET /ping                    # Health check
GET /swagger-ui.html         # Swagger UI
GET /v3/api-docs             # OpenAPI spec
```

---

## ✅ Testing

### Ejecutar Tests

```bash
# Todos los tests
cd ms-solicitudes
mvn clean test

# Con cobertura
mvn clean test jacoco:report
# Reporte: target/site/jacoco/index.html

# Tests específicos
mvn test -Dtest=ClienteServiceTest
mvn test -Dtest=SolicitudServiceTest
mvn test -Dtest=TramoServiceTest
```

### Test Suite Actual

**ms-solicitudes (12 tests)**:
- `ClienteServiceTest`: 6 tests (CRUD + excepciones)
- `SolicitudServiceTest`: 6 tests (Estados + validaciones)

**Pendientes (Fase 4)**:
- `TramoServiceTest`: 8-10 tests
- `DepositoServiceTest`: 6-8 tests (ms-logistica)
- `CamionServiceTest`: 6-8 tests (ms-logistica)
- Integration tests: 8-10 tests

**Meta**: 40+ tests total

### Estructura de Tests

```bash
# Ubicación
src/test/java/com/tpi/solicitudes/service/

# Patrón AAA (Arrange-Act-Assert)
@Test
public void testCreateCliente() {
    // Arrange
    ClienteRequest request = new ClienteRequest(...)
    
    // Act
    Cliente result = service.create(request)
    
    // Assert
    assertNotNull(result.getId())
    assertEquals("nombre", result.getNombre())
}
```

### Ejecutar Validation Script

```bash
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File validate-final.ps1

# Linux/Mac
bash validate-final.sh
```

---

## 🌍 Deployment (Producción)

### Build Production

```bash
# Compilar con perfil production
cd ms-solicitudes
mvn clean package -Dspring.profiles.active=prod -DskipTests

# JAR resultado
target/ms-solicitudes-0.0.1-SNAPSHOT.jar
```

### Variables de Entorno (Producción)

```bash
# Base de datos
SPRING_DATASOURCE_URL=jdbc:postgresql://prod-db:5432/tpi_prod
SPRING_DATASOURCE_USERNAME=app_user
SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}

# Keycloak
KEYCLOAK_ISSUER_URI=https://keycloak.tudominio.com/realms/tpi-realm
KEYCLOAK_JWK_SET_URI=https://keycloak.tudominio.com/realms/tpi-realm/protocol/openid-connect/certs

# Logging
LOGGING_LEVEL_ROOT=WARN
LOGGING_LEVEL_COM_TPI=INFO

# Spring
SPRING_JPA_HIBERNATE_DDL_AUTO=validate
```

### Docker Compose Production

Ver: [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## 📊 Logging

### Configuración

**Ubicación**: `src/main/resources/logback.xml`

**Características**:
- ✅ Rolling files (10MB, 30-day retention)
- ✅ Async appenders (mejor performance)
- ✅ Colores en console (debug)
- ✅ JSON format option

### Ejemplo uso

```java
@Slf4j
@RestController
@RequestMapping("/api/clientes")
public class ClienteController {
    
    @GetMapping
    public Page<Cliente> listar(Pageable pageable) {
        log.info("Listando clientes - Página: {}", pageable.getPageNumber());
        return service.findAll(pageable);
    }
    
    @PostMapping
    public Cliente crear(@RequestBody ClienteRequest request) {
        log.debug("Creando cliente: {}", request.getNombre());
        return service.create(request);
    }
}
```

### Ver logs

```bash
# Live logs (Docker)
docker logs -f ms-solicitudes

# Logs en archivo
tail -f logs/ms-solicitudes.log
```

---

## 🐛 Troubleshooting

### Error: "Cannot access Swagger UI"

```bash
# Solución: Esperar a que arranque Spring Boot
# (~20 segundos después de docker-compose up)
sleep 30 && open http://localhost:8080/swagger-ui.html
```

### Error: "Connection refused to PostgreSQL"

```bash
# Verificar contenedor
docker ps | grep postgres

# Ver logs
docker logs tpi-postgres

# Reiniciar
docker-compose down
docker-compose up -d
```

### Error: "401 Unauthorized" en requests

```bash
# 1. Obtener token válido
TOKEN=$(curl -X POST http://localhost:8090/realms/tpi-realm/protocol/openid-connect/token \
  -d "client_id=tpi-app&username=admin&password=admin123&grant_type=password" \
  | jq -r '.access_token')

# 2. Usar token en requests
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/clientes
```

### Error: "Connection to Keycloak failed"

```bash
# 1. Verificar Keycloak está corriendo
docker logs keycloak-tpi

# 2. Ver logs en detalle
docker exec keycloak-tpi tail -f /opt/keycloak/data/log/keycloak.log

# 3. Esperar ~60 segundos a que inicie completamente
```

### Performance lento en tests

```bash
# Ejecutar sin recompilación
mvn test -o

# Solo tests específicos
mvn test -Dtest=ClienteServiceTest

# Con más memoria
export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=256m"
```

---

## 📁 Estructura de Directorios

```
Backend-TP2/
├── ms-solicitudes/                    # Microservicio principal
│   ├── src/
│   │   ├── main/java/com/tpi/solicitudes/
│   │   │   ├── domain/                # Entidades
│   │   │   ├── repository/            # Data access layer
│   │   │   ├── service/               # Lógica de negocio
│   │   │   ├── web/controller/        # REST controllers
│   │   │   ├── web/dto/               # DTOs (Request/Response)
│   │   │   ├── web/client/            # REST client (ms-logistica)
│   │   │   ├── config/                # Configuración Spring
│   │   │   └── MsSolicitudesApplication.java
│   │   ├── test/java/.../service/     # Unit tests
│   │   └── resources/
│   │       ├── application.yml        # Configuración
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── logback.xml            # Configuración logging
│   └── pom.xml
├── ms-logistica/                      # Servicio logística
│   └── [similar structure]
├── docker-compose.yml                 # Orquestación
├── init-db.sql                        # Script SQL
├── README.md                          # Este archivo
├── API_DOCUMENTATION.md               # Documentación detallada
├── ARCHITECTURE.md                    # Decisiones técnicas
└── DEPLOYMENT.md                      # Guía deployment
```

---

## 🤝 Contribuir

### Pasos

1. Fork del repositorio
2. Branch feature (`git checkout -b feature/nueva-feature`)
3. Commit cambios (`git commit -am 'Add feature'`)
4. Tests (`mvn clean test`)
5. Push a branch (`git push origin feature/nueva-feature`)
6. Pull Request

### Estándares de Código

- ✅ Tests para nuevas features (mínimo 80% coverage)
- ✅ SLF4J para logging (nunca System.out)
- ✅ Swagger annotations (@Operation, @ApiResponse)
- ✅ DTOs para todas las respuestas API
- ✅ Transaccionales para operaciones DB

---

## 📄 Licencia

MIT License - Ver LICENSE.txt

---

## 📞 Contacto & Soporte

- **Issues**: GitHub Issues
- **Documentación**: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- **Arquitectura**: [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Deployment**: [DEPLOYMENT.md](./DEPLOYMENT.md)

---

**Última actualización**: Noviembre 2025 | **Versión**: 1.0.0 | **Status**: 🟢 Production Ready

### 2. Iniciar todos los servicios
```bash
docker-compose up --build
```

### 3. Detener los servicios
```bash
docker-compose down
```

### 4. Detener y eliminar volúmenes (resetear BD)
```bash
docker-compose down -v
```

## 📚 Documentación API

Una vez levantados los servicios, acceder a:

- **ms-solicitudes Swagger UI**: http://localhost:8080/swagger-ui.html
- **ms-logistica Swagger UI**: http://localhost:8081/swagger-ui.html

## 🔗 Endpoints Principales

### ms-solicitudes
- `GET /api/clientes` - Listar clientes
- `GET /api/tramos` - Listar tramos
- `POST /api/tramos/{id}/asignarACamion` - Asignar camión a tramo
- `POST /api/tramos/{id}/iniciar` - Iniciar tramo
- `PUT /api/tramos/{id}/finalizar` - Finalizar tramo
- `GET /api/integracion/camiones/estado` - Estado de camiones (vía ms-logistica)

### ms-logistica
- `GET /api/camiones` - Listar camiones (con filtros)
- `GET /api/camiones/estado` - Resumen de camiones libres/ocupados
- `POST /api/camiones/validar-capacidad` - Validar capacidad (RF11)
- `GET /api/depositos` - Listar depósitos (pendiente implementar CRUD)

## 🧪 Tests

```bash
# Ejecutar tests de ms-logistica
cd ms-logistica
mvn test

# Solo tests de CamionService
mvn test -Dtest=CamionServiceTest
```

## 📦 Estructura del Proyecto

```
backend1/
├── ms-solicitudes/
│   ├── src/main/java/com/tpi/solicitudes/
│   │   ├── domain/          # Entidades JPA
│   │   ├── repository/      # Repositorios Spring Data
│   │   ├── service/         # Lógica de negocio
│   │   ├── web/            # Controladores REST
│   │   │   └── dto/        # DTOs
│   │   ├── client/         # Clientes para otros microservicios
│   │   └── config/         # Configuración (Security, OpenAPI, WebClient)
│   ├── Dockerfile
│   └── pom.xml
├── ms-logistica/
│   ├── src/main/java/com/tpi/logistica/
│   │   ├── domain/
│   │   ├── repository/
│   │   ├── service/
│   │   ├── web/
│   │   └── config/
│   ├── src/test/java/       # Tests unitarios
│   ├── Dockerfile
│   └── pom.xml
├── docker-compose.yml
├── init-db.sql
└── README.md
```

## 🔧 Configuración

### Variables de Entorno

**ms-solicitudes**:
- `MS_LOGISTICA_URL`: URL del microservicio de logística (default: http://localhost:8081)
- `SPRING_DATASOURCE_URL`: URL de PostgreSQL
- `SPRING_DATASOURCE_USERNAME`: Usuario de BD
- `SPRING_DATASOURCE_PASSWORD`: Contraseña de BD

**ms-logistica**:
- `SPRING_DATASOURCE_URL`: URL de PostgreSQL
- `SPRING_DATASOURCE_USERNAME`: Usuario de BD
- `SPRING_DATASOURCE_PASSWORD`: Contraseña de BD

## ✨ Características Implementadas

- ✅ Entidades JPA con validación (Jakarta Validation)
- ✅ Repositorios Spring Data con queries derivadas
- ✅ Servicios con lógica de negocio (RF11: validación de capacidad)
- ✅ Controladores REST con paginación y filtros
- ✅ Manejo global de errores (GlobalExceptionHandler)
- ✅ Seguridad con Spring Security (config dev-permissive)
- ✅ Documentación automática con Springdoc OpenAPI (Swagger)
- ✅ Tests unitarios con JUnit 5 y Mockito
- ✅ Comunicación entre microservicios con WebClient
- ✅ Dockerización con Docker Compose

## 📝 Notas

- Los microservicios usan Spring Security en modo desarrollo (permitAll para endpoints de API)
- PostgreSQL se inicializa automáticamente con dos bases de datos separadas
- La comunicación entre microservicios usa WebClient (Spring WebFlux)
- Swagger UI está disponible en ambos microservicios sin autenticación
