# Guía: 1 Host por PDU Individual en Zabbix

## Arquitectura: 1 Host = 1 PDU Física

Esta es la arquitectura **recomendada** para monitorear PDUs APC 8953 en cascada.

### Ventajas de este Enfoque

✅ **Separación lógica**: Cada PDU es un host independiente  
✅ **Mejor organización**: Más fácil de gestionar en el dashboard  
✅ **Alertas específicas**: Triggers por PDU individual  
✅ **Escalabilidad**: Fácil añadir/quitar PDUs  
✅ **Claridad**: Identificación inmediata de qué PDU tiene problemas  
✅ **Mantenimiento**: Puedes deshabilitar/mantener una PDU sin afectar las demás  
✅ **Graficación**: Gráficos más claros y específicos  

### Comparación con el Enfoque de Cascada

| Aspecto | 1 Host Cascada | 1 Host por PDU |
|---------|----------------|----------------|
| Hosts en Zabbix | 1 | 4 (para 4 PDUs) |
| Claridad | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Gestión | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Triggers específicos | Difícil | Fácil |
| Dashboard | Complejo | Limpio |
| Escalabilidad | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## Estructura de la Configuración

### Escenario: 4 PDUs en Cascada bajo IP 192.168.1.100

```
┌─────────────────────────────────────────────────────────────────┐
│  IP: 192.168.1.100 (Management Interface - COMPARTIDA)         │
└────────────┬────────────────────┬────────────────┬──────────────┘
             │                    │                │
    ┌────────▼────────┐  ┌───────▼────────┐  ┌───▼─────────┐
    │   PDU 1         │  │   PDU 2        │  │   PDU 3     │  ...
    │   Index: 1      │  │   Index: 2     │  │   Index: 3  │
    │   Banks: 1,2    │  │   Banks: 3,4   │  │   Banks: 5,6│
    │   Outlets: 1-8  │  │   Outlets: 9-16│  │   Outlets:  │
    │                 │  │                │  │     17-24   │
    └─────────────────┘  └────────────────┘  └─────────────┘
         │                     │                    │
    ┌────▼─────────┐     ┌────▼─────────┐    ┌────▼─────────┐
    │ Zabbix Host: │     │ Zabbix Host: │    │ Zabbix Host: │
    │ PDU-A1-U1    │     │ PDU-A1-U2    │    │ PDU-A1-U3    │
    │ Macros:      │     │ Macros:      │    │ Macros:      │
    │ INDEX=1      │     │ INDEX=2      │    │ INDEX=3      │
    │ BANK.START=1 │     │ BANK.START=3 │    │ BANK.START=5 │
    └──────────────┘     └──────────────┘    └──────────────┘
```

---

## Tabla de Mapeo de Índices

### Para configurar las macros de cada host:

| Host Name | PDU # | {$PDU.INDEX} | {$PDU.BANK.START} | {$PDU.OUTLET.START} | Outlets Range |
|-----------|-------|--------------|-------------------|---------------------|---------------|
| PDU-RackA1-Unit1 | 1 | 1 | 1 | 1 | 1-8 |
| PDU-RackA1-Unit2 | 2 | 2 | 3 | 9 | 9-16 |
| PDU-RackA1-Unit3 | 3 | 3 | 5 | 17 | 17-24 |
| PDU-RackA1-Unit4 | 4 | 4 | 7 | 25 | 25-32 |

**Nota sobre outlets**: El rango exacto depende del modelo físico. Ajustar según tu configuración real.

---

## Configuración Paso a Paso

### Paso 1: Importar el Template

```
Configuration → Templates → Import
Archivo: apc_8953_single_unit_template.yaml
```

### Paso 2: Crear Hosts Individuales

#### Host 1: PDU Unit 1

**Configuración del Host:**
```
Configuration → Hosts → Create host

Host tab:
  Host name: PDU-RackA1-Unit1
  Visible name: APC PDU Rack A1 - Unit 1
  Groups: PDUs / Data Center / Rack A1
  Interfaces:
    - Type: SNMP
    - IP address: 192.168.1.100  ← MISMA IP para todas
    - Port: 161
```

**SNMP Configuration (SNMPv3):**
```
SNMP version: SNMPv3
Security name: zabbix_monitor
Security level: authPriv
Authentication protocol: SHA256
Authentication passphrase: TuPasswordAuth123!
Privacy protocol: AES256
Privacy passphrase: TuPasswordPriv456!
```

