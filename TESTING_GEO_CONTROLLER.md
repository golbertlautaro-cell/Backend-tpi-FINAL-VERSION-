# Guía de Prueba - GeoController (Integración Google Maps)

## 📝 Descripción

Este documento proporciona instrucciones para probar la integración de Google Maps en ms-logistica a través del controlador temporal `GeoController`.

## 🚀 Requisitos Previos

1. **API Key de Google Maps**: Necesitas una API key válida
   - Accede a [Google Cloud Console](https://console.cloud.google.com/)
   - Habilita "Maps SDK for Android" y "Distance Matrix API"
   - Crea una credencial de tipo API Key
   - Reemplaza `PEGA_TU_API_KEY_AQUI` en `application.yml`

2. **Servicio ejecutándose**:
   ```bash
   cd ms-logistica
   mvn spring-boot:run
   ```

3. **Herramienta de prueba** (una de):
   - Postman
   - curl (terminal)
   - Swagger UI

## 🔧 Configuración

### application.yml (ms-logistica)
```yaml
google:
  maps:
    api-key: TU_CLAVE_REAL_AQUI
    base-url: https://maps.googleapis.com/maps/api
```

## 📍 Endpoint

**URL Base**: `http://localhost:8081`

### GET /api/distancia

Calcula la distancia y duración entre dos puntos geográficos.

#### Parámetros Query

| Parámetro | Tipo   | Requerido | Ejemplo                    | Descripción                           |
|-----------|--------|-----------|----------------------------|---------------------------------------|
| origen    | String | Sí        | Buenos Aires, Argentina    | Dirección o coordenadas de origen     |
| destino   | String | Sí        | Córdoba, Argentina         | Dirección o coordenadas de destino    |

#### Ejemplos de Uso

### 1️⃣ Con cURL

```bash
# Prueba básica con direcciones
curl -X GET "http://localhost:8081/api/distancia?origen=Buenos%20Aires,%20Argentina&destino=C%C3%B3rdoba,%20Argentina"

# Prueba con coordenadas (lat,lng)
curl -X GET "http://localhost:8081/api/distancia?origen=-34.6037,−58.3816&destino=-31.4201,-64.1888"

# Prueba con formato prettified
curl -X GET "http://localhost:8081/api/distancia?origen=Buenos%20Aires&destino=La%20Plata" | jq .
```

### 2️⃣ Con Postman

1. Abre Postman
2. Crea una nueva solicitud GET
3. URL: `http://localhost:8081/api/distancia`
4. Query Params:
   - Key: `origen` | Value: `Buenos Aires, Argentina`
   - Key: `destino` | Value: `Córdoba, Argentina`
5. Click Send

### 3️⃣ Con Swagger UI

1. Navega a: `http://localhost:8081/swagger-ui/index.html`
2. Busca "Geolocalización"
3. Abre el endpoint GET `/api/distancia`
4. Click "Try it out"
5. Ingresa valores en los campos
6. Click "Execute"

## 📤 Respuesta Exitosa (200 OK)

```json
{
  "origen": "Buenos Aires, Argentina",
  "destino": "Córdoba, Argentina",
  "kilometros": 704.5,
  "duracionTexto": "7 hours 15 mins"
}
```

## ❌ Respuestas de Error

### 400 - Bad Request
```json
{
  "error": "Los parámetros 'origen' y 'destino' son requeridos"
}
```

### 500 - Error en Google Maps
```json
{
  "error": "Google Maps API error: INVALID_REQUEST"
}
```

Posibles razones:
- API Key inválida o expirada
- Límite de consultas excedido
- Ubicación no encontrada
- Ubicaciones sin ruta disponible

## 🧪 Casos de Prueba

### ✅ Caso 1: Distancia válida entre ciudades
```bash
curl "http://localhost:8081/api/distancia?origen=Buenos%20Aires&destino=La%20Plata"
```
**Esperado**: JSON con distancia en km y duración

### ✅ Caso 2: Distancia con coordenadas
```bash
curl "http://localhost:8081/api/distancia?origen=-34.6037,-58.3816&destino=-34.9205,-57.9557"
```
**Esperado**: JSON con distancia aproximada de 45 km

### ✅ Caso 3: Misma ubicación
```bash
curl "http://localhost:8081/api/distancia?origen=Buenos%20Aires&destino=Buenos%20Aires"
```
**Esperado**: JSON con distancia de 0 km

### ❌ Caso 4: Parámetro faltante
```bash
curl "http://localhost:8081/api/distancia?origen=Buenos%20Aires"
```
**Esperado**: Error 400 o 500 (parámetro destino faltante)

### ❌ Caso 5: Ubicación inválida
```bash
curl "http://localhost:8081/api/distancia?origen=XXXINVALIDOXXX&destino=YYYY"
```
**Esperado**: Error 500 con mensaje de Google Maps (ZERO_RESULTS)

## 📊 Logs Esperados

En la consola de ms-logistica verás:

```
[INFO ] Solicitud recibida: calcular distancia desde 'Buenos Aires' hasta 'Córdoba'
[INFO ] Calculando distancia desde 'Buenos Aires' hasta 'Córdoba'
[INFO ] Distancia calculada: 704.5 km, Duración: 7 hours 15 mins
[INFO ] Respuesta exitosa: 704.5 km en 7 hours 15 mins
```

## 🔍 Debugging

### Verificar configuración
```bash
# En ms-logistica/src/main/resources/application.yml
echo "Verificando google.maps.api-key está configurada"
```

### Verificar bean de RestClient
```bash
# En logs de startup de Spring
# Busca línea similar a:
# RestClientConfig: Creating bean 'googleMapsRestClient'
```

### Verificar conectividad a Google
```bash
# Prueba manual
curl -I "https://maps.googleapis.com/maps/api/distancematrix/json"
```

## 📝 Notas Importantes

1. **Controlador Temporal**: Este controlador (`GeoController`) es solo para verificación. Debe removerse o refactorizarse en producción.

2. **Límites de API**:
   - Plan gratuito: 25 solicitudes/segundo, 500 diarias
   - Monitorea uso en Google Cloud Console

3. **Costo**: Las solicitudes a Distance Matrix API tienen costo. Revisa [Google Maps Pricing](https://developers.google.com/maps/billing-and-pricing/pricing)

4. **Autenticación**: La API key está en el parámetro `key` de la URL. En producción, considera usar OAuth 2.0.

5. **Rate Limiting**: Para aplicaciones en producción, implementa caché y rate limiting.

## 🚀 Próximos Pasos

Después de verificar que el servicio funciona:

1. Integrar `GoogleMapsService` en `TramoService` para validar distancias en solicitudes
2. Crear tests unitarios para `GoogleMapsService`
3. Implementar caché para evitar llamadas repetidas
4. Remover `GeoController` (ya no es necesario)
5. Agregar servicio de geocodificación inversa si es necesario

## 📞 Soporte

Si encuentras problemas:

1. Verifica logs de ms-logistica
2. Valida API key en Google Cloud Console
3. Comprueba que `application.yml` tiene correcta configuración
4. Verifica conectividad a internet
5. Revisa cuota de solicitudes en Google Cloud Console
