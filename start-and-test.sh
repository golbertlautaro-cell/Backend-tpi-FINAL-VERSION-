#!/bin/bash
# Script para iniciar ambos microservicios y probar endpoints
# Uso: bash start-and-test.sh

echo "=========================================="
echo "  INICIANDO MICROSERVICIOS - TPI LOGISTICA"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Crear directorio de logs si no existe
mkdir -p logs

echo -e "${BLUE}[1/4]${NC} Compilando ms-logistica..."
cd ms-logistica
mvn clean compile -q
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ms-logistica compilado exitosamente${NC}"
else
    echo -e "${RED}❌ Error compilando ms-logistica${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[2/4]${NC} Compilando ms-solicitudes..."
cd ../ms-solicitudes
mvn clean compile -q
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ms-solicitudes compilado exitosamente${NC}"
else
    echo -e "${RED}❌ Error compilando ms-solicitudes${NC}"
    exit 1
fi

cd ..
echo ""
echo -e "${BLUE}[3/4]${NC} Iniciando ms-logistica (puerto 8081)..."
echo "Ejecutando: mvn spring-boot:run -f ms-logistica/pom.xml"
mvn spring-boot:run -f ms-logistica/pom.xml > logs/ms-logistica.log 2>&1 &
LOGISTICA_PID=$!
echo -e "${GREEN}✅ ms-logistica iniciado (PID: $LOGISTICA_PID)${NC}"
echo "   Logs: logs/ms-logistica.log"

sleep 3

echo ""
echo -e "${BLUE}[4/4]${NC} Iniciando ms-solicitudes (puerto 8080)..."
echo "Ejecutando: mvn spring-boot:run -f ms-solicitudes/pom.xml"
mvn spring-boot:run -f ms-solicitudes/pom.xml > logs/ms-solicitudes.log 2>&1 &
SOLICITUDES_PID=$!
echo -e "${GREEN}✅ ms-solicitudes iniciado (PID: $SOLICITUDES_PID)${NC}"
echo "   Logs: logs/ms-solicitudes.log"

sleep 5

echo ""
echo "=========================================="
echo "  SERVICIOS EN EJECUCIÓN"
echo "=========================================="
echo ""
echo -e "${GREEN}ms-logistica${NC}     (Puerto 8081)"
echo "  - Health:  http://localhost:8081/actuator/health"
echo "  - Swagger: http://localhost:8081/swagger-ui/index.html"
echo "  - GEO API: http://localhost:8081/api/distancia?origen=A&destino=B"
echo ""
echo -e "${GREEN}ms-solicitudes${NC}   (Puerto 8080)"
echo "  - Health:  http://localhost:8080/actuator/health"
echo "  - Swagger: http://localhost:8080/swagger-ui/index.html"
echo ""

echo "=========================================="
echo "  PRUEBAS RECOMENDADAS"
echo "=========================================="
echo ""
echo -e "${YELLOW}1. Health Check:${NC}"
echo "   curl http://localhost:8080/actuator/health"
echo "   curl http://localhost:8081/actuator/health"
echo ""
echo -e "${YELLOW}2. GeoController (Google Maps):${NC}"
echo "   curl 'http://localhost:8081/api/distancia?origen=Buenos+Aires&destino=Cordoba'"
echo ""
echo -e "${YELLOW}3. Ver logs:${NC}"
echo "   tail -f logs/ms-logistica.log"
echo "   tail -f logs/ms-solicitudes.log"
echo ""

echo "=========================================="
echo -e "${YELLOW}Presiona Ctrl+C para detener los servicios${NC}"
echo "=========================================="
echo ""

# Mantener el script en ejecución
wait $LOGISTICA_PID $SOLICITUDES_PID

echo ""
echo -e "${YELLOW}Servicios detenidos${NC}"
