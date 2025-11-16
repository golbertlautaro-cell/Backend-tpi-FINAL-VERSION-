# 🚀 INSTRUCCIONES PARA EJECUTAR Y PROBAR

## ✅ Estado Actual
- ✅ ms-logistica compilado
- ✅ ms-solicitudes compilado
- ✅ 57 tests pasando
- ✅ 0 errores

---

## 🎯 Opción 1: Ejecutar en 2 Terminales (RECOMENDADO)

### Terminal 1 - ms-logistica (Puerto 8081)
```powershell
cd d:\Users\Usuario\Desktop\backend1\ms-logistica
mvn spring-boot:run
```

**Espera a ver este mensaje:**
```
Tomcat started on port(s): 8081 with context path ''
```

### Terminal 2 - ms-solicitudes (Puerto 8080)
```powershell
cd d:\Users\Usuario\Desktop\backend1\ms-solicitudes
mvn spring-boot:run
```

**Espera a ver este mensaje:**
```
Tomcat started on port(s): 8080 with context path ''
```

---

## 🧪 Opciones de Prueba (Una vez iniciados)

### Opción A: Health Check (Más Simple)
```powershell
# Verifica que ms-logistica esté activo
curl http://localhost:8081/actuator/health

# Verifica que ms-solicitudes esté activo
curl http://localhost:8080/actuator/health
```

### Opción B: Probar Google Maps (Si tienes API Key)

Primero, configura en `ms-logistica/src/main/resources/application.yml`:
```yaml
google:
  maps:
    api-key: TU_API_KEY_AQUI
```

Luego ejecuta:
```powershell
curl "http://localhost:8081/api/distancia?origen=Buenos%20Aires&destino=C%C3%B3rdoba"
```

Respuesta esperada:
```json
{
  "origen": "Buenos Aires",
  "destino": "Córdoba",
  "kilometros": 704.5,
  "duracionTexto": "7 hours 15 mins"
}
```

### Opción C: Swagger UI (Interfaz Gráfica)

En tu navegador:
- **ms-logistica**: http://localhost:8081/swagger-ui/index.html
- **ms-solicitudes**: http://localhost:8080/swagger-ui/index.html

---

## 📊 Ver Logs en Tiempo Real

### ms-logistica
```powershell
Get-Content -Path logs/ms-logistica.log -Wait
```

### ms-solicitudes
```powershell
Get-Content -Path logs/ms-solicitudes.log -Wait
```

---

## 📋 Checklist

- [ ] Terminal 1: ms-logistica arrancado (puerto 8081)
- [ ] Terminal 2: ms-solicitudes arrancado (puerto 8080)
- [ ] Health check OK: curl localhost:8080/actuator/health
- [ ] Health check OK: curl localhost:8081/actuator/health
- [ ] Swagger UI accesible
- [ ] Google Maps funcionando (opcional)

---

## 🛑 Para Detener

```powershell
# Presiona Ctrl+C en cada terminal
```

---

## ⚡ Problema: Puerto ya en uso

Si ves error como `Port 8081 is already in use`:

```powershell
# Encuentra qué proceso usa el puerto
netstat -ano | findstr :8081

# Mata el proceso (reemplaza PID con el número)
taskkill /PID <PID> /F
```

---

## 🎯 Próximo Paso

Una vez que confirmes:
- ✅ Ambos servicios corren
- ✅ Health checks responden OK
- ✅ Swagger UI accesible

**Opción 1**: Continuar con **Fase 5** (Docker, Actuator, CI/CD)  
**Opción 2**: Guardar cambios con **Commit a GitHub**

