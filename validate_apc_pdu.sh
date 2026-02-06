#!/bin/bash

# Script de validación SNMP para APC PDU 8953 Cascaded
# Soporta SNMPv2c y SNMPv3
# 
# Uso SNMPv2c: ./validate_apc_pdu.sh <IP> v2c <COMMUNITY>
# Uso SNMPv3:  ./validate_apc_pdu.sh <IP> v3 <USER> <AUTH_PROTO> <AUTH_PASS> <PRIV_PROTO> <PRIV_PASS>
#
# Ejemplo v2c: ./validate_apc_pdu.sh 192.168.1.100 v2c public
# Ejemplo v3:  ./validate_apc_pdu.sh 192.168.1.100 v3 apcuser SHA myauthpass AES myprivpass

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de ayuda
show_help() {
    echo "Script de validación SNMP para APC PDU 8953 Cascaded"
    echo ""
    echo "Uso:"
    echo "  SNMPv2c: $0 <IP_ADDRESS> v2c <COMMUNITY>"
    echo "  SNMPv3:  $0 <IP_ADDRESS> v3 <USER> <AUTH_PROTO> <AUTH_PASS> [PRIV_PROTO] [PRIV_PASS]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 192.168.1.100 v2c public"
    echo "  $0 192.168.1.100 v3 apcuser SHA myauthpass"
    echo "  $0 192.168.1.100 v3 apcuser SHA myauthpass AES myprivpass"
    echo "  $0 192.168.1.100 v3 apcuser MD5 myauthpass DES myprivpass"
    echo ""
    echo "Protocolos soportados:"
    echo "  Autenticación: MD5, SHA, SHA-224, SHA-256, SHA-384, SHA-512"
    echo "  Privacidad: DES, AES, AES-192, AES-256"
    echo ""
    exit 1
}

# Parámetros
IP_ADDRESS=${1:-""}
SNMP_VERSION=${2:-""}

# Verificar parámetros básicos
if [ -z "$IP_ADDRESS" ] || [ -z "$SNMP_VERSION" ]; then
    show_help
fi

# Variables para SNMP
SNMP_PARAMS=""

# Configurar según versión SNMP
case "$SNMP_VERSION" in
    v2c)
        COMMUNITY=${3:-"public"}
        SNMP_PARAMS="-v2c -c $COMMUNITY"
        SNMP_DISPLAY="SNMPv2c (Community: $COMMUNITY)"
        ;;
    v3)
        SNMP_USER=${3:-""}
        AUTH_PROTO=${4:-""}
        AUTH_PASS=${5:-""}
        PRIV_PROTO=${6:-""}
        PRIV_PASS=${7:-""}
        
        if [ -z "$SNMP_USER" ] || [ -z "$AUTH_PROTO" ] || [ -z "$AUTH_PASS" ]; then
            echo -e "${RED}Error: SNMPv3 requiere al menos USER, AUTH_PROTO y AUTH_PASS${NC}"
            show_help
        fi
        
        # Construir parámetros SNMPv3
        SNMP_PARAMS="-v3 -l authNoPriv -u $SNMP_USER -a $AUTH_PROTO -A $AUTH_PASS"
        SNMP_DISPLAY="SNMPv3 (User: $SNMP_USER, Auth: $AUTH_PROTO)"
        
        # Si se proporciona privacidad
        if [ -n "$PRIV_PROTO" ] && [ -n "$PRIV_PASS" ]; then
            SNMP_PARAMS="-v3 -l authPriv -u $SNMP_USER -a $AUTH_PROTO -A $AUTH_PASS -x $PRIV_PROTO -X $PRIV_PASS"
            SNMP_DISPLAY="SNMPv3 (User: $SNMP_USER, Auth: $AUTH_PROTO, Priv: $PRIV_PROTO)"
        fi
        ;;
    *)
        echo -e "${RED}Error: Versión SNMP no soportada: $SNMP_VERSION${NC}"
        echo "Use 'v2c' o 'v3'"
        show_help
        ;;
esac

# Verificar que se proporcionó una IP válida
if [ -z "$IP_ADDRESS" ]; then
    echo -e "${RED}Error: Debe proporcionar una dirección IP${NC}"
    show_help
fi

