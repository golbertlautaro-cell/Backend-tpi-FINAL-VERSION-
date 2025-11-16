# 🚀 Guía de Deployment - Producción

**Versión**: 1.0.0 | **Stack**: Docker + Nginx + PostgreSQL RDS | **Última actualización**: Noviembre 2025

---

## 📋 Tabla de Contenidos

1. [Pre-requisitos](#pre-requisitos)
2. [Compilación para Producción](#compilación-para-producción)
3. [Setup Docker](#setup-docker)
4. [Configuración PostgreSQL](#configuración-postgresql)
5. [Setup Keycloak](#setup-keycloak)
6. [Reverse Proxy (Nginx)](#reverse-proxy-nginx)
7. [SSL/TLS](#ssltls)
8. [Monitoring & Logging](#monitoring--logging)
9. [Backup & Recovery](#backup--recovery)
10. [Troubleshooting](#troubleshooting)

---

## 🔧 Pre-requisitos

- Docker & Docker Compose (20.10+)
- PostgreSQL 16+ (RDS recomendado en AWS/Azure)
- Keycloak 23.0.7+ (Docker o cloud-hosted)
- Nginx 1.25+ (reverse proxy)
- SSL Certificate (Let's Encrypt o CA)
- Domain name (tudominio.com)

---

## 🏗️ Compilación para Producción

### 1. Build JAR con Perfil Production

```bash
# ms-solicitudes
cd ms-solicitudes
mvn clean package -DskipTests \
    -Dspring.profiles.active=prod \
    -Dmaven.test.skip=true

# Resultado: target/ms-solicitudes-0.0.1-SNAPSHOT.jar

# ms-logistica
cd ../ms-logistica
mvn clean package -DskipTests \
    -Dspring.profiles.active=prod

# Resultado: target/ms-logistica-0.0.1-SNAPSHOT.jar
cd ..
```

### 2. Verificar JAR

```bash
# Listar JARs generados
ls -lh ms-solicitudes/target/*.jar
ls -lh ms-logistica/target/*.jar

# Verificar que JAR ejecuta
java -jar ms-solicitudes/target/ms-solicitudes-0.0.1-SNAPSHOT.jar --help
```

---

## 🐳 Setup Docker

### 1. Dockerfile (Multistage - Optimizado)

**Ubicación**: `ms-solicitudes/Dockerfile` (igual para ms-logistica)

```dockerfile
# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src src
RUN mvn clean package -DskipTests

# Stage 2: Runtime (tiny image)
FROM eclipse-temurin:21-jre-alpine

LABEL maintainer="TPI Team"
LABEL version="1.0.0"

RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

# Copy JAR from builder
COPY --from=builder /build/target/ms-solicitudes-0.0.1-SNAPSHOT.jar app.jar

USER spring

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ping || exit 1

ENTRYPOINT ["java", "-Xmx512m", "-XX:+UseG1GC", "-jar", "app.jar"]
```

### 2. Build Docker Images

```bash
# Build ms-solicitudes
docker build -t myregistry.azurecr.io/tpi:ms-solicitudes-1.0.0 ms-solicitudes/

# Build ms-logistica
docker build -t myregistry.azurecr.io/tpi:ms-logistica-1.0.0 ms-logistica/

# Test locally
docker run -it -p 8080:8080 myregistry.azurecr.io/tpi:ms-solicitudes-1.0.0

# Push to registry
docker login myregistry.azurecr.io
docker push myregistry.azurecr.io/tpi:ms-solicitudes-1.0.0
docker push myregistry.azurecr.io/tpi:ms-logistica-1.0.0
```

### 3. Docker Compose Producción

**Ubicación**: `docker-compose.prod.yml`

```yaml
version: '3.8'

services:
  ms-solicitudes:
    image: myregistry.azurecr.io/tpi:ms-solicitudes-1.0.0
    container_name: ms-solicitudes-prod
    restart: always
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://prod-db.c5yq6gq5y1qz.us-east-1.rds.amazonaws.com:5432/tpi_prod
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      SPRING_JPA_HIBERNATE_DDL_AUTO: validate
      SPRING_JPA_SHOW_SQL: 'false'
      SPRING_PROFILES_ACTIVE: prod
      KEYCLOAK_ISSUER_URI: https://keycloak.tudominio.com/realms/tpi-realm
      KEYCLOAK_JWK_SET_URI: https://keycloak.tudominio.com/realms/tpi-realm/protocol/openid-connect/certs
      LOGGING_LEVEL_ROOT: WARN
      LOGGING_LEVEL_COM_TPI: INFO
      MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE: health,metrics,info
    ports:
      - "8080:8080"
    networks:
      - tpi-network
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:8080/ping || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  ms-logistica:
    image: myregistry.azurecr.io/tpi:ms-logistica-1.0.0
    container_name: ms-logistica-prod
    restart: always
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://prod-db.c5yq6gq5y1qz.us-east-1.rds.amazonaws.com:5432/tpi_prod
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      SPRING_JPA_HIBERNATE_DDL_AUTO: validate
      SPRING_PROFILES_ACTIVE: prod
      KEYCLOAK_ISSUER_URI: https://keycloak.tudominio.com/realms/tpi-realm
      LOGGING_LEVEL_ROOT: WARN
      LOGGING_LEVEL_COM_TPI: INFO
    ports:
      - "8081:8080"
    networks:
      - tpi-network
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:8080/ping || exit 1
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  tpi-network:
    driver: bridge

volumes:
  logs:
```

### 4. Iniciar Servicios

```bash
# Cargar variables de entorno
export DB_USER=tpi_app_user
export DB_PASSWORD=$(openssl rand -base64 32)

# Crear archivo .env
cat > .env << EOF
DB_USER=tpi_app_user
DB_PASSWORD=$DB_PASSWORD
EOF

# Iniciar (con docker-compose prod)
docker-compose -f docker-compose.prod.yml up -d

# Verificar
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f ms-solicitudes
```

---

## 🗄️ Configuración PostgreSQL

### 1. AWS RDS Setup

```bash
# Crear RDS instance (via AWS Console o CLI)
aws rds create-db-instance \
    --db-instance-identifier tpi-prod-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 16.1 \
    --master-username tpi_admin \
    --master-user-password $(openssl rand -base64 32) \
    --allocated-storage 100 \
    --storage-type gp3 \
    --multi-az \
    --backup-retention-period 30 \
    --publicly-accessible false
```

### 2. Crear Base de Datos y Usuario

```bash
# Conectar a RDS
psql -h prod-db.c5yq6gq5y1qz.us-east-1.rds.amazonaws.com \
     -U tpi_admin \
     -d postgres

# Crear base de datos
CREATE DATABASE tpi_prod 
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8';

# Crear usuario de aplicación (con permisos limitados)
CREATE USER tpi_app_user WITH PASSWORD 'strong_password_here';

# Otorgar permisos
GRANT CONNECT ON DATABASE tpi_prod TO tpi_app_user;
\c tpi_prod
GRANT USAGE ON SCHEMA public TO tpi_app_user;
GRANT CREATE ON SCHEMA public TO tpi_app_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tpi_app_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO tpi_app_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO tpi_app_user;
```

### 3. Inicializar Schema (migrations)

```bash
# Opción A: Via Spring Data JPA (DDL auto)
# application-prod.yml debe tener:
# spring.jpa.hibernate.ddl-auto: update

# Opción B: Via Flyway (recomendado para prod)
# Ver: https://flywaydb.org/documentation/

# Opción C: Manual SQL
psql -h prod-db.c5yq6gq5y1qz.us-east-1.rds.amazonaws.com \
     -U tpi_app_user \
     -d tpi_prod \
     -f init-db.sql
```

### 4. Configurar Backups

```bash
# Automated backups (AWS RDS)
# - Backup retention: 30 días
# - Backup window: 03:00 UTC (fuera de horario pico)
# - Multi-AZ: Enabled (para failover automático)
```

---

## 🔐 Setup Keycloak

### Opción 1: Cloud Hosted (Recomendado)

```bash
# AWS Cognito (alternativa)
# Azure AD B2C
# Auth0
# Keycloak managed service
```

### Opción 2: Self-Hosted en EC2

```yaml
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:23.0.7
    container_name: keycloak-prod
    restart: always
    environment:
      KEYCLOAK_ADMIN: ${KEYCLOAK_ADMIN}
      KEYCLOAK_ADMIN_PASSWORD: ${KEYCLOAK_PASSWORD}
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://prod-db.c5yq6gq5y1qz.us-east-1.rds.amazonaws.com:5432/keycloak
      KC_DB_USERNAME: ${DB_USER}
      KC_DB_PASSWORD: ${DB_PASSWORD}
      KC_PROXY: edge
      KC_HOSTNAME: keycloak.tudominio.com
      KC_HOSTNAME_STRICT: 'false'
      KC_HTTP_ENABLED: 'true'
    ports:
      - "8090:8080"
    networks:
      - tpi-network
    healthcheck:
      test: curl --fail http://localhost:8080/health/ready || exit 1
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  tpi-network:
    driver: bridge
```

### Configuración del Realm

```bash
# 1. Acceder Admin Console
# https://keycloak.tudominio.com/admin

# 2. Crear Realm: tpi-realm
# 3. Crear Cliente: tpi-app
#    - Client Protocol: openid-connect
#    - Root URL: https://tudominio.com
#    - Valid Redirect URIs: https://tudominio.com/*
#    - Web Origins: https://tudominio.com

# 4. Crear Usuarios:
#    - admin / admin123
#    - user / user123

# 5. Asignar Roles
```

---

## 🌐 Reverse Proxy (Nginx)

### 1. Configuración Nginx

**Ubicación**: `/etc/nginx/sites-available/tpi-api.conf`

```nginx
upstream ms_solicitudes {
    server ms-solicitudes:8080 max_fails=3 fail_timeout=30s;
    # Si hay múltiples instancias:
    # server ms-solicitudes-1:8080;
    # server ms-solicitudes-2:8080;
}

upstream ms_logistica {
    server ms-logistica:8080 max_fails=3 fail_timeout=30s;
}

# Redirect HTTP → HTTPS
server {
    listen 80;
    server_name tudominio.com www.tudominio.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS API
server {
    listen 443 ssl http2;
    server_name api.tudominio.com;

    # SSL/TLS certificates
    ssl_certificate /etc/letsencrypt/live/tudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tudominio.com/privkey.pem;

    # SSL Security headers
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/s;
    limit_req zone=general burst=20 nodelay;

    # ms-solicitudes
    location /api/solicitudes {
        proxy_pass http://ms_solicitudes;
        include proxy_params;
        limit_req zone=general burst=20;
    }

    location /api/clientes {
        proxy_pass http://ms_solicitudes;
        include proxy_params;
    }

    location /api/tramos {
        proxy_pass http://ms_solicitudes;
        include proxy_params;
    }

    # ms-logistica
    location /api/camiones {
        proxy_pass http://ms_logistica;
        include proxy_params;
    }

    location /api/depositos {
        proxy_pass http://ms_logistica;
        include proxy_params;
    }

    # Swagger
    location /swagger-ui.html {
        proxy_pass http://ms_solicitudes;
        include proxy_params;
    }

    location /v3/api-docs {
        proxy_pass http://ms_solicitudes;
        include proxy_params;
    }

    # Health checks (internal only)
    location /ping {
        access_log off;
        proxy_pass http://ms_solicitudes;
        proxy_connect_timeout 1s;
        proxy_read_timeout 1s;
    }

    # Metrics (internal only)
    location /actuator {
        allow 10.0.0.0/8;  # Private network
        deny all;
        proxy_pass http://ms_solicitudes;
        include proxy_params;
    }

    # Default 404
    location / {
        return 404;
    }
}

# Proxy params file: /etc/nginx/includes/proxy_params
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $server_name;
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_buffering off;
proxy_read_timeout 60s;
proxy_connect_timeout 60s;
```

### 2. Habilitar Configuración

```bash
# Link config
sudo ln -s /etc/nginx/sites-available/tpi-api.conf /etc/nginx/sites-enabled/

# Test
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

---

## 🔒 SSL/TLS

### 1. Let's Encrypt (Gratuito & Automático)

```bash
# Instalar Certbot
sudo apt-get install certbot python3-certbot-nginx

# Obtener certificado
sudo certbot certonly --nginx -d tudominio.com -d www.tudominio.com

# Auto-renewal (cron)
sudo systemctl enable certbot.timer
```

### 2. Certificado CA (Alternativa)

```bash
# Generar CSR
openssl req -new -key private.key -out server.csr

# Enviar a CA
# Descargar certificado

# Instalar en Nginx
# Actualizar rutas en nginx.conf
```

---

## 📊 Monitoring & Logging

### 1. Centralized Logging (ELK Stack)

```yaml
# docker-compose con Elasticsearch, Logstash, Kibana
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    environment:
      - discovery.type=single-node
    ports:
      - "9200:9200"

  logstash:
    image: docker.elastic.co/logstash/logstash:8.0.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5000:5000"

  kibana:
    image: docker.elastic.co/kibana/kibana:8.0.0
    ports:
      - "5601:5601"
```

### 2. Prometheus Metrics

**application-prod.yml**:
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
```

**prometheus.yml**:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ms-solicitudes'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/actuator/prometheus'

  - job_name: 'ms-logistica'
    static_configs:
      - targets: ['localhost:8081']
    metrics_path: '/actuator/prometheus'
```

### 3. Alerting (Grafana + AlertManager)

```bash
# Alertas
- CPU > 80%
- Memory > 90%
- Response time > 500ms
- Error rate > 1%
- Database connections > 90%
```

---

## 💾 Backup & Recovery

### 1. PostgreSQL Backups

```bash
# Automated backups (AWS RDS)
# Manual backup
pg_dump -h prod-db.c5yq6gq5y1qz.us-east-1.rds.amazonaws.com \
        -U tpi_app_user \
        -d tpi_prod \
        -Fc > tpi_prod_$(date +%Y%m%d_%H%M%S).dump

# Restore
pg_restore -h prod-db.c5yq6gq5y1qz.us-east-1.rds.amazonaws.com \
           -U tpi_app_user \
           -d tpi_prod_restore \
           < tpi_prod_20251109_120000.dump
```

### 2. Docker Image Backup

```bash
# Commit image changes
docker commit ms-solicitudes-prod myregistry.azurecr.io/tpi:ms-solicitudes-backup-$(date +%Y%m%d)

# Push to registry
docker push myregistry.azurecr.io/tpi:ms-solicitudes-backup-$(date +%Y%m%d)
```

---

## 🐛 Troubleshooting

### 1. Container won't start

```bash
# Ver logs
docker logs ms-solicitudes-prod

# Verificar variables de entorno
docker inspect ms-solicitudes-prod | grep -A 20 "Env"

# Test conectividad DB
docker exec ms-solicitudes-prod curl telnet prod-db:5432
```

### 2. Database connection timeout

```bash
# Ver status de RDS
aws rds describe-db-instances --db-instance-identifier tpi-prod-db

# Verificar security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Permitir acceso desde container
# Security Group Rule: 5432/TCP from Container Security Group
```

### 3. JWT validation fails

```bash
# Verificar Keycloak está accesible
curl https://keycloak.tudominio.com/realms/tpi-realm/.well-known/openid-configuration

# Ver logs de Keycloak
docker logs keycloak-prod

# Verificar ISSUER_URI en app config
docker exec ms-solicitudes-prod env | grep KEYCLOAK
```

### 4. High memory usage

```bash
# Ver heap usage
docker stats ms-solicitudes-prod

# Aumentar límite en docker-compose
# environment:
#   - JAVA_OPTS=-Xmx1024m -XX:+UseG1GC

# Analizar heap dump
jmap -dump:live,format=b,file=heap.bin <pid>
```

---

## ✅ Pre-Deployment Checklist

```
Database:
☐ RDS instance creada
☐ Backups automatizados configurados
☐ Security groups correctos
☐ Base de datos inicializada
☐ Usuario de app creado

Keycloak:
☐ Deployado (cloud o self-hosted)
☐ Realm creado
☐ Cliente OAuth2 creado
☐ Usuarios creados
☐ Certificado SSL válido

Docker:
☐ Images compiladas
☐ Enviadas a registry
☐ docker-compose.prod.yml configurado
☐ Variables de entorno (.env) configuradas

Nginx:
☐ Configurado como reverse proxy
☐ SSL/TLS certificado instalado
☐ Rate limiting configurado
☐ Security headers habilitados
☐ Health checks funcionando

Monitoring:
☐ Prometheus configurado
☐ Kibana/ELK setup (si aplica)
☐ Alertas definidas
☐ Dashboards Grafana creados

Testing:
☐ Endpoints HTTP validados
☐ JWT authentication works
☐ Database queries OK
☐ Logs centralizados
☐ Performance baseline established
```

---

## 🚀 Go-Live Procedure

```bash
# 1. Pre-checks (30 min antes)
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs --tail=50

# 2. Validar endpoints
curl -X GET https://api.tudominio.com/api/clientes \
  -H "Authorization: Bearer $TOKEN" -v

# 3. Smoke tests (post-deploy)
./smoke-tests.sh

# 4. Monitor logs (primeras 2 horas)
docker-compose -f docker-compose.prod.yml logs -f

# 5. Verificar alertas

# 6. Comunicar a stakeholders
```

---

**Última actualización**: Noviembre 2025
