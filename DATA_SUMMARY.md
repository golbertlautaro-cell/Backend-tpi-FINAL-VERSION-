# 📊 Resumen de Datos del Proyecto Backend-TP2

## 🗄️ Base de Datos: `solicitudes_db`

### ✅ Tabla: `clientes` (20 registros)
| ID | Nombre | Email | Teléfono | Dirección |
|---|---|---|---|---|
| 1-20 | Cliente 1-20 | cliente1@example.com - cliente20@example.com | 11440001-11440020 | Calle 1-20, Buenos Aires |

### ✅ Tabla: `solicitudes` (20 registros)
| Nro | ID Cliente | Estado | Costo Estimado | Costo Final | ID Contenedor | Tiempo Real | Fecha Creación |
|---|---|---|---|---|---|---|---|
| 1 | 1 | PROGRAMADA | 160.50 | 176.75 | 1001 | 35 min | 2025-11-11 01:50:08 |
| 2 | 2 | PROGRAMADA | 170.50 | 187.75 | 1002 | 40 min | 2025-11-11 01:51:08 |
| ... | ... | ... | ... | ... | ... | ... | ... |
| 20 | 20 | PROGRAMADA | 350.50 | 386.75 | 1020 | 130 min | 2025-11-11 02:09:08 |

**Fórmulas aplicadas:**
- `costo_estimado = 150.50 + (nro_solicitud * 10)`
- `costo_final = 165.75 + (nro_solicitud * 11)`
- `id_contenedor = nro_solicitud + 1000`
- `tiempo_real = (30 + (nro_solicitud * 5))`
- `fecha_actualizacion = fecha_creacion + 1 día`

### ✅ Tabla: `tramos` (20 registros)
| ID Tramo | Nro Solicitud | Origen | Destino | Tipo | Estado | Costo Aprox | Dominio Camión |
|---|---|---|---|---|---|---|---|
| 1 | 1 | Buenos Aires Centro | La Plata | RECOGIDA | ASIGNADO | 105.00 | DOM-002 |
| 2 | 2 | Buenos Aires Centro | La Plata | RECOGIDA | FINALIZADO | 110.00 | DOM-003 |
| 3 | 3 | Buenos Aires Centro | La Plata | ENTREGA | ASIGNADO | 115.00 | DOM-004 |
| ... | ... | ... | ... | ... | ... | ... | ... |
| 20 | 20 | Buenos Aires Centro | La Plata | RECOGIDA | FINALIZADO | 200.00 | DOM-001 |

**Características:**
- Tipo: RECOGIDA (80%), ENTREGA (20%)
- Estado: ASIGNADO (50%), FINALIZADO (50%)
- Tiempos: fechas simuladas con 30 min de inicio, 85 min real
- Odómetro: 86000 - 106000 km
- Costo Real: 115.50 - 210.50 $

---

## 🗄️ Base de Datos: `logistica_db`

### ✅ Tabla: `camiones` (20 registros)
| Dominio | Capacidad Peso | Capacidad Volumen | Consumo Promedio | Costo Base/km | Transportista | Disponible |
|---|---|---|---|---|---|---|
| DOM-001 | 2050 kg | 16 m³ | 4.1 l/km | 8.1 $ | Transporte 1 | No |
| DOM-002 | 2100 kg | 17 m³ | 4.2 l/km | 8.2 $ | Transporte 2 | Sí |
| ... | ... | ... | ... | ... | ... | ... |
| DOM-020 | 3000 kg | 35 m³ | 4.0 l/km | 8.0 $ | Transporte 20 | Sí |

**Disponibilidad:** Alternada (10 disponibles, 10 no disponibles)

### ✅ Tabla: `depositos` (10 registros)
| ID | Nombre | Dirección | Latitud | Longitud | Costo Diario |
|---|---|---|---|---|---|
| 1 | Deposito 1 | Calle 1, Buenos Aires | -34.59 | -58.39 | 101 $ |
| 2 | Deposito 2 | Calle 2, Buenos Aires | -34.58 | -58.40 | 102 $ |
| ... | ... | ... | ... | ... | ... |
| 10 | Deposito 10 | Calle 10, Buenos Aires | -34.50 | -58.48 | 110 $ |

---

## 📝 Endpoints Disponibles (GET sin autenticación)

### ms-solicitudes (Puerto 8080)
- ✅ `GET /api/solicitudes` - Listar solicitudes paginadas
- ✅ `GET /api/solicitudes/{id}` - Obtener solicitud por ID
- ✅ `GET /api/tramos` - Listar tramos paginados
- ✅ `GET /api/tramos/{id}` - Obtener tramo por ID
- ✅ `GET /api/clientes` - Listar clientes paginados
- ✅ `GET /api/clientes/{id}` - Obtener cliente por ID
- ✅ `GET /swagger-ui.html` - Documentación interactiva

### ms-logistica (Puerto 8081)
- ✅ `GET /api/camiones` - Listar camiones
- ✅ `GET /api/camiones/{dominio}` - Obtener camión por dominio
- ✅ `GET /api/distancia?origen=X&destino=Y` - Calcular distancia con Google Maps
- ✅ `GET /swagger-ui.html` - Documentación interactiva

---

## 🔧 Detalles de la Implementación

### Docker Compose Stack
```
✅ tpi-postgres      - PostgreSQL 16 (Puerto 5432)
✅ keycloak-tpi      - Keycloak (Puerto 8090)
✅ ms-solicitudes    - Spring Boot (Puerto 8080)
✅ ms-logistica      - Spring Boot (Puerto 8081)
```

### Volumen de Datos
- **Volumen:** `backend1_postgres_data`
- **Tipo:** Persistente (sobrevive reinicios de contenedores)
- **Ubicación dentro del contenedor:** `/var/lib/postgresql/data`

### Seguridad (GET públicos, POST/PUT requieren JWT)
- GET endpoints: Sin autenticación
- POST/PUT/DELETE endpoints: Requieren token JWT desde Keycloak

---

## 📈 Estadísticas Totales

| Concepto | Cantidad |
|---|---|
| **Clientes** | 20 |
| **Solicitudes** | 20 |
| **Tramos** | 20 |
| **Camiones** | 20 |
| **Depósitos** | 10 |
| **Total de registros** | 70 |

---

## 🎯 Próximos Pasos Opcionales

1. **Agregar más datos:** Aumentar de 20 a 100+ registros por entidad
2. **Script de inicialización:** Crear `data.sql` para que se carguen automáticamente
3. **Relaciones cruzadas:** Agregar más interacciones entre solicitudes y tramos
4. **Datos de prueba realistas:** Usar direcciones reales y Google Maps para distancias
5. **Commit a Git:** Guardar cambios en el repositorio

---

**Última actualización:** 2025-11-10
**Generado por:** GitHub Copilot