# Verificar que snmpwalk está instalado
if ! command -v snmpwalk &> /dev/null; then
    echo -e "${RED}Error: snmpwalk no está instalado${NC}"
    echo "Instalar con: sudo apt-get install snmp snmp-mibs-downloader"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Validación SNMP para APC PDU 8953 Cascaded               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "IP Address:    ${YELLOW}$IP_ADDRESS${NC}"
echo -e "SNMP Config:   ${YELLOW}$SNMP_DISPLAY${NC}"
echo ""

# Función para verificar OID
check_oid() {
    local description=$1
    local oid=$2
    local expected_count=$3
    
    echo -ne "${YELLOW}Verificando:${NC} $description ... "
    
    result=$(snmpwalk $SNMP_PARAMS -t 5 "$IP_ADDRESS" "$oid" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
        count=$(echo "$result" | grep -c "^")
        if [ -n "$expected_count" ] && [ "$expected_count" != "any" ]; then
            if [ "$count" -eq "$expected_count" ]; then
                echo -e "${GREEN}✓ OK${NC} (${count} valores encontrados)"
            else
                echo -e "${YELLOW}⚠ ADVERTENCIA${NC} (esperado: ${expected_count}, encontrado: ${count})"
            fi
        else
            echo -e "${GREEN}✓ OK${NC} (${count} valores encontrados)"
        fi
        return 0
    else
        echo -e "${RED}✗ FALLO${NC}"
        return 1
    fi
}

# Función para mostrar valores
show_values() {
    local description=$1
    local oid=$2
    
    echo ""
    echo -e "${BLUE}═══ $description ═══${NC}"
    result=$(snmpwalk $SNMP_PARAMS -t 5 "$IP_ADDRESS" "$oid" 2>&1)
    if [ $? -eq 0 ]; then
        echo "$result" | while IFS= read -r line; do
            echo "  $line"
        done
    else
        echo -e "  ${RED}No se pudo obtener información${NC}"
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. INFORMACIÓN GENERAL DEL DISPOSITIVO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_oid "Modelo del dispositivo" ".1.3.6.1.4.1.318.1.1.26.2.1.6.1" "1"
check_oid "Nombre del dispositivo" ".1.3.6.1.4.1.318.1.1.26.2.1.8.1" "1"
check_oid "Ubicación" ".1.3.6.1.4.1.318.1.1.26.2.1.9.1" "1"
check_oid "Versión de firmware" ".1.3.6.1.4.1.318.1.1.4.2.3" "1"
check_oid "Número de serie" ".1.3.6.1.4.1.318.1.1.26.4.1.1.3.1" "1"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. DETECCIÓN DE PDUs EN CASCADA${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_oid "Power Consumption (PDUs detectadas)" ".1.3.6.1.4.1.318.1.1.26.4.3.1.5" "any"
check_oid "Load State" ".1.3.6.1.4.1.318.1.1.26.4.3.1.4" "any"
check_oid "Input Current" ".1.3.6.1.4.1.318.1.1.26.4.3.1.9" "any"
check_oid "Energy Accumulated" ".1.3.6.1.4.1.318.1.1.26.4.3.1.12" "any"
check_oid "Apparent Power" ".1.3.6.1.4.1.318.1.1.26.4.3.1.16" "any"
check_oid "Power Factor" ".1.3.6.1.4.1.318.1.1.26.4.3.1.17" "any"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. DETECCIÓN DE BANKS/PHASES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_oid "Bank Current" ".1.3.6.1.4.1.318.1.1.26.8.3.1.5" "any"
check_oid "Bank Load State" ".1.3.6.1.4.1.318.1.1.26.8.3.1.4" "any"
check_oid "Bank Voltage" ".1.3.6.1.4.1.318.1.1.26.8.3.1.6" "any"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. DETECCIÓN DE FASES DE ENTRADA${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_oid "Phase Current" ".1.3.6.1.4.1.318.1.1.26.6.3.1.5" "any"
check_oid "Phase Voltage" ".1.3.6.1.4.1.318.1.1.26.6.3.1.6" "any"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. DETECCIÓN DE OUTLETS (TOMAS)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_oid "Outlet Current (hasta 24)" ".1.3.6.1.4.1.318.1.1.26.9.2.3.1.5" "any"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. DETECCIÓN DE SENSORES AMBIENTALES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_oid "Temperature Sensors" ".1.3.6.1.4.1.318.1.1.26.10.2.2.1.8" "any"
check_oid "Humidity Sensors" ".1.3.6.1.4.1.318.1.1.26.10.2.2.1.10" "any"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}7. VALORES DETALLADOS (MUESTRA)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Mostrar valores de ejemplo
show_values "Información del dispositivo" ".1.3.6.1.4.1.318.1.1.26.2.1"
show_values "PDU Power Consumption (kW × 0.01)" ".1.3.6.1.4.1.318.1.1.26.4.3.1.5"
show_values "PDU Load State (1=low,2=normal,3=near,4=over)" ".1.3.6.1.4.1.318.1.1.26.4.3.1.4"
show_values "Bank Current (A × 0.1)" ".1.3.6.1.4.1.318.1.1.26.8.3.1.5"
show_values "Bank Voltage (V)" ".1.3.6.1.4.1.318.1.1.26.8.3.1.6"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}8. ANÁLISIS DE CASCADA${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Contar PDUs detectadas
pdu_count=$(snmpwalk $SNMP_PARAMS -t 5 "$IP_ADDRESS" .1.3.6.1.4.1.318.1.1.26.4.3.1.5 2>/dev/null | wc -l)
bank_count=$(snmpwalk $SNMP_PARAMS -t 5 "$IP_ADDRESS" .1.3.6.1.4.1.318.1.1.26.8.3.1.5 2>/dev/null | wc -l)
outlet_count=$(snmpwalk $SNMP_PARAMS -t 5 "$IP_ADDRESS" .1.3.6.1.4.1.318.1.1.26.9.2.3.1.5 2>/dev/null | wc -l)

echo ""
echo -e "PDUs detectadas:    ${GREEN}$pdu_count${NC}"
echo -e "Banks detectados:   ${GREEN}$bank_count${NC}"
echo -e "Outlets detectados: ${GREEN}$outlet_count${NC}"

echo ""
if [ "$pdu_count" -gt 0 ]; then
    echo -e "${GREEN}✓ Sistema en cascada detectado correctamente${NC}"
    echo ""
    echo "Distribución esperada:"
    echo "  • PDUs: $pdu_count"
    echo "  • Banks por PDU: $(($bank_count / $pdu_count)) (típicamente 2)"
    echo "  • Total outlets: $outlet_count"
else
    echo -e "${RED}✗ No se detectaron PDUs${NC}"
    echo "Posibles causas:"
    echo "  • Community string incorrecta"
    echo "  • Firewall bloqueando puerto 161/UDP"
    echo "  • Dispositivo no soporta rPDU2 MIB"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}9. RECOMENDACIONES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$pdu_count" -ge 1 ] && [ "$bank_count" -ge 2 ]; then
    echo -e "${GREEN}✓ El dispositivo es compatible con el template de Zabbix${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Importar el template en Zabbix: apc_8953_template.yaml"
    echo "  2. Crear/editar host con IP: $IP_ADDRESS"
    echo "  3. Asignar template: 'APC PDU 8953 Cascaded'"
    if [ "$SNMP_VERSION" = "v2c" ]; then
        echo "  4. Configurar interfaz SNMP:"
        echo "     - SNMP version: SNMPv2"
        echo "     - SNMP community: {\$SNMP_COMMUNITY} = $COMMUNITY"
    else
        echo "  4. Configurar interfaz SNMP:"
        echo "     - SNMP version: SNMPv3"
        echo "     - Security name: $SNMP_USER"
        echo "     - Authentication protocol: $AUTH_PROTO"
        echo "     - Authentication passphrase: [configurar en Zabbix]"
        if [ -n "$PRIV_PROTO" ]; then
            echo "     - Privacy protocol: $PRIV_PROTO"
            echo "     - Privacy passphrase: [configurar en Zabbix]"
        fi
    fi
    echo "  5. Esperar ~1 hora para el discovery automático"
else
    echo -e "${YELLOW}⚠ Verificar compatibilidad del dispositivo${NC}"
    echo ""
    echo "Acciones recomendadas:"
    echo "  1. Verificar que el modelo sea APC 89xx series (rPDU2)"
    echo "  2. Actualizar firmware a versión reciente"
    echo "  3. Verificar configuración SNMP en el dispositivo"
    echo "  4. Consultar documentación del fabricante"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Validación completada                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
