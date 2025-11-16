# PHASE 3 - Tests Unitarios e Integración

## Objetivo
Implementar una cobertura completa de tests unitarios e integración para garantizar calidad, mantenibilidad y confiabilidad del código.

## Estrategia de Testing

### 1. Tests Unitarios (Unit Tests)
- **Enfoque**: Probar componentes individuales de forma aislada
- **Herramientas**: JUnit 5, Mockito
- **Cobertura**: Services, Utilities, Validators
- **Características**:
  - Mocks de dependencias externas (repositories, clientes HTTP)
  - Tests rápidos (< 1s por test)
  - Tests independientes

### 2. Tests de Integración
- **Enfoque**: Probar flujos completos entre componentes
- **Herramientas**: Spring Boot Test, MockMvc
- **Cobertura**: Controllers, Services con persistencia
- **Características**:
  - Contexto completo de Spring
  - Base de datos embebida (H2)
  - Tests más lentos pero más realistas

### 3. Tests E2E
- **Enfoque**: Validar flujos completos del sistema
- **Herramientas**: Postman/Validation Scripts
- **Cobertura**: APIs públicas, autenticación, flujos de negocio
- **Características**:
  - Servicios reales ejecutándose
  - Datos persistentes
  - Validación de comportamiento completo

## Estructura de Tests

### ms-solicitudes

```
src/test/java/com/tpi/solicitudes/
├── service/
│   ├── ClienteServiceTest.java      ✅ CREADO
│   ├── SolicitudServiceTest.java    ✅ CREADO
│   ├── TramoServiceTest.java        📝 TODO
│   └── DepositoServiceTest.java     📝 TODO
├── web/
│   ├── ClienteControllerTest.java   ✅ CREADO
│   ├── SolicitudControllerTest.java 📝 TODO
│   ├── TramoControllerTest.java     📝 TODO
│   └── DepositoControllerTest.java  📝 TODO
└── util/
    └── DateUtilTest.java            📝 TODO
```

### ms-logistica

```
src/test/java/com/tpi/logistica/
├── service/
│   └── CamionServiceTest.java       ✅ EXISTE
├── web/
│   └── CamionControllerTest.java    📝 TODO
└── util/
    └── ContenedorUtilTest.java      📝 TODO
```

## Tests Implementados

### 1. ClienteServiceTest
**Ubicación**: `ms-solicitudes/src/test/java/.../service/ClienteServiceTest.java`

**Tests**:
- ✅ `testFindById()` - Obtener cliente por ID
- ✅ `testFindByIdNotFound()` - Cliente no existe
- ✅ `testFindAll()` - Listar clientes paginados
- ✅ `testCreateCliente()` - Crear nuevo cliente
- ✅ `testUpdateCliente()` - Actualizar cliente
- ✅ `testDeleteCliente()` - Eliminar cliente

**Tipo**: Unit Test con Mockito
**Cobertura**: Métodos principales del service

### 2. SolicitudServiceTest
**Ubicación**: `ms-solicitudes/src/test/java/.../service/SolicitudServiceTest.java`

**Tests**:
- ✅ `testFindById()` - Obtener solicitud por ID
- ✅ `testFindByIdNotFound()` - Lanza excepción si no existe
- ✅ `testFindAll()` - Listar solicitudes paginadas
- ✅ `testCreateSolicitud()` - Crear nueva solicitud
- ✅ `testUpdateSolicitudStatus()` - Actualizar estado
- ✅ `testDeleteSolicitud()` - Eliminar solicitud

**Tipo**: Unit Test con Mockito
**Cobertura**: Lógica de negocio de solicitudes

### 3. ClienteControllerTest
**Ubicación**: `ms-solicitudes/src/test/java/.../web/ClienteControllerTest.java`

**Tests**:
- ✅ `testListarClientes()` - GET /api/clientes
- ✅ `testObtenerClienteById()` - GET /api/clientes/{id}
- ✅ `testCrearCliente()` - POST /api/clientes

**Tipo**: Integration Test con MockMvc
**Cobertura**: Endpoints REST del controller

## Configuración de Dependencias (pom.xml)

Dependencias necesarias para tests:

```xml
<!-- JUnit 5 -->
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>

<!-- Mockito -->
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>

<!-- Spring Boot Test -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>

<!-- H2 Database (para tests) -->
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>test</scope>
</dependency>
```

