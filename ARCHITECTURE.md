# 🏗️ Arquitectura del Sistema - Decisiones Técnicas

**Versión**: 1.0.0 | **Fecha**: Noviembre 2025

---

## 📐 Vista General de la Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      Cliente (Web/Mobile)                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                    HTTP/REST
                         │
        ┌────────────────┴────────────────┐
        │                                 │
┌───────▼────────────┐        ┌──────────▼──────────┐
│  ms-solicitudes    │        │   ms-logistica      │
│    (8080)          │        │    (8081)           │
│ ┌────────────────┐ │        │ ┌────────────────┐  │
│ │ Controllers    │ │        │ │ Controllers    │  │
│ │ @RestController│ │        │ │ @RestController│  │
│ └────────────────┘ │        │ └────────────────┘  │
│ ┌────────────────┐ │        │ ┌────────────────┐  │
│ │ Services       │ │        │ │ Services       │  │
│ │ @Service       │ │        │ │ @Service       │  │
│ └────────────────┘ │        │ └────────────────┘  │
│ ┌────────────────┐ │        │ ┌────────────────┐  │
│ │ Repositories   │ │        │ │ Repositories   │  │
│ │ @Repository    │ │        │ │ @Repository    │  │
│ └────────────────┘ │        │ └────────────────┘  │
│                    │        │                     │
│ Spring Boot 3.3.5  │        │ Spring Boot 3.3.5   │
│ Java 21            │        │ Java 21             │
└────────┬───────────┘        └──────────┬──────────┘
         │                              │
         └──────────────┬───────────────┘
                        │
            ┌───────────▼───────────┐
            │   PostgreSQL 16       │
            │   (Docker Alpine)     │
            │                       │
            │ - Usuarios            │
            │ - Solicitudes         │
            │ - Tramos              │
            │ - Camiones            │
            │ - Depósitos           │
            └───────────────────────┘
            
        ┌──────────────────────────┐
        │   Keycloak 23.0.7        │
        │   (OAuth2/OIDC)          │
        │   (8090)                 │
        │                          │
        │ - Autenticación          │
        │ - Autorización           │
        │ - Gestión de Tokens      │
        └──────────────────────────┘
```

---

## 🎯 Decisiones de Arquitectura

### 1. Patrón: Microservicios

**Decisión**: Dividir en 2 microservicios separados por dominio

```
✅ VENTAJAS:
- Escalabilidad independiente
- Deployments separados (DevOps flexible)
- Responsabilidades claras
- Fácil testing y mantenibilidad
- Equipos autónomos

⚠️ TRADE-OFFS:
- Complejidad en coordinación
- Necesidad de API contracts
- Latencia por HTTP/REST
- Sincronización de datos más compleja
```

**Alternativas consideradas**:
- ❌ Monolito (Simple pero inflexible)
- ❌ Event-driven (Overkill para este proyecto)

---

### 2. Patrón: Layered Architecture (3-Tier)

**Estructura**:
```
Controller (REST)
    ↓
Service (Business Logic)
    ↓
Repository (Data Access)
    ↓
Database
```

**Beneficios**:
- ✅ Separación de responsabilidades clara
- ✅ Testing unitario fácil (mockear cada capa)
- ✅ Reusabilidad de servicios
- ✅ Cambiabilidad (BDD posible)

**Ejemplo**:
```java
// Controller: Mapea HTTP → DTOs → Servicio
@RestController
@RequestMapping("/api/clientes")
public class ClienteController {
    @PostMapping
    public ClienteResponse crear(@RequestBody ClienteRequest req) {
        // DTOs desacoplan HTTP de lógica
        return clienteService.create(req);
    }
}

// Service: Lógica de negocio
@Service
public class ClienteService {
    @Transactional
    public Cliente create(ClienteRequest req) {
        // Validaciones, transformaciones
        Cliente cliente = new Cliente(req.getNombre(), ...);
        return clienteRepository.save(cliente);
    }
}

