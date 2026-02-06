# Template APC PDU 8953 Cascaded - Documentación

## Descripción General

Este template para Zabbix 7.4.6 está diseñado para monitorear regletas APC modelo 8953 que operan en cascada bajo una misma dirección IP.

### Características Principales

- **Soporte para hasta 4 PDUs en cascada** bajo la misma IP
- **Descubrimiento automático (LLD)** de:
  - Dispositivos PDU (hasta 4)
  - Banks/Phases (2 por PDU = hasta 8)
  - Fases de entrada
  - Outlets individuales (hasta 24)
  - Sensores de temperatura/humedad
- **UUID único por cada ítem** (requerimiento Zabbix 7.4+)
- **Sin triggers** (según requerimiento)

## Estructura de Índices SNMP

### Mapeo de PDUs en Cascada

Los índices SNMP se distribuyen de la siguiente manera:

```
PDU Física    │  Índices Device  │  Índices Bank/Phase
──────────────┼──────────────────┼─────────────────────
PDU 1         │        1         │      1, 2
PDU 2         │        2         │      3, 4
PDU 3         │        3         │      5, 6
PDU 4         │        4         │      7, 8
```

### OIDs Principales por Categoría

#### 1. Información del Dispositivo (Items estáticos)

| Métrica | OID | Descripción |
|---------|-----|-------------|
| Model | .1.3.6.1.4.1.318.1.1.26.2.1.6.1 | Modelo del dispositivo |
| Name | .1.3.6.1.4.1.318.1.1.26.2.1.8.1 | Nombre del dispositivo |
| Location | .1.3.6.1.4.1.318.1.1.26.2.1.9.1 | Ubicación |
| Firmware | .1.3.6.1.4.1.318.1.1.4.2.3 | Versión de firmware |
| Serial | .1.3.6.1.4.1.318.1.1.26.4.1.1.3.1 | Número de serie |

#### 2. Métricas por PDU (Discovery: pdu.device.discovery)

Base OID: `.1.3.6.1.4.1.318.1.1.26.4.3.1.X.{#SNMPINDEX}`

| Métrica | Sufijo | Unidad | Factor | Descripción |
|---------|--------|--------|--------|-------------|
| Power | .5 | kW | ×0.01 | Consumo en centésimas de kW |
| Load State | .4 | enum | - | Estado: 1=low, 2=normal, 3=near, 4=over |
| Input Current | .9 | A | ×0.1 | Corriente en décimas de A |
| Energy | .12 | kWh | ×0.1 | Energía acumulada |
| Apparent Power | .16 | VA | - | Potencia aparente |
| Power Factor | .17 | - | ×0.01 | Factor de potencia |

**Ejemplo de valores reales:**
```
.1.3.6.1.4.1.318.1.1.26.4.3.1.5.1 = 125  → 1.25 kW (PDU 1)
.1.3.6.1.4.1.318.1.1.26.4.3.1.5.2 = 98   → 0.98 kW (PDU 2)
.1.3.6.1.4.1.318.1.1.26.4.3.1.4.1 = 2    → Normal (PDU 1)
```

#### 3. Métricas por Bank/Phase (Discovery: pdu.bank.discovery)

Base OID: `.1.3.6.1.4.1.318.1.1.26.8.3.1.X.{#SNMPINDEX}`

| Métrica | Sufijo | Unidad | Factor | Descripción |
|---------|--------|--------|--------|-------------|
| Current | .5 | A | ×0.1 | Corriente del bank |
| Load State | .4 | enum | - | Estado de carga |
| Voltage | .6 | V | - | Voltaje del bank |

**Ejemplo de distribución:**
```
Índice 1,2 → PDU 1 (Bank A y B)
Índice 3,4 → PDU 2 (Bank A y B)
Índice 5,6 → PDU 3 (Bank A y B)
Índice 7,8 → PDU 4 (Bank A y B)
```

#### 4. Métricas por Fase de Entrada (Discovery: pdu.phase.discovery)

Base OID: `.1.3.6.1.4.1.318.1.1.26.6.3.1.X.{#SNMPINDEX}`

| Métrica | Sufijo | Unidad | Factor |
|---------|--------|--------|--------|
| Current | .5 | A | ×0.1 |
| Voltage | .6 | V | - |

#### 5. Métricas por Outlet (Discovery: pdu.outlet.discovery)

Base OID: `.1.3.6.1.4.1.318.1.1.26.9.2.3.1.5.{#SNMPINDEX}`

Detecta hasta 24 outlets individuales.

| Métrica | Unidad | Factor |
|---------|--------|--------|
| Current | A | ×0.1 |

#### 6. Sensores Ambientales (Discovery: pdu.sensor.discovery)