**Templates:**
```
Link new templates: APC PDU 8953 Single Unit
```

**Macros:**
```
{$PDU.INDEX} = 1
{$PDU.BANK.START} = 1
{$PDU.OUTLET.START} = 1
{$PDU.OUTLET.COUNT} = 8
```

#### Host 2: PDU Unit 2

```
Host name: PDU-RackA1-Unit2
Visible name: APC PDU Rack A1 - Unit 2
IP: 192.168.1.100  ← MISMA IP
SNMP: [misma configuración SNMPv3]

Macros:
{$PDU.INDEX} = 2
{$PDU.BANK.START} = 3
{$PDU.OUTLET.START} = 9
{$PDU.OUTLET.COUNT} = 8
```

#### Host 3: PDU Unit 3

```
Host name: PDU-RackA1-Unit3
Visible name: APC PDU Rack A1 - Unit 3
IP: 192.168.1.100  ← MISMA IP
SNMP: [misma configuración SNMPv3]

Macros:
{$PDU.INDEX} = 3
{$PDU.BANK.START} = 5
{$PDU.OUTLET.START} = 17
{$PDU.OUTLET.COUNT} = 8
```

#### Host 4: PDU Unit 4

```
Host name: PDU-RackA1-Unit4
Visible name: APC PDU Rack A1 - Unit 4
IP: 192.168.1.100  ← MISMA IP
SNMP: [misma configuración SNMPv3]

Macros:
{$PDU.INDEX} = 4
{$PDU.BANK.START} = 7
{$PDU.OUTLET.START} = 25
{$PDU.OUTLET.COUNT} = 8
```

---

## Script de Creación Automática via API

Para automatizar la creación de los 4 hosts:

```bash
#!/bin/bash

# Configuración
ZABBIX_URL="http://zabbix.example.com/api_jsonrpc.php"
AUTH_TOKEN="YOUR_AUTH_TOKEN"
TEMPLATE_ID="XXXXX"  # ID del template importado
GROUP_ID="XX"        # ID del grupo de hosts
PDU_IP="192.168.1.100"
SNMP_USER="zabbix_monitor"
SNMP_AUTH_PASS="TuPasswordAuth123!"
SNMP_PRIV_PASS="TuPasswordPriv456!"

# Crear Host 1
curl -X POST "$ZABBIX_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "host.create",
    "params": {
      "host": "PDU-RackA1-Unit1",
      "name": "APC PDU Rack A1 - Unit 1",
      "interfaces": [{
        "type": 2,
        "main": 1,
        "useip": 1,
        "ip": "'"$PDU_IP"'",
        "port": "161",
        "details": {
          "version": 3,
          "securityname": "'"$SNMP_USER"'",
          "securitylevel": 2,
          "authprotocol": 2,
          "authpassphrase": "'"$SNMP_AUTH_PASS"'",
          "privprotocol": 2,
          "privpassphrase": "'"$SNMP_PRIV_PASS"'"
        }
      }],
      "groups": [{"groupid": "'"$GROUP_ID"'"}],
      "templates": [{"templateid": "'"$TEMPLATE_ID"'"}],
      "macros": [
        {"macro": "{$PDU.INDEX}", "value": "1"},
        {"macro": "{$PDU.BANK.START}", "value": "1"},
        {"macro": "{$PDU.OUTLET.START}", "value": "1"},
        {"macro": "{$PDU.OUTLET.COUNT}", "value": "8"}
      ]
    },
    "auth": "'"$AUTH_TOKEN"'",
    "id": 1
  }'

# Repetir para hosts 2, 3, 4 con valores ajustados...
```

---

## Verificación de la Configuración

### Verificar que cada host consulta los índices correctos:

