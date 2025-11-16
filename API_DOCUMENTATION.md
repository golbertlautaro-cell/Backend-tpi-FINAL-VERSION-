# 📖 API Documentation - Especificación Completa

**Versión**: 1.0.0 | **Stack**: Spring Boot 3.3.5 + OpenAPI 3 | **Última actualización**: Noviembre 2025

---

## 🔐 Autenticación

### Obtener Token JWT

**Endpoint**: `POST /realms/{realm}/protocol/openid-connect/token`

**Host**: Keycloak (http://localhost:8090)

**Headers**:
```
Content-Type: application/x-www-form-urlencoded
```

**Body**:
```
client_id=tpi-app
username=admin
password=admin123
grant_type=password
```

**Response (200 OK)**:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cC...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "token_type": "Bearer",
  "not-before-policy": 0,
  "scope": "profile email"
}
```

### Usar Token en Requests

**Header**:
```
Authorization: Bearer <access_token>
```

**Ejemplo cURL**:
```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIs..." \
  http://localhost:8080/api/clientes
```

---

## 📌 ms-solicitudes (Puerto 8080)

### Clientes

#### 1️⃣ Listar Clientes (con paginación)

```
GET /api/clientes
```

**Headers**:
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Query Parameters**:
| Parámetro | Tipo | Descripción |
|-----------|------|---|
| page | int | Número de página (0-indexed) |
| size | int | Elementos por página (default: 20) |
| sort | String | Campo para ordenar (ej: "nombre,asc") |

**Response (200 OK)**:
```json
{
  "content": [
    {
      "id": 1,
      "nombre": "Empresa XYZ",
      "email": "contacto@empresaxyz.com",
      "telefono": "1234567890",
      "direccion": "Av. Principal 123",
      "razonSocial": "XYZ S.A.",
      "cuit": "20123456789"
    }
  ],
  "pageable": {
    "sort": {
      "empty": false,
      "sorted": true,
      "unsorted": false
    },
    "offset": 0,
    "pageNumber": 0,
    "pageSize": 20,
    "paged": true,
    "unpaged": false
  },
  "totalPages": 5,
  "totalElements": 95,
  "last": false,
  "size": 20,
  "number": 0,
  "sort": {
    "empty": false,
    "sorted": true,
    "unsorted": false
  },
  "first": true,
  "numberOfElements": 20,
  "empty": false
}
```

**Response (401 Unauthorized)**:
```json
{
  "error": "unauthorized",
  "error_description": "Token inválido o expirado"
}
```

---

#### 2️⃣ Obtener Cliente por ID

```
GET /api/clientes/{id}
```

**Path Parameters**:
| Parámetro | Tipo | Descripción |
|-----------|------|---|
| id | Long | ID del cliente |

**Response (200 OK)**:
```json
{
  "id": 1,
  "nombre": "Empresa XYZ",
  "email": "contacto@empresaxyz.com",
  "telefono": "1234567890",
  "direccion": "Av. Principal 123",
  "razonSocial": "XYZ S.A.",
  "cuit": "20123456789"
}
```

**Response (404 Not Found)**:
```json
{
  "error": "NOT_FOUND",
  "message": "Cliente con ID 999 no encontrado"
}
```

---

#### 3️⃣ Crear Cliente

```
POST /api/clientes
```

**Headers**:
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "nombre": "Nueva Empresa",
  "email": "new@empresa.com",
  "telefono": "9876543210",
  "direccion": "Calle Secundaria 456",
  "razonSocial": "Nueva Empresa S.A.",
  "cuit": "20987654321"
}
```

**Response (201 Created)**:
```json
{
  "id": 12,
  "nombre": "Nueva Empresa",
  "email": "new@empresa.com",
  "telefono": "9876543210",
  "direccion": "Calle Secundaria 456",
  "razonSocial": "Nueva Empresa S.A.",
  "cuit": "20987654321"
}
```