// Repository: Acceso a datos
@Repository
public interface ClienteRepository extends JpaRepository<Cliente, Long> {}
```

---

### 3. Autenticación: OAuth2 + JWT

**Flujo**:
```
Cliente
  ↓ (user/pass)
Keycloak (OAuth2 Authorization Server)
  ↓ (JWT token)
Cliente (almacena token)
  ↓ (cada request + Bearer token)
Spring Security Filter (valida JWT)
  ↓ (extrae claims)
Controlador
```

**Decisión**: Usar Keycloak como servidor OAuth2 centralizado

**Razones**:
- ✅ Open source y production-ready
- ✅ OAuth2/OIDC compliance
- ✅ Admin console out-of-the-box
- ✅ Soporte para múltiples realms y clientes
- ✅ No almacenar passwords en nuestra app

**Configuración en Spring**:
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://keycloak:8080/realms/tpi-realm
          jwk-set-uri: http://keycloak:8080/realms/tpi-realm/protocol/openid-connect/certs
```

**JWT Token Structure**:
```
eyJhbGciOiJSUzI1NiIsInR5cC5JV1QiLCJraWQiOiI...
 └─ HEADER ──┘
 
eyJzdWIiOiJhZG1pbiIsImV4cCI6MTY5OTUyMzQwMCwibmFtZSI6IkFkbWluIiwiaWF0IjoiMTY5OTUyMzEwMCJ9
 └─ PAYLOAD ──┘ (Claims: subject, expiration, custom fields)
 
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c...
 └─ SIGNATURE ──┘ (RSA256 signed by Keycloak)
```

---

### 4. API Documentation: OpenAPI 3 + Swagger UI

**Decisión**: Documentación automática y testeable

```java
@Operation(summary = "Listar clientes", description = "...")
@ApiResponses(value = {
    @ApiResponse(responseCode = "200", description = "OK"),
    @ApiResponse(responseCode = "401", description = "No autorizado")
})
@GetMapping
public Page<ClienteResponse> listar(...) { ... }
```

**Beneficios**:
- ✅ Documentación siempre sincronizada con código
- ✅ Swagger UI para testing interactivo
- ✅ Spec JSON para integración con otros tools
- ✅ Type safety en DTOs (@Schema)

---

### 5. Database: PostgreSQL 16 + Hibernate

**Decisión**: SQL relacional con ORM

**Schema Normalizado**:
```sql
CLIENTE {id, nombre, email, ...}
    ↓ (1:N)
SOLICITUD {id, cliente_id, estado, ...}
    ↓ (1:N)
TRAMO {id, solicitud_id, origen, destino, ...}
    ↓ (N:1)
CAMION {id, patente, capacidad_tm, ...}

DEPOSITO {id, nombre, capacidad, ...}
```

**ORM Mapping**:
```java
@Entity @Table(name = "cliente")
public class Cliente {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @OneToMany(mappedBy = "cliente", cascade = CascadeType.ALL)
    private List<Solicitud> solicitudes;
}
```

**Alternativas consideradas**:
- ❌ NoSQL (BSON schema: complejidad en queries)
- ❌ In-memory (H2: solo dev)
- ✅ PostgreSQL (Relaciones ACID, proven)

---

### 6. Logging: SLF4J + Logback

**Decisión**: Logging centralizado, structured

**Configuración**:
```xml
<!-- logback.xml -->
<appender name="ASYNC_FILE" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="FILE" />
</appender>

<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>logs/ms-solicitudes.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
        <maxFileSize>10MB</maxFileSize>
        <maxHistory>30</maxHistory>
    </rollingPolicy>
</appender>
```

**Uso en Código**:
```java
@Slf4j
@Service
public class ClienteService {
    public Cliente create(ClienteRequest request) {
        log.info("Creando cliente: {} (email: {})", 
                 request.getNombre(), request.getEmail());
        try {
            // lógica
        } catch (Exception e) {
            log.error("Error creando cliente", e);
        }
    }
}
```