```bash
# Verificar PDU 1 (índice 1)
snmpget -v3 -l authPriv \
  -u zabbix_monitor \
  -a SHA256 -A TuPasswordAuth123! \
  -x AES256 -X TuPasswordPriv456! \
  192.168.1.100 \
  1.3.6.1.4.1.318.1.1.26.4.3.1.5.1

# Verificar PDU 2 (índice 2)
snmpget -v3 -l authPriv \
  -u zabbix_monitor \
  -a SHA256 -A TuPasswordAuth123! \
  -x AES256 -X TuPasswordPriv456! \
  192.168.1.100 \
  1.3.6.1.4.1.318.1.1.26.4.3.1.5.2

# Verificar Banks de PDU 1 (índices 1,2)
snmpget -v3 -l authPriv \
  -u zabbix_monitor \
  -a SHA256 -A TuPasswordAuth123! \
  -x AES256 -X TuPasswordPriv456! \
  192.168.1.100 \
  1.3.6.1.4.1.318.1.1.26.8.3.1.5.1 \
  1.3.6.1.4.1.318.1.1.26.8.3.1.5.2

# Verificar Banks de PDU 2 (índices 3,4)
snmpget -v3 -l authPriv \
  -u zabbix_monitor \
  -a SHA256 -A TuPasswordAuth123! \
  -x AES256 -X TuPasswordPriv456! \
  192.168.1.100 \
  1.3.6.1.4.1.318.1.1.26.8.3.1.5.3 \
  1.3.6.1.4.1.318.1.1.26.8.3.1.5.4
```

### En Zabbix GUI:

```
Monitoring → Latest data

Filtrar por:
- Host: PDU-RackA1-Unit1
- Application: Power Metrics

Deberías ver:
✅ Power Consumption (valor en kW)
✅ Load State (1-4)
✅ Input Current (valor en A)
✅ Bank A: Current
✅ Bank B: Current
```

---

## Dashboard Recomendado

### Crear Dashboard "PDU Rack A1 Overview"

```
┌────────────────────────────────────────────────────────────────┐
│ PDU Rack A1 - Power Overview                                  │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Total Power Consumption (All Units)                          │
│  ┌──────────────────────────────────────────────────┐        │
│  │ [Stacked Graph]                                   │        │
│  │ Unit 1: 1.2 kW                                    │        │
│  │ Unit 2: 1.5 kW                                    │        │
│  │ Unit 3: 0.8 kW                                    │        │
│  │ Unit 4: 1.1 kW                                    │        │
│  │ TOTAL: 4.6 kW                                     │        │
│  └──────────────────────────────────────────────────┘        │
│                                                                │
│  Individual Unit Status                                       │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐  │
│  │ Unit 1      │ Unit 2      │ Unit 3      │ Unit 4      │  │
│  │ 1.2 kW      │ 1.5 kW      │ 0.8 kW      │ 1.1 kW      │  │
│  │ Normal      │ Normal      │ Normal      │ Normal      │  │
│  │ 5.4 A       │ 6.8 A       │ 3.6 A       │ 5.0 A       │  │
│  │ Bank A: OK  │ Bank A: OK  │ Bank A: OK  │ Bank A: OK  │  │
│  │ Bank B: OK  │ Bank B: OK  │ Bank B: OK  │ Bank B: OK  │  │
│  └─────────────┴─────────────┴─────────────┴─────────────┘  │
│                                                                │
│  Current Distribution per Bank                                │
│  ┌──────────────────────────────────────────────────┐        │
│  │ [Bar Chart]                                       │        │
│  │ Unit1-BankA ████████ 5.4A                        │        │
│  │ Unit1-BankB ████████ 5.8A                        │        │
│  │ Unit2-BankA █████████ 6.8A                       │        │
│  │ Unit2-BankB █████████ 6.2A                       │        │
│  │ ...                                               │        │
│  └──────────────────────────────────────────────────┘        │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Widget de Power Gauge por PDU:

```json
{
  "type": "gauge",
  "name": "PDU Unit 1 Power",
  "fields": {
    "itemid": "apc.pdu.power",
    "host": "PDU-RackA1-Unit1",
    "min": "0",
    "max": "5",
    "thresholds": "0,3:green;3,4:yellow;4,5:red"
  }
}
```

---

## Triggers Específicos por PDU

Con este enfoque puedes crear triggers mucho más específicos:

```yaml
# Ejemplo de trigger para PDU Unit 1
triggers:
  - name: 'PDU Rack A1 Unit 1: Overload detected'
    expression: 'last(/PDU-RackA1-Unit1/apc.pdu.load.state)=4'
    priority: HIGH
    description: 'La PDU Unit 1 está en estado de overload'
    
  - name: 'PDU Rack A1 Unit 1: High power consumption'
    expression: 'last(/PDU-RackA1-Unit1/apc.pdu.power)>3'
    priority: WARNING
    description: 'La PDU Unit 1 está consumiendo más de 3 kW'
    
  - name: 'PDU Rack A1 Unit 1: Bank A imbalance'
    expression: 'abs(last(/PDU-RackA1-Unit1/apc.pdu.bank.a.current)-last(/PDU-RackA1-Unit1/apc.pdu.bank.b.current))>5'
    priority: WARNING
    description: 'Desbalance de corriente entre Bank A y B mayor a 5A'