## Ejecución de Tests

### Ejecutar todos los tests
```bash
cd ms-solicitudes
mvn test

cd ms-logistica
mvn test
```

### Ejecutar tests de una clase específica
```bash
mvn test -Dtest=ClienteServiceTest
mvn test -Dtest=ClienteControllerTest
```

### Ejecutar un test específico
```bash
mvn test -Dtest=ClienteServiceTest#testFindById
```

### Con cobertura de código (JaCoCo)
```bash
mvn test jacoco:report
# Reporte en: target/site/jacoco/index.html
```

## Convenciones de Naming

### Test Classes
- Sufijo: `Test`
- Ejemplo: `ClienteServiceTest`, `ClienteControllerTest`

### Test Methods
- Prefijo: `test`
- Descripción clara: `testFindById`, `testFindByIdNotFound`
- DisplayName: `@DisplayName("Descripción clara del test")`

### Assertions
- JUnit 5: `assertEquals()`, `assertNotNull()`, `assertTrue()`
- Mockito: `verify()`, `when()`, `doReturn()`

## Patrón AAA (Arrange-Act-Assert)

Todos los tests siguen este patrón:

```java
@Test
void testExample() {
    // Arrange - Preparar datos y mocks
    when(repository.findById(1L)).thenReturn(Optional.of(entity));
    
    // Act - Ejecutar la acción
    Entity result = service.findById(1L);
    
    // Assert - Verificar resultados
    assertNotNull(result);
    assertEquals(1L, result.getId());
    verify(repository, times(1)).findById(1L);
}
```

## Próximos Pasos

### Fase 3.1 - Completar Tests Unitarios
- [ ] TramoServiceTest
- [ ] DepositoServiceTest
- [ ] SolicitudControllerTest
- [ ] TramoControllerTest
- [ ] DepositoControllerTest
- [ ] CamionControllerTest

### Fase 3.2 - Tests de Integración Avanzados
- [ ] ControllerIntegrationTests (POST, PUT, DELETE)
- [ ] ServiceIntegrationTests (con base de datos)
- [ ] TestContainers para PostgreSQL real

### Fase 3.3 - Cobertura de Código
- [ ] Configurar JaCoCo para medir cobertura
- [ ] Target: >= 80% de cobertura
- [ ] Generar reportes

### Fase 3.4 - Tests de Seguridad
- [ ] OAuth2 token validation tests
- [ ] Authorization tests por roles
- [ ] CORS configuration tests

### Fase 3.5 - Performance Tests
- [ ] Load testing con JMeter
- [ ] Stress testing
- [ ] Latency measurements

## Ejecución Recomendada

1. **Desarrollo**: Tests unitarios rápidos (Ctrl+Shift+F10)
2. **Pre-commit**: Tests unitarios + integración
3. **CI/CD**: Suite completa de tests
4. **Producción**: Validación E2E en ambiente staging

## Archivos Creados

✅ Estructura de directorios:
- `src/test/java/com/tpi/solicitudes/service/`
- `src/test/java/com/tpi/solicitudes/web/`
- `src/test/java/com/tpi/logistica/web/`

✅ Tests implementados:
- `ClienteServiceTest.java` (6 tests)
- `SolicitudServiceTest.java` (6 tests)
- `ClienteControllerTest.java` (3 tests)

📝 Total: 15 tests implementados

## Comandos Útiles

```bash
# Ejecutar tests
mvn test

# Generar cobertura
mvn test jacoco:report

# Ejecutar con output verbose
mvn test -X

# Saltar tests
mvn clean package -DskipTests

# Ejecutar solo tests
mvn test -DskipITs=false

# Debug de tests
mvn test -Dtest=ClienteServiceTest -X -e
```

## Status Actual

✅ **Completado**:
- Fase 1: Swagger, DTOs, RestClient
- Fase 2: Logging Estructurado con Logback
- E2E Authentication con JWT/Keycloak
- Tests Unitarios básicos (15 tests)

⏳ **En Progreso**:
- Fase 3.1: Completar suite de tests unitarios
- Fase 3.2: Tests de integración avanzados

📋 **Pendiente**:
- Fase 3.3: Cobertura de código (JaCoCo)
- Fase 3.4: Tests de seguridad
- Fase 3.5: Performance tests