**Niveles**:
- `DEBUG`: Info detallada (dev only)
- `INFO`: Eventos importantes (requests, creaciones)
- `WARN`: Advertencias (config faltante)
- `ERROR`: Excepciones capturadas
- `OFF`: Production (menos I/O)

---

### 7. Testing: Unit Tests + Mockito

**Decisión**: 80%+ coverage en service layer

**Patrón AAA** (Arrange-Act-Assert):
```java
@Test
public void testCreateCliente_Success() {
    // Arrange
    ClienteRequest request = new ClienteRequest("Test", "test@test.com", ...);
    Cliente expected = new Cliente(1L, "Test", ...);
    when(repository.save(any())).thenReturn(expected);
    
    // Act
    Cliente result = service.create(request);
    
    // Assert
    assertEquals("Test", result.getNombre());
    verify(repository, times(1)).save(any());
}
```

**Test Double Strategy**:
```
Real: Controller, Service
Mock: Repository (con cuando(when).thenReturn())
Spy: Verificar interacciones
```

**Alternativas**:
- ❌ Integration tests sin mocks (lento, frágil)
- ✅ Unit tests (rápido, confiable)

---

### 8. DTOs: Request/Response Separation

**Decisión**: No exponer entidades directamente

```java
// ❌ MALO - Exponer entidad directo
@GetMapping
public Cliente obtener(Long id) {
    return repository.findById(id);
}

// ✅ BUENO - DTO separado
@GetMapping
public ClienteResponse obtener(Long id) {
    Cliente entity = repository.findById(id);
    return ClienteResponse.from(entity);
}
```

**Beneficios**:
- ✅ API contract inmutable
- ✅ Evita ciclos JSON
- ✅ Lazy loading seguro
- ✅ Validación en DTOs (@NotNull, @Email, etc)

---

## 🔄 Comunicación Inter-Microservicios

### RestClient: ms-solicitudes → ms-logistica

**Decisión**: HTTP REST con RestTemplate/RestClient

```java
@Component
public class LogisticaRestClient {
    private final RestClient restClient;
    
    public CapacidadResponse verificarCapacidad(String origen, String destino) {
        return restClient.get()
            .uri("http://ms-logistica:8081/api/capacidades")
            .retrieve()
            .body(CapacidadResponse.class);
    }
}
```

**Alternativas consideradas**:
- ❌ gRPC (Overkill, HTTP suficiente)
- ❌ Message Queue (Async: no necesario aún)
- ✅ REST (Simple, debug-friendly)

---

## 🔐 Security Layers

```
1. Transport: HTTPS (TLS 1.3) - Production
   
2. Authentication: OAuth2 JWT
   - Keycloak valida user/password
   - Retorna JWT
   - Cliente enviá Bearer token
   
3. Authorization: Spring Security
   @PreAuthorize("hasRole('ADMIN')")
   public void delete(Long id) { ... }
   
4. Data Validation: Annotations + Custom Validators
   @NotNull, @Email, @Size, etc.
   
5. SQL Injection Prevention: JPA PreparedStatements
   Hibernate automatic
```

---

## 📊 Database Design

### Diagrama ER

```
CLIENTE (id, nombre, email, telefono, direccion, razon_social, cuit)
    ↓ 1:N
SOLICITUD (id, numero_solicitud, cliente_id, estado, fecha_creacion, descripcion)
    ↓ 1:N
TRAMO (id, solicitud_id, numero, origen, destino, distancia, camion_id, estado)
    ↓ N:1
CAMION (id, patente, marca, modelo, año, capacidad_tm, estado, ubicacion)

DEPOSITO (id, nombre, ubicacion, capacidad_contenedores, estado)
    ↓ 1:N
CONTENEDOR (id, numero, tipo, peso, contenido, deposito_id, solicitud_id)
```

### Índices de Performance

```sql
-- Queries frecuentes
CREATE INDEX idx_solicitud_cliente ON solicitud(cliente_id);
CREATE INDEX idx_tramo_solicitud ON tramo(solicitud_id);
CREATE INDEX idx_solicitud_estado ON solicitud(estado);
CREATE INDEX idx_tramo_estado ON tramo(estado);
CREATE INDEX idx_camion_patente ON camion(patente) UNIQUE;
```