```

---

## Ventajas para Mantenimiento

### Deshabilitar una PDU sin afectar las demás:

```
1. Configuration → Hosts → PDU-RackA1-Unit2
2. Status → Disabled
```

Ahora Unit 2 no se monitorea, pero Units 1, 3, 4 siguen activas.

### Añadir una nueva PDU:

```
1. Crear nuevo host: PDU-RackA1-Unit5
2. IP: 192.168.1.100 (misma)
3. Macros:
   {$PDU.INDEX} = 5
   {$PDU.BANK.START} = 9
   {$PDU.OUTLET.START} = 33
4. Done!
```

---

## Host Groups Recomendados

Organizar los hosts en grupos lógicos:

```
PDUs
├── Data Center
│   ├── Rack A1
│   │   ├── PDU-RackA1-Unit1
│   │   ├── PDU-RackA1-Unit2
│   │   ├── PDU-RackA1-Unit3
│   │   └── PDU-RackA1-Unit4
│   ├── Rack A2
│   │   ├── PDU-RackA2-Unit1
│   │   └── PDU-RackA2-Unit2
│   └── Rack B1
│       └── PDU-RackB1-Unit1
└── Critical Infrastructure
    └── [Los 4 PDUs del Rack A1 también aquí]
```

---

## Naming Convention Recomendada

```
PDU-<Ubicación>-<Rack>-Unit<Número>

Ejemplos:
- PDU-DC1-RackA1-Unit1
- PDU-DC1-RackA1-Unit2
- PDU-DC2-RackB5-Unit1
- PDU-Office-Network-Unit1
```

Esto permite:
- Identificación rápida de ubicación
- Filtrado fácil en dashboards
- Organización lógica
- Scripts automatizados

---

## Migración desde Template de Cascada

Si ya tienes el template de cascada configurado:

### Opción 1: Migración Manual

1. Crear los 4 nuevos hosts con el template Single Unit
2. Configurar las macros correctamente
3. Esperar 1-2 horas para acumular datos
4. Verificar que todo funciona
5. Deshabilitar el host de cascada
6. Después de 1 semana, eliminar el host de cascada

### Opción 2: Convivencia

Puedes mantener ambos enfoques simultáneamente:
- Host cascada: Vista general rápida
- Hosts individuales: Análisis detallado

---

## Troubleshooting

### Problema: "No data" en algunos hosts

**Verificar macros:**
```bash
# Revisar que cada host tenga las macros correctas
Configuration → Hosts → [Host] → Macros

Debe tener:
{$PDU.INDEX} = [valor correcto]
{$PDU.BANK.START} = [valor correcto]
```

**Verificar índices SNMP:**
```bash
# Probar el índice específico
snmpget -v3 ... IP 1.3.6.1.4.1.318.1.1.26.4.3.1.5.<PDU.INDEX>
```

### Problema: Todos los hosts muestran los mismos datos

**Causa:** Todos tienen `{$PDU.INDEX} = 1`

**Solución:** Verificar y corregir las macros de cada host

---

## Resumen de Beneficios

| Beneficio | Descripción |
|-----------|-------------|
| 🎯 **Claridad** | Identificación inmediata de problemas por PDU |
| 📊 **Dashboards** | Visualización limpia y organizada |
| 🚨 **Alertas** | Triggers específicos por unidad |
| 🔧 **Mantenimiento** | Habilitar/deshabilitar PDUs individualmente |
| 📈 **Escalabilidad** | Fácil añadir nuevas PDUs |
| 🏷️ **Organización** | Host groups lógicos por ubicación |
| 📱 **Reportes** | Reportes por PDU individual |
| 💾 **SLAs** | Seguimiento de SLA por unidad |

---

## Próximos Pasos

1. ✅ Importar template `apc_8953_single_unit_template.yaml`
2. ✅ Crear hosts para cada PDU física
3. ✅ Configurar macros correctamente
4. ✅ Validar conectividad SNMP
5. ✅ Crear dashboard personalizado
6. ✅ Configurar triggers (próxima fase)
7. ✅ Documentar configuración específica

---

**Versión:** 1.0  
**Fecha:** 2026-02-03  
**Recomendación:** Este enfoque es ideal para producción