**Response (400 Bad Request)**:
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Email inválido",
  "details": {
    "email": "Debe ser un email válido"
  }
}
```

---

#### 4️⃣ Actualizar Cliente

```
PUT /api/clientes/{id}
```

**Path Parameters**:
| Parámetro | Tipo | Descripción |
|-----------|------|---|
| id | Long | ID del cliente |

**Request Body**:
```json
{
  "nombre": "Empresa Actualizada",
  "email": "updated@empresa.com",
  "telefono": "5555555555",
  "direccion": "Nueva Dirección 789",
  "razonSocial": "Empresa Actualizada S.A.",
  "cuit": "20555555555"
}
```

**Response (200 OK)**:
```json
{
  "id": 12,
  "nombre": "Empresa Actualizada",
  "email": "updated@empresa.com",
  "telefono": "5555555555",
  "direccion": "Nueva Dirección 789",
  "razonSocial": "Empresa Actualizada S.A.",
  "cuit": "20555555555"
}
```

---

#### 5️⃣ Eliminar Cliente

```
DELETE /api/clientes/{id}
```

**Path Parameters**:
| Parámetro | Tipo | Descripción |
|-----------|------|---|
| id | Long | ID del cliente |

**Response (204 No Content)**:
```
(sin body)
```

**Response (404 Not Found)**:
```json
{
  "error": "NOT_FOUND",
  "message": "Cliente con ID 999 no encontrado"
}
```

---

### Solicitudes

#### 1️⃣ Listar Solicitudes

```
GET /api/solicitudes
```

**Query Parameters**:
| Parámetro | Tipo | Descripción |
|-----------|------|---|
| page | int | Número de página |
| size | int | Elementos por página |
| estado | String | Filtro: PENDIENTE, EN_PROCESO, COMPLETADA, CANCELADA |

**Response (200 OK)**:
```json
{
  "content": [
    {
      "id": 1,
      "numeroSolicitud": "SOL-2025-001",
      "clienteId": 1,
      "clienteNombre": "Empresa XYZ",
      "estado": "EN_PROCESO",
      "fechaCreacion": "2025-11-09T10:30:00Z",
      "fechaActualizacion": "2025-11-09T11:00:00Z",
      "descripcion": "Transporte de mercaderías a Córdoba"
    }
  ],
  "pageable": {
    "offset": 0,
    "pageNumber": 0,
    "pageSize": 20,
    "paged": true
  },
  "totalPages": 3,
  "totalElements": 45,
  "last": false
}
```

---

#### 2️⃣ Obtener Solicitud por ID

```
GET /api/solicitudes/{id}
```

**Response (200 OK)**:
```json
{
  "id": 1,
  "numeroSolicitud": "SOL-2025-001",
  "clienteId": 1,
  "clienteNombre": "Empresa XYZ",
  "estado": "EN_PROCESO",
  "fechaCreacion": "2025-11-09T10:30:00Z",
  "fechaActualizacion": "2025-11-09T11:00:00Z",
  "descripcion": "Transporte de mercaderías a Córdoba",
  "tramos": [
    {
      "id": 1,
      "numero": 1,
      "origen": "Buenos Aires",
      "destino": "Córdoba",
      "distancia": 650,
      "estado": "EN_TRANSITO"
    }
  ]
}
```

---

#### 3️⃣ Crear Solicitud

```
POST /api/solicitudes
```

**Request Body**:
```json
{
  "clienteId": 1,
  "descripcion": "Transporte de mercaderías frágiles",
  "origen": "Buenos Aires",
  "destino": "Mendoza",
  "contenedores": [
    {
      "numero": "CNT-001",
      "tipo": "CONTENEDOR_20",
      "peso": 5000,
      "contenido": "Electrodomésticos"
    }
  ]
}
```

**Response (201 Created)**:
```json
{
  "id": 45,
  "numeroSolicitud": "SOL-2025-045",
  "clienteId": 1,
  "estado": "PENDIENTE",
  "fechaCreacion": "2025-11-09T12:00:00Z"
}
```

---

#### 4️⃣ Actualizar Estado de Solicitud

```
PUT /api/solicitudes/{id}
```

**Request Body**:
```json
{
  "estado": "COMPLETADA",
  "notas": "Entrega realizada correctamente"
}
```

**Response (200 OK)**:
```json
{
  "id": 45,
  "numeroSolicitud": "SOL-2025-045",
  "estado": "COMPLETADA",
  "fechaActualizacion": "2025-11-09T15:30:00Z"
}
```

---

#### 5️⃣ Listar Tramos de una Solicitud

```
GET /api/solicitudes/{id}/tramos
```

**Response (200 OK)**:
```json
{
  "content": [
    {
      "id": 1,
      "numero": 1,
      "origen": "Buenos Aires",
      "destino": "Córdoba",
      "distancia": 650,
      "camionId": 5,
      "camionPatente": "ABC-123",
      "estado": "EN_TRANSITO",
      "fechaSalida": "2025-11-09T08:00:00Z"
    },
    {
      "id": 2,
      "numero": 2,
      "origen": "Córdoba",
      "destino": "Mendoza",
      "distancia": 450,
      "camionId": null,
      "estado": "PENDIENTE"
    }
  ]
}
```

---

### Tramos

#### 1️⃣ Listar Tramos

```
GET /api/tramos
```

**Query Parameters**:
| Parámetro | Tipo | Descripción |
|-----------|------|---|
| page | int | Número de página |
| size | int | Elementos por página |
| estado | String | PENDIENTE, EN_TRANSITO, COMPLETADO |

**Response (200 OK)**:
```json
{
  "content": [
    {
      "id": 1,
      "solicitudId": 1,
      "numero": 1,
      "origen": "Buenos Aires",
      "destino": "Córdoba",
      "distancia": 650,
      "estado": "EN_TRANSITO"
    }
  ],
  "totalElements": 25,
  "totalPages": 2
}
```

---

#### 2️⃣ Crear Tramo

```
POST /api/tramos
```

**Request Body**:
```json
{
  "solicitudId": 1,
  "numero": 2,
  "origen": "Córdoba",
  "destino": "Mendoza",
  "distancia": 450,
  "contenedores": [1, 2, 3]
}
```

**Response (201 Created)**:
```json
{
  "id": 25,
  "solicitudId": 1,
  "numero": 2,
  "estado": "PENDIENTE",
  "fechaCreacion": "2025-11-09T12:30:00Z"
}
```

---

## 🚚 ms-logistica (Puerto 8081)

### Camiones

#### 1️⃣ Listar Camiones

```
GET /api/camiones
```

**Response (200 OK)**:
```json
{
  "content": [
    {
      "id": 1,
      "patente": "ABC-123",
      "marca": "Scania",
      "modelo": "R440",
      "año": 2022,
      "capacidadTm": 25,
      "estado": "DISPONIBLE",
      "ubicacion": "Buenos Aires"
    }
  ],
  "totalElements": 15
}
```

---

#### 2️⃣ Crear Camión

```
POST /api/camiones
```

**Request Body**:
```json
{
  "patente": "XYZ-789",
  "marca": "Volvo",
  "modelo": "FH16",
  "año": 2023,
  "capacidadTm": 30,
  "ubicacion": "Buenos Aires"
}
```

**Response (201 Created)**:
```json
{
  "id": 16,
  "patente": "XYZ-789",
  "estado": "DISPONIBLE"
}
```

---

### Depósitos

#### 1️⃣ Listar Depósitos

```
GET /api/depositos
```

**Response (200 OK)**:
```json
{
  "content": [
    {
      "id": 1,
      "nombre": "Depósito Buenos Aires",
      "ubicacion": "Avenida 9 de Julio 1000",
      "capacidadContenedores": 500,
      "contenedoresActuales": 150,
      "estado": "OPERATIVO"
    }
  ]
}
```

---

### Capacidades

#### 1️⃣ Obtener Capacidades Disponibles

```
GET /api/capacidades
```

**Query Parameters**:
| Parámetro | Tipo | Descripción |
|-----------|------|---|
| origen | String | Ciudad origen |
| destino | String | Ciudad destino |
| fecha | String | Fecha requerida (YYYY-MM-DD) |

**Response (200 OK)**:
```json
{
  "disponibles": [
    {
      "camionId": 1,
      "patente": "ABC-123",
      "capacidadDisponible": 8,
      "proximaSalida": "2025-11-09T06:00:00Z"
    },
    {
      "camionId": 3,
      "patente": "DEF-456",
      "capacidadDisponible": 15,
      "proximaSalida": "2025-11-10T06:00:00Z"
    }
  ]
}
```

---

## 🆘 Códigos de Error

### 400 Bad Request
```json
{
  "timestamp": "2025-11-09T12:00:00Z",
  "status": 400,
  "error": "VALIDATION_ERROR",
  "message": "Datos de entrada inválidos",
  "details": {
    "email": "Email debe ser válido",
    "nombre": "Nombre no puede estar vacío"
  }
}
```

### 401 Unauthorized
```json
{
  "timestamp": "2025-11-09T12:00:00Z",
  "status": 401,
  "error": "UNAUTHORIZED",
  "message": "Token inválido, expirado o ausente"
}
```

### 403 Forbidden
```json
{
  "timestamp": "2025-11-09T12:00:00Z",
  "status": 403,
  "error": "FORBIDDEN",
  "message": "No tiene permisos para acceder a este recurso"
}
```

### 404 Not Found
```json
{
  "timestamp": "2025-11-09T12:00:00Z",
  "status": 404,
  "error": "NOT_FOUND",
  "message": "Recurso no encontrado"
}
```

### 500 Internal Server Error
```json
{
  "timestamp": "2025-11-09T12:00:00Z",
  "status": 500,
  "error": "INTERNAL_SERVER_ERROR",
  "message": "Error interno del servidor",
  "traceId": "abc123def456"
}
```

---

## 🔄 Rate Limiting (Futuro)

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1699523400
```

