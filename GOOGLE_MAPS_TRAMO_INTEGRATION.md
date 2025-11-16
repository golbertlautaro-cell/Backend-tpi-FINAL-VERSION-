# 📊 Integración Google Maps en TramoService - Completada

## 🎯 Objetivo Logrado

Se ha integrado exitosamente `GoogleMapsService` en `TramoService` para utilizar distancias reales de Google Maps en el cálculo de costos y tiempos estimados.

---

## 📦 Archivos Modificados

### 1. **ms-solicitudes/config/RestClientConfig.java**
**Cambios**:
- ✅ Agregado RestClient bean para Google Maps
- ✅ Inyección de `google.maps.base-url` desde configuration

```java
@Bean
public RestClient googleMapsRestClient() {
    return RestClient.builder()
            .baseUrl(googleMapsBaseUrl)
            .build();
}
```

### 2. **ms-solicitudes/service/TramoService.java**
**Cambios**:
- ✅ Inyectado `GoogleMapsService` en constructor
- ✅ Agregado nuevo método `calcularCostoYTiempoEstimadoConGoogleMaps()`
- ✅ Agregado método helper `extraerMinutosDeDuracion()`

---

## 📁 Archivos Creados

### DTOs (ms-solicitudes)
1. ✅ `GoogleDistanceResponse.java` - Mapeo respuesta completa
2. ✅ `GoogleDistanceRow.java` - Mapeo fila de resultados
3. ✅ `GoogleDistanceElement.java` - Mapeo elemento individual
4. ✅ `GoogleDistanceValue.java` - Mapeo valor numérico + texto

### Servicios (ms-solicitudes)
1. ✅ `GoogleMapsService.java` - Servicio de integración con Google Maps

---

## 🔄 Flujo de Integración

```
1. TramoController recibe solicitud para calcular costo
   GET /api/tramos/{id}/calcular-costo?origen=A&destino=B
                        ↓
2. TramoService.calcularCostoYTiempoEstimadoConGoogleMaps()
                        ↓
3. GoogleMapsService.calcularDistancia(origen, destino)
   → Llama a Google Maps Distance Matrix API
   → Deserializa a GoogleDistanceResponse
   → Extrae kilometros y duracion
                        ↓
4. LogisticaClient.obtenerCamion(dominio)
   → Obtiene costoBaseKm del camión
                        ↓
5. Cálculos:
   - costoEstimado = distancia.getKilometros() * costoBaseKm
   - duracionMinutos = extraerMinutosDeDuracion(duracionTexto)
   - fechaFinEstimada = fechaInicio + duracionMinutos
                        ↓
6. TramoRepository.save(tramo)
   → Guarda en BD con valores calculados
                        ↓
7. Retorna Mono<Tramo> con datos actualizados
```

---

## 🔧 Método Nuevo: calcularCostoYTiempoEstimadoConGoogleMaps()

```java
public Mono<Tramo> calcularCostoYTiempoEstimadoConGoogleMaps(
    Long idTramo,
    String origen,
    String destino)
```

### Pasos del algoritmo:

**1. Obtener Tramo**
```java
Tramo tramo = obtener(idTramo);
```

**2. Validar asignación de camión**
```java
if (tramo.getDominioCamion() == null) {
    return error("El tramo no tiene camión asignado");
}
```

**3. Calcular distancia desde Google Maps**
```java
DistanciaDTO distancia = googleMapsService.calcularDistancia(origen, destino);
// distancia.getKilometros() = 704.5
// distancia.getDuracionTexto() = "7 hours 15 mins"
```

**4. Obtener costo base del camión**
```java
Map<String, Object> camion = logisticaClient.obtenerCamion(dominio).block();
double costoBaseKm = (Number) camion.get("costoBaseKm");
```

**5. Calcular costo estimado**
```java
double costoEstimado = distancia.getKilometros() * costoBaseKm;
// 704.5 km * 50 $/km = $35,225
tramo.setCostoAproximado(costoEstimado);
```

**6. Extraer minutos de duración**
```java
long duracionMinutos = extraerMinutosDeDuracion("7 hours 15 mins");
// Resultado: 435 minutos (7*60 + 15)
```

**7. Calcular fechas estimadas**
```java
tramo.setFechaHoraInicioEstimada(LocalDateTime.now());
tramo.setFechaHoraFinEstimada(inicio.plusMinutes(435));
```

**8. Guardar en base de datos**
```java
tramoRepository.save(tramo);
```

---

## 🧮 Método Helper: extraerMinutosDeDuracion()

Convierte textos de duración de Google Maps a minutos:

| Entrada | Salida |
|---------|--------|
| "7 hours 15 mins" | 435 |
| "30 mins" | 30 |
| "2 hours" | 120 |
| "1 hour 45 mins" | 105 |

```java
private long extraerMinutosDeDuracion(String duracionTexto) {
    // Parsea "X hours Y mins" o "X mins" o "X hours"
    // Retorna total en minutos
}
```

---

## ✅ Compilación Exitosa

```
BUILD SUCCESS
- Archivos compilados: 42
- Recursos: 2
- Tiempo: 11.696 segundos
- Errores: 0
- Advertencias: 0
```

