# Guía Rápida de Configuración - APC PDU 8953 Cascaded

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ZABBIX SERVER                                    │
│                  (Template instalado)                               │
└────────────────────────────┬────────────────────────────────────────┘
                             │ SNMP v2c
                             │ Port 161/UDP
                             │ Community: public
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│               IP: 192.168.1.100 (ejemplo)                           │
│                  Management Interface                               │
└─────────────────────────────────────────────────────────────────────┘
                             │
            ┌────────────────┼────────────────┐
            ▼                ▼                ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │   PDU 1      │ │   PDU 2      │ │   PDU 3      │ ...
    │              │ │              │ │              │
    │ Index: 1     │ │ Index: 2     │ │ Index: 3     │
    │ Banks: 1,2   │ │ Banks: 3,4   │ │ Banks: 5,6   │
    │              │ │              │ │              │
    │ Outlets:     │ │ Outlets:     │ │ Outlets:     │
    │   1-8        │ │   9-16       │ │   17-24      │
    └──────────────┘ └──────────────┘ └──────────────┘
```

## Estructura de Índices SNMP

### Tabla de Mapeo Completa

```
┌──────────┬─────────────┬──────────────┬─────────────────────┐
│ PDU #    │ Device Index│ Bank Indices │ Outlets (ejemplo)   │
├──────────┼─────────────┼──────────────┼─────────────────────┤
│ PDU 1    │      1      │    1, 2      │    1, 2, 3, 4, 5, 6 │
│ PDU 2    │      2      │    3, 4      │    7, 8, 9,10,11,12 │
│ PDU 3    │      3      │    5, 6      │   13,14,15,16,17,18 │
│ PDU 4    │      4      │    7, 8      │   19,20,21,22,23,24 │
└──────────┴─────────────┴──────────────┴─────────────────────┘

Nota: La distribución exacta de outlets depende del modelo físico
```

## Ejemplos de Configuración en Zabbix

### 1. Configuración del Host

#### Via GUI:

1. **Navegación**: Configuration → Hosts → Create host
2. **Host tab**:
   ```
   Host name: apc-pdu-datacenter-01
   Visible name: APC PDU Rack A1
   Groups: PDUs / Data Center / Critical Infrastructure
   Interfaces:
     - Type: SNMP
     - IP address: 192.168.1.100
     - Port: 161
     - SNMP version: SNMPv2
     - SNMP community: {$SNMP_COMMUNITY}
   ```

3. **Templates tab**:
   ```
   Link new templates: APC PDU 8953 Cascaded
   ```

4. **Macros tab**:
   ```
   {$SNMP_COMMUNITY} = public
   {$SNMP_TIMEOUT} = 5s
   ```

#### Via API (JSON):

```json
{
  "jsonrpc": "2.0",
  "method": "host.create",
  "params": {
    "host": "apc-pdu-datacenter-01",
    "name": "APC PDU Rack A1",
    "interfaces": [
      {
        "type": 2,
        "main": 1,
        "useip": 1,
        "ip": "192.168.1.100",
        "dns": "",
        "port": "161",
        "details": {
          "version": 2,
          "community": "{$SNMP_COMMUNITY}"
        }
      }
    ],
    "groups": [
      {"groupid": "X"}
    ],
    "templates": [
      {"templateid": "XXXX"}
    ],
    "macros": [
      {
        "macro": "{$SNMP_COMMUNITY}",
        "value": "public"
      }
    ]
  },
  "auth": "YOUR_AUTH_TOKEN",
  "id": 1
}
```

### 2. Macros Disponibles

```yaml
# Macro obligatoria
{$SNMP_COMMUNITY}
  Descripción: Community string para SNMP
  Valor por defecto: public
  Ejemplo: private_comm_2024

# Macros opcionales (futuro uso para triggers)
{$PDU.POWER.HIGH}
  Descripción: Umbral de potencia alta (kW)
  Valor sugerido: 10
  
{$PDU.POWER.CRITICAL}
  Descripción: Umbral de potencia crítica (kW)
  Valor sugerido: 15

{$PDU.CURRENT.HIGH}
  Descripción: Umbral de corriente alta (A)
  Valor sugerido: 15

{$PDU.TEMP.HIGH}
  Descripción: Temperatura alta (°C)
  Valor sugerido: 30

{$PDU.TEMP.CRITICAL}
  Descripción: Temperatura crítica (°C)
  Valor sugerido: 35
```

### 3. Ejemplo de Valores Reales

#### Escenario: 2 PDUs en cascada, cada una con 2 banks y 12 outlets

```
# PDU Device Metrics
.1.3.6.1.4.1.318.1.1.26.4.3.1.5.1 = 145    → 1.45 kW (PDU 1)
.1.3.6.1.4.1.318.1.1.26.4.3.1.5.2 = 132    → 1.32 kW (PDU 2)
.1.3.6.1.4.1.318.1.1.26.4.3.1.4.1 = 2      → Normal
.1.3.6.1.4.1.318.1.1.26.4.3.1.4.2 = 2      → Normal

