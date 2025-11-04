# 📊 Centralized Logging con Loki - PeruHCE

## Descripción

Stack de logging centralizado usando Grafana Loki para agregación de logs y Promtail como agente de recolección.

## Componentes

- **Loki**: Sistema de agregación de logs (similar a Prometheus pero para logs)
- **Promtail**: Agente que recolecta logs de contenedores Docker
- **Grafana**: Visualización de logs (ya integrado en monitoring stack)

## Inicio Rápido

### Iniciar el stack de logging

```bash
# Con el stack de monitoring completo
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# O solo agregar logging a la configuración existente
docker compose -f docker-compose.yml -f docker-compose.logging.yml up -d
```

### Acceder a los logs

1. **Grafana**: http://localhost:3001
   - Usuario: `admin`
   - Contraseña: (definida en `.env` como `GRAFANA_ADMIN_PASSWORD`)

2. En Grafana, ir a **Explore** (icono de brújula)

3. Seleccionar datasource **Loki**

4. Ejecutar queries LogQL

## Queries LogQL Útiles

### Ver logs por servicio

```logql
{service="backend"}
```

### Filtrar por nivel de log

```logql
{service="backend"} |= "ERROR"
```

### Logs de múltiples servicios

```logql
{service=~"backend|frontend|gateway"}
```

### Buscar texto específico

```logql
{container="peruHCE-backend"} |= "SQLException"
```

### Logs con rate (cuántos logs por segundo)

```logql
rate({service="backend"}[5m])
```

### Top 10 errores

```logql
topk(10, sum by (container) (count_over_time({level="ERROR"}[24h])))
```

### Logs de las últimas 4 horas

```logql
{service="backend"} [4h]
```

## Dashboards Recomendados

### 1. Dashboard de Logs por Servicio

```json
{
  "title": "PeruHCE Logs Overview",
  "panels": [
    {
      "title": "Log Rate by Service",
      "targets": [
        {
          "expr": "sum by (service) (rate({job=\"docker\"}[1m]))"
        }
      ]
    }
  ]
}
```

### 2. Importar Dashboards Pre-construidos

En Grafana:
1. Ir a **Dashboards** → **Import**
2. Usar ID: `13639` (Logs / App)
3. Seleccionar datasource: **Loki**

## Configuración Avanzada

### Ajustar retención de logs

Editar `config/loki/loki-config.yml`:

```yaml
table_manager:
  retention_deletes_enabled: true
  retention_period: 720h  # 30 días (cambiar según necesidad)
```

### Filtrar logs de health checks

Ya está configurado en `config/promtail/promtail-config.yml`:

```yaml
- drop:
    expression: '.*(healthcheck|health_check).*'
    drop_counter_reason: healthcheck
```

### Agregar labels personalizados

Editar `config/promtail/promtail-config.yml` en la sección `relabel_configs`:

```yaml
- source_labels: ['__meta_docker_container_label_com_docker_compose_service']
  target_label: 'service'
```

## Troubleshooting

### Loki no recibe logs

```bash
# Verificar salud de Loki
curl http://localhost:3100/ready

# Ver logs de Promtail
docker logs peruHCE-promtail

# Verificar que Promtail puede conectarse a Loki
docker exec peruHCE-promtail wget -O- http://loki:3100/ready
```

### Promtail no encuentra contenedores

```bash
# Verificar que tiene acceso al socket de Docker
docker exec peruHCE-promtail ls -la /var/run/docker.sock

# Ver posiciones de lectura
docker exec peruHCE-promtail cat /tmp/positions.yaml
```

### Grafana no muestra Loki como datasource

```bash
# Verificar provisioning
docker exec peruHCE-grafana ls -la /etc/grafana/provisioning/datasources/

# Reiniciar Grafana
docker restart peruHCE-grafana
```

## Mejores Prácticas

### 1. Usar Structured Logging en tu aplicación

```java
// Java/OpenMRS
log.info("User login successful",
    kv("userId", userId),
    kv("ipAddress", ipAddress));
```

### 2. Niveles de Log Consistentes

- `ERROR`: Errores que requieren atención inmediata
- `WARN`: Situaciones potencialmente problemáticas
- `INFO`: Eventos informativos importantes
- `DEBUG`: Información detallada para debugging

### 3. Crear Alertas en Grafana

```logql
# Alerta si hay más de 10 errores en 5 minutos
count_over_time({level="ERROR"}[5m]) > 10
```

## Recursos

- [LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [Loki Configuration](https://grafana.com/docs/loki/latest/configuration/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/configuration/)

## Performance

### Uso de Recursos

- **Loki**: ~200MB RAM, depende de ingestion rate
- **Promtail**: ~50MB RAM
- **Disco**: ~1-5GB por día (depende del volumen de logs)

### Optimización

```yaml
# En loki-config.yml para reducir uso de memoria
limits_config:
  ingestion_rate_mb: 4  # Reducir de 10 a 4
  ingestion_burst_size_mb: 6  # Reducir de 20 a 6
```