---

## 🧪 Cómo Usar el Nuevo Método

### Endpoint (Ejemplo)
```bash
POST /api/tramos/{id}/calcular-costo-google-maps
Content-Type: application/json

{
  "origen": "Buenos Aires, Argentina",
  "destino": "Córdoba, Argentina"
}
```

### En el Controlador
```java
@PostMapping("/{id}/calcular-costo-google-maps")
public Mono<Tramo> calcularCosto(
    @PathVariable Long id,
    @RequestParam String origen,
    @RequestParam String destino) {
    return tramoService.calcularCostoYTiempoEstimadoConGoogleMaps(id, origen, destino);
}
```

### Respuesta Esperada
```json
{
  "idTramo": 1,
  "origen": "Buenos Aires",
  "destino": "Córdoba",
  "costoAproximado": 35225.0,
  "fechaHoraInicioEstimada": "2025-11-10T21:30:00",
  "fechaHoraFinEstimada": "2025-11-11T04:45:00",
  "estado": "ASIGNADO",
  "dominioCamion": "ABC123"
}
```

---

## 📋 Comparativa: Antiguo vs Nuevo

### ❌ Antiguo: calcularCostoYTiempoEstimado()
```java
// Requería coordenadas lat/lng
public Mono<Tramo> calcularCostoYTiempoEstimado(
    Long idTramo,
    double origenLat, double origenLng,
    double destinoLat, double destinoLng)

// Usaba GoogleMapsClient (posiblemente WebClient)
googleMapsClient.obtenerDistanciaYDuracion(lat, lng, lat, lng)
```

### ✅ Nuevo: calcularCostoYTiempoEstimadoConGoogleMaps()
```java
// Acepta direcciones texto
public Mono<Tramo> calcularCostoYTiempoEstimadoConGoogleMaps(
    Long idTramo,
    String origen,
    String destino)

// Usa GoogleMapsService directo
googleMapsService.calcularDistancia(origen, destino)

// ✨ Ventajas:
// - Más flexible (acepta direcciones)
// - Type-safe (DTOs deserializados)
// - Manejo de errores mejorado
// - Logging detallado
// - Parser de duración integrado
```

---

## 🔐 Configuración Requerida

En `ms-solicitudes/application.yml`:

```yaml
google:
  maps:
    api-key: TU_API_KEY_REAL_AQUI
    base-url: https://maps.googleapis.com/maps/api

services:
  logistica:
    url: http://localhost:8081
```

---

## 📊 Inyecciones de Dependencias

### En TramoService:
```java
@Service
public class TramoService {
    // ✅ Anteriores
    private final TramoRepository tramoRepository;
    private final SolicitudRepository solicitudRepository;
    private final LogisticaClient logisticaClient;
    private final GoogleMapsClient googleMapsClient;
    
    // ✅ NUEVO
    private final GoogleMapsService googleMapsService;
    
    public TramoService(..., GoogleMapsService googleMapsService) {
        // ...
        this.googleMapsService = googleMapsService;
    }
}
```

---

## 🎯 Ventajas de Esta Integración

✅ **Distancias reales**: Usa Google Maps en lugar de aproximaciones  
✅ **Dirección como texto**: No requiere coordenadas  
✅ **Type-safe**: DTOs validados automáticamente  
✅ **Manejo robusto**: Validación de respuestas  
✅ **Logging completo**: Rastreo de errores  
✅ **Reutilizable**: GoogleMapsService en otros servicios  
✅ **Flexible**: Soporta direcciones completas o coordenadas  
✅ **Tiempo estimado**: Extrae duración de Google  

---

## ⚠️ Consideraciones

1. **API Limits**: Google Maps tiene límites de solicitudes
2. **Costo**: Las solicitudes tienen costo según plan
3. **Validación**: Verificar que direcciones sean válidas
4. **Caché**: Considerar cachear resultados frecuentes
5. **Fallback**: Tener método alternativo si Google falla

---

## 🚀 Próximos Pasos

1. ✅ Crear controlador REST para exponer el nuevo método
2. ✅ Implementar tests para GoogleMapsService
3. ✅ Agregar caché para evitar llamadas repetidas
4. ✅ Implementar retry/fallback si falla Google Maps
5. ✅ Integrar en flujo de creación de tramos

---

## 📝 Resumen de Cambios

| Archivo | Tipo | Estado |
|---------|------|--------|
| RestClientConfig.java | Modified | ✅ |
| TramoService.java | Modified | ✅ |
| GoogleMapsService.java | Created | ✅ |
| GoogleDistanceResponse.java | Created | ✅ |
| GoogleDistanceRow.java | Created | ✅ |
| GoogleDistanceElement.java | Created | ✅ |
| GoogleDistanceValue.java | Created | ✅ |
| **Total** | **7 archivos** | **✅ Completado** |

---

**Status**: 🎉 INTEGRACIÓN COMPLETADA Y COMPILADA  
**Compilación**: ✅ BUILD SUCCESS  
**Archivo**: ms-solicitudes (42 fuentes, 0 errores)