# Bank Metrics (4 banks total: 2 por PDU)
.1.3.6.1.4.1.318.1.1.26.8.3.1.5.1 = 54     → 5.4 A (PDU 1, Bank A)
.1.3.6.1.4.1.318.1.1.26.8.3.1.5.2 = 58     → 5.8 A (PDU 1, Bank B)
.1.3.6.1.4.1.318.1.1.26.8.3.1.5.3 = 48     → 4.8 A (PDU 2, Bank A)
.1.3.6.1.4.1.318.1.1.26.8.3.1.5.4 = 52     → 5.2 A (PDU 2, Bank B)

.1.3.6.1.4.1.318.1.1.26.8.3.1.6.1 = 230    → 230 V
.1.3.6.1.4.1.318.1.1.26.8.3.1.6.2 = 231    → 231 V
.1.3.6.1.4.1.318.1.1.26.8.3.1.6.3 = 229    → 229 V
.1.3.6.1.4.1.318.1.1.26.8.3.1.6.4 = 230    → 230 V

# Outlet Metrics (24 outlets)
.1.3.6.1.4.1.318.1.1.26.9.2.3.1.5.1 = 12   → 1.2 A
.1.3.6.1.4.1.318.1.1.26.9.2.3.1.5.2 = 8    → 0.8 A
...
.1.3.6.1.4.1.318.1.1.26.9.2.3.1.5.24 = 15  → 1.5 A
```

## Verificación Post-Instalación

### Checklist de Verificación

```
□ Template importado exitosamente
□ Host creado con interfaz SNMP configurada
□ Macro {$SNMP_COMMUNITY} configurada
□ Discovery rules ejecutándose (ver Latest data)
□ Items siendo populados (esperar 1-5 minutos)
□ Gráficos disponibles
□ No hay errores en Zabbix server log
```

### Comandos de Verificación

```bash
# 1. Verificar conectividad SNMP básica
snmpwalk -v2c -c public 192.168.1.100 1.3.6.1.2.1.1.1.0

# 2. Verificar detección de PDUs
snmpwalk -v2c -c public 192.168.1.100 1.3.6.1.4.1.318.1.1.26.4.3.1.5

# 3. Verificar detección de Banks
snmpwalk -v2c -c public 192.168.1.100 1.3.6.1.4.1.318.1.1.26.8.3.1.5

# 4. Verificar información del dispositivo
snmpget -v2c -c public 192.168.1.100 \
  1.3.6.1.4.1.318.1.1.26.2.1.6.1 \
  1.3.6.1.4.1.318.1.1.26.2.1.8.1

# 5. Test completo (usar script incluido)
./validate_apc_pdu.sh 192.168.1.100 public
```

### Logs de Zabbix

```bash
# Ver logs del server
sudo tail -f /var/log/zabbix/zabbix_server.log | grep -i "apc\|pdu\|snmp"

# Buscar errores de SNMP
sudo grep "SNMP error" /var/log/zabbix/zabbix_server.log | tail -20

# Ver discovery process
sudo grep "Discovery rule" /var/log/zabbix/zabbix_server.log | grep "apc-pdu"
```

## Interpretación de Datos en Zabbix

### Dashboard Recomendado

```
┌──────────────────────────────────────────────────────────────┐
│ APC PDU Monitoring Dashboard                                │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Total Power Consumption                                    │
│  ┌────────────────────────────────────────────┐            │
│  │ [Graph: All PDUs Power over time]          │            │
│  └────────────────────────────────────────────┘            │
│                                                              │
│  PDU Status Overview                                        │
│  ┌─────────┬─────────┬─────────┬─────────┐                │
│  │ PDU 1   │ PDU 2   │ PDU 3   │ PDU 4   │                │
│  │ 1.45 kW │ 1.32 kW │ 0.98 kW │ OFF     │                │
│  │ Normal  │ Normal  │ Normal  │ --      │                │
│  └─────────┴─────────┴─────────┴─────────┘                │
│                                                              │
│  Bank Current Distribution                                  │
│  ┌────────────────────────────────────────────┐            │
│  │ [Bar Chart: Current per Bank]              │            │
│  └────────────────────────────────────────────┘            │
│                                                              │
│  Environmental Sensors                                      │
│  Temperature: 24.5°C  |  Humidity: 45%                     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Widgets Sugeridos