**Límites**:
- 1000 requests/hora (usuarios autenticados)
- 100 requests/hora (sin autenticar)

---

## 📊 Modelos de Datos

### Cliente
```json
{
  "id": 1,
  "nombre": "string (max 100)",
  "email": "string (email válido)",
  "telefono": "string",
  "direccion": "string",
  "razonSocial": "string",
  "cuit": "string (11 dígitos)"
}
```

### Solicitud
```json
{
  "id": 1,
  "numeroSolicitud": "string (auto-generated)",
  "clienteId": 1,
  "estado": "PENDIENTE|EN_PROCESO|COMPLETADA|CANCELADA",
  "fechaCreacion": "ISO 8601 timestamp",
  "fechaActualizacion": "ISO 8601 timestamp",
  "descripcion": "string"
}
```

### Tramo
```json
{
  "id": 1,
  "solicitudId": 1,
  "numero": 1,
  "origen": "string",
  "destino": "string",
  "distancia": "número (km)",
  "estado": "PENDIENTE|EN_TRANSITO|COMPLETADO"
}
```

### Camión
```json
{
  "id": 1,
  "patente": "string (único)",
  "marca": "string",
  "modelo": "string",
  "año": "número",
  "capacidadTm": "número",
  "estado": "DISPONIBLE|EN_USO|MANTENIMIENTO"
}
```

---

## 🧪 Testing API

### Con Postman

1. Importar colección desde `/postman/TPI-API.json`
2. Configurar variable: `base_url = http://localhost:8080`
3. Ejecutar colección

### Con cURL

```bash
# Script de prueba
#!/bin/bash

# 1. Obtener token
TOKEN=$(curl -s -X POST http://localhost:8090/realms/tpi-realm/protocol/openid-connect/token \
  -d "client_id=tpi-app&username=admin&password=admin123&grant_type=password" \
  -d "Content-Type=application/x-www-form-urlencoded" | jq -r '.access_token')

# 2. Listar clientes
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/clientes

# 3. Crear cliente
curl -X POST http://localhost:8080/api/clientes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Test Empresa",
    "email": "test@empresa.com",
    "telefono": "1234567890",
    "direccion": "Calle Test 123",
    "razonSocial": "Test S.A.",
    "cuit": "20123456789"
  }'
```

---

**Última actualización**: Noviembre 2025