---

## 🐳 Containerization Strategy

### Docker Compose

```yaml
version: '3.8'

services:
  ms-solicitudes:
    build:
      context: ./ms-solicitudes
      dockerfile: Dockerfile
    image: tpi:ms-solicitudes-1.0.0
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/tpi_db
      - KEYCLOAK_ISSUER_URI=http://keycloak:8080/realms/tpi-realm
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - keycloak
    healthcheck:
      test: curl --fail http://localhost:8080/ping || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
  
  ms-logistica:
    # Similar...
    ports:
      - "8081:8080"
  
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: tpi_db
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
  
  keycloak:
    image: quay.io/keycloak/keycloak:23.0.7
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin123
    ports:
      - "8090:8080"
    command: start-dev

volumes:
  postgres_data:
```

**Dockerfile (Multistage)**:
```dockerfile
# Build stage
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-Xmx512m", "-jar", "app.jar"]
```

---

## 🚀 Deployment Strategy

### Development
```
Local: JAR directo o via Maven spring-boot:run
Docker Compose: Todos los servicios en mismo host
```

### Staging/Production
```
Cloud options:
- AWS ECS (Container orchestration)
- Azure Container Instances
- Kubernetes (overkill para este scale)
- Docker Swarm (deprecated)

Nginx reverse proxy (443 → 8080 HTTP)
RDS PostgreSQL (managed database)
Keycloak SaaS o self-hosted
```

---

## 🔄 CI/CD Pipeline (Futuro)

```
Push a main
  ↓
[GitHub Actions]
  ├─ mvn clean test (Unit tests)
  ├─ sonarqube (Code quality)
  ├─ docker build & push
  └─ docker-compose pull && docker-compose up
  ↓
[Staging] (Validación manual)
  ↓
[Production] (Manual approval)
```

---

## 📈 Scalability Considerations

### Horizontal Scaling

```
Load Balancer (Nginx/HAProxy)
    ├─ ms-solicitudes:1
    ├─ ms-solicitudes:2
    ├─ ms-solicitudes:3
    └─ ms-solicitudes:N
    
    ├─ ms-logistica:1
    ├─ ms-logistica:2
    └─ ms-logistica:N

PostgreSQL (Replication read-only si needed)
```

### Caching Strategy (Futuro)

```
Redis L1 Cache
├─ JWT tokens validados (5 min)
├─ Clientes frecuentes (30 min)
└─ Depósitos disponibles (1 hour)
```

### Metrics & Monitoring

```
Actuator endpoints
  ├─ /actuator/health
  ├─ /actuator/metrics
  └─ /actuator/prometheus

Prometheus + Grafana (collection + viz)

Alertas
├─ CPU > 80%
├─ Errores > 1%
├─ Response time > 500ms
└─ DB connections > 90%
```

---

## 📝 API Versioning Strategy

**Versión 1 (actual)**: Sin versionado (V1 implícita)

**Futuro**: Si breaking changes
```java
@RestController
@RequestMapping("/api/v2/clientes")
public class ClienteControllerV2 { ... }
```

---

## 🎓 Lecciones Aprendidas

1. **DTO Mapping**: Usar mappers (MapStruct, ModelMapper) para evitar boilerplate
2. **Transaccional**: `@Transactional` en level de servicio, no controller
3. **Exception Handling**: Custom exceptions + Global @ExceptionHandler
4. **Paginación**: Siempre con Pageable (no SELECT *)
5. **Logging**: Structured logging (JSON) para prod

---

## 📚 Referencias & Best Practices

- [Spring Boot Best Practices](https://spring.io/guides)
- [OAuth2 Security Pattern](https://tools.ietf.org/html/rfc6749)
- [OpenAPI 3 Spec](https://spec.openapis.org/oas/v3.0.0)
- [PostgreSQL Optimization](https://wiki.postgresql.org/wiki/Performance_Optimization)

---

**Última actualización**: Noviembre 2025