```json
// Widget 1: Total Power (Graph)
{
  "type": "graph",
  "name": "Total Power Consumption",
  "fields": {
    "source_type": "1",
    "itemid": [
      "apc.pdu[1,power]",
      "apc.pdu[2,power]",
      "apc.pdu[3,power]",
      "apc.pdu[4,power]"
    ]
  }
}

// Widget 2: PDU Status (Plain text)
{
  "type": "plaintext",
  "name": "PDU Load States",
  "fields": {
    "itemids": [
      "apc.pdu[1,load.state]",
      "apc.pdu[2,load.state]",
      "apc.pdu[3,load.state]",
      "apc.pdu[4,load.state]"
    ],
    "show_lines": "10"
  }
}

// Widget 3: Current per Bank (Graph)
{
  "type": "graph",
  "name": "Bank Current Distribution",
  "fields": {
    "source_type": "1",
    "itemid": [
      "apc.pdu.bank[1,current]",
      "apc.pdu.bank[2,current]",
      "apc.pdu.bank[3,current]",
      "apc.pdu.bank[4,current]"
    ]
  }
}
```

## Troubleshooting Common Issues

### Issue 1: No Data Received

**Síntomas:**
- Items en estado "Not supported"
- No aparecen discovered items

**Solución:**
```bash
# 1. Verificar conectividad
ping 192.168.1.100

# 2. Verificar puerto SNMP
nmap -sU -p 161 192.168.1.100

# 3. Verificar community string
snmpwalk -v2c -c WRONG_COMMUNITY 192.168.1.100 system
# Debe dar timeout/error

snmpwalk -v2c -c CORRECT_COMMUNITY 192.168.1.100 system
# Debe mostrar datos

# 4. Verificar en Zabbix
Configuration → Hosts → [Your host] → Latest data
# Revisar errores en los items
```

### Issue 2: Solo 1 PDU Detectada

**Síntomas:**
- Discovery encuentra solo 1 PDU cuando hay más

**Posible causa:**
- Solo hay 1 PDU física conectada (NORMAL)
- PDUs adicionales están apagadas
- PDUs adicionales no responden SNMP

**Verificación:**
```bash
# Contar PDUs activas
snmpwalk -v2c -c public 192.168.1.100 \
  1.3.6.1.4.1.318.1.1.26.4.3.1.5 | wc -l

# Debe retornar el número de PDUs activas (1, 2, 3, o 4)
```

### Issue 3: Valores Incorrectos

**Síntomas:**
- Los valores parecen multiplicados por 10 o 100

**Causa:**
- Falta configurar preprocessing (multiplicadores)

**Solución:**
- Verificar que el template tenga los preprocessing steps:
  - Power: × 0.01
  - Current: × 0.1
  - Temperature: × 0.1
  - Power Factor: × 0.01

## Mantenimiento

### Actualizaciones de Firmware

Después de actualizar el firmware de la PDU:

```bash
# 1. Verificar nueva versión
snmpget -v2c -c public 192.168.1.100 1.3.6.1.4.1.318.1.1.4.2.3

# 2. Re-ejecutar discovery en Zabbix
Configuration → Hosts → [Host] → Discovery rules → Execute now

# 3. Verificar logs
tail -f /var/log/zabbix/zabbix_server.log
```

### Backup del Template

```bash
# Exportar template modificado
Configuration → Templates → [Template] → Export

# Guardar en control de versiones
git add apc_8953_template_v1.1.yaml
git commit -m "Update: Added custom thresholds"
```

## Próximos Pasos (Triggers - Futuro)

Cuando estés listo para añadir triggers, aquí hay ejemplos:

```yaml
# Ejemplo de triggers para añadir al template

triggers:
  # Trigger 1: Overload
  - name: 'PDU {#SNMPINDEX}: Overload state detected'
    expression: 'last(/APC PDU 8953 Cascaded/apc.pdu[{#SNMPINDEX},load.state])=4'
    priority: HIGH
    manual_close: YES
    
  # Trigger 2: Near Overload
  - name: 'PDU {#SNMPINDEX}: Near overload'
    expression: 'last(/APC PDU 8953 Cascaded/apc.pdu[{#SNMPINDEX},load.state])=3'
    priority: WARNING
    
  # Trigger 3: High Power
  - name: 'PDU {#SNMPINDEX}: High power consumption'
    expression: 'last(/APC PDU 8953 Cascaded/apc.pdu[{#SNMPINDEX},power])>{$PDU.POWER.HIGH}'
    priority: WARNING
    
  # Trigger 4: Critical Power
  - name: 'PDU {#SNMPINDEX}: Critical power consumption'
    expression: 'last(/APC PDU 8953 Cascaded/apc.pdu[{#SNMPINDEX},power])>{$PDU.POWER.CRITICAL}'
    priority: HIGH
    dependencies:
      - 'PDU {#SNMPINDEX}: High power consumption'
```

## Contacto y Soporte

Para issues o mejoras:
- Revisar documentación: APC_PDU_Template_README.md
- Validar configuración: ./validate_apc_pdu.sh
- Logs de Zabbix: /var/log/zabbix/
- Documentación APC: https://www.apc.com/

---
**Versión:** 1.0  
**Fecha:** 2026-02-03  
**Compatibilidad:** Zabbix 7.4.6+, APC rPDU2 series