| Métrica | OID | Unidad | Factor |
|---------|-----|--------|--------|
| Temperature | .1.3.6.1.4.1.318.1.1.26.10.2.2.1.8.{#SNMPINDEX} | °C | ×0.1 |
| Humidity | .1.3.6.1.4.1.318.1.1.26.10.2.2.1.10.{#SNMPINDEX} | % | - |

## Instalación

### Paso 1: Importar el Template

```bash
# En la interfaz web de Zabbix:
Configuration → Templates → Import
# Seleccionar archivo: apc_8953_template.yaml
```

### Paso 2: Asignar a un Host

1. Crear/editar host con la IP de la PDU
2. En la pestaña "Templates", añadir: `APC PDU 8953 Cascaded`
3. Configurar interfaz SNMP:
   - SNMP version: SNMPv2
   - SNMP community: `{$SNMP_COMMUNITY}` (por defecto: public)
   - Port: 161

### Paso 3: Configurar Macros (Opcional)

```
{$SNMP_COMMUNITY} = public
{$SNMP_TIMEOUT} = 5s
```

## Verificación

### Comprobar Discovery Rules

Después de 1 hora (o forzar actualización), verificar en:

```
Monitoring → Latest data → [Host] → Discovery rules
```

Deberías ver:
- **PDU Device Discovery**: 1-4 instancias detectadas
- **PDU Bank/Phase Discovery**: 2-8 instancias detectadas
- **PDU Outlet Discovery**: N instancias (según modelo)

### Verificar Items

```
Monitoring → Latest data → [Host]
```

Buscar por tags:
- `Application: PDU 1`
- `Application: PDU 2`
- `Application: Bank 1`
- `Application: Outlet 1`

## Interpretación de Valores

### Load State

| Valor | Estado | Acción Recomendada |
|-------|--------|-------------------|
| 1 | Low Load | Normal |
| 2 | Normal | Normal |
| 3 | Near Overload | ⚠️ Monitorear - redistribuir carga |
| 4 | Overload | 🚨 URGENTE - reducir carga inmediatamente |

### Power Consumption

Los valores vienen en **centésimas de kW**, el template aplica multiplicador 0.01:

```
Valor SNMP = 125 → Template muestra: 1.25 kW
Valor SNMP = 1550 → Template muestra: 15.50 kW
```

### Current

Los valores vienen en **décimas de Amperios**, el template aplica multiplicador 0.1:

```
Valor SNMP = 54 → Template muestra: 5.4 A
Valor SNMP = 125 → Template muestra: 12.5 A
```

## Troubleshooting

### No se detectan PDUs

1. Verificar conectividad SNMP:
```bash
snmpwalk -v2c -c public <IP_PDU> 1.3.6.1.4.1.318.1.1.26.4.3.1.5
```

2. Verificar que el OID base devuelve valores
3. Revisar logs de Zabbix server: `/var/log/zabbix/zabbix_server.log`

### Solo se detecta 1 PDU de 4

Esto es **normal** si solo hay 1 PDU conectada. El template descubre dinámicamente las PDUs presentes.

Para forzar la verificación:
```bash
snmpwalk -v2c -c public <IP_PDU> 1.3.6.1.4.1.318.1.1.26.4.3.1.5
```

Deberías ver algo como:
```
.1.3.6.1.4.1.318.1.1.26.4.3.1.5.1 = INTEGER: 125
.1.3.6.1.4.1.318.1.1.26.4.3.1.5.2 = INTEGER: 98
```

### Valores incorrectos

Verificar que los multiplicadores están aplicados correctamente en la configuración del item.

## Personalización

### Añadir Triggers (futura implementación)

Para añadir triggers después, algunos ejemplos útiles:

```yaml
triggers:
  - name: 'PDU {#SNMPINDEX}: Overload detected'
    expression: 'last(/APC PDU 8953 Cascaded/apc.pdu[{#SNMPINDEX},load.state])=4'
    priority: HIGH
    
  - name: 'PDU {#SNMPINDEX}: High power consumption'
    expression: 'last(/APC PDU 8953 Cascaded/apc.pdu[{#SNMPINDEX},power])>10'
    priority: WARNING
```

### Modificar Intervalos de Polling

En el template YAML, buscar `delay:` y ajustar:

```yaml
delay: 1m   # Polling cada 1 minuto
delay: 5m   # Polling cada 5 minutos
delay: 1h   # Polling cada 1 hora
```

## Notas Técnicas

### Compatibilidad

- **Zabbix**: 7.4.6+
- **Protocolo SNMP**: v2c (recomendado), v3 (soportado)
- **MIB**: PowerNet-MIB v4.x (rPDU2 series)
- **Modelos APC**: 8953, AP89xx series con rPDU2

### Rendimiento

- **Items por PDU individual**: ~7 items
- **Items por Bank**: ~3 items
- **Items por Outlet**: 1 item
- **Total estimado (4 PDUs, 8 Banks, 24 Outlets)**: ~75-100 items activos

### Limitaciones Conocidas

1. **Sin triggers**: Por diseño según requerimiento inicial
2. **Legacy OIDs**: Incluidos para compatibilidad pero pueden no estar presentes en modelos nuevos
3. **Discovery interval**: 1 hora (puede ser ajustado según necesidad)

## Referencias

- PowerNet-MIB: https://www.apc.com/
- Documentación Zabbix LLD: https://www.zabbix.com/documentation/current/en/manual/discovery/low_level_discovery
- OID Reference: http://oidref.com/1.3.6.1.4.1.318.1.1.26

## Changelog

### v1.0 (2026-02-03)
- Versión inicial
- Soporte para hasta 4 PDUs en cascada
- Discovery automático de devices, banks, phases, outlets y sensores
- UUID únicos por item (Zabbix 7.4+)
- Sin triggers (según requerimiento)

## Autor

Template generado para monitoreo de APC PDU 8953 en cascada.

## Licencia

Uso libre para monitoreo de infraestructura APC.
