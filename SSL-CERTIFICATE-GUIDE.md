# Guía de Certificados SSL para peruHCE

Esta guía explica cómo usar y administrar certificados SSL en la distribución peruHCE.

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Arquitectura SSL](#arquitectura-ssl)
3. [Configuración Rápida](#configuración-rápida)
4. [Configuración Avanzada](#configuración-avanzada)
5. [Instalación de Certificados en Clientes](#instalación-de-certificados-en-clientes)
6. [Renovación de Certificados](#renovación-de-certificados)
7. [Solución de Problemas](#solución-de-problemas)
8. [Mejores Prácticas de Seguridad](#mejores-prácticas-de-seguridad)

---

## Introducción

peruHCE utiliza certificados SSL auto-firmados diseñados para redes hospitalarias internas. Esta implementación está basada en el proyecto OpenMRS Reference Application pero optimizada para despliegues en entornos sin acceso a DNS público o internet.

### Características Principales

- ✅ Certificados auto-firmados con RSA 4096 bits
- ✅ Soporte para múltiples dominios e IPs (SubjectAltName)
- ✅ Renovación automática opcional
- ✅ Headers de seguridad HTTP mejorados (HSTS, CSP, etc.)
- ✅ Configuración de cifrado moderno (TLS 1.2/1.3)
- ✅ Parámetros Diffie-Hellman de 4096 bits

---

## Arquitectura SSL

### Estructura de Directorios

```
peruHCE-distro-referenceapplication/
├── certbot/                          # Servicio de gestión de certificados
│   ├── Dockerfile
│   └── scripts/
│       └── entrypoint.sh            # Script de generación/renovación
├── gateway/                          # Nginx reverse proxy
│   ├── Dockerfile
│   ├── docker-entrypoint.sh         # Selector de configuración SSL
│   ├── watch-certs.sh               # Monitor de renovación
│   ├── default.conf.template        # Configuración HTTP
│   ├── default-ssl.conf.template    # Configuración HTTPS
│   └── nginx.conf
└── docker-compose.ssl.yml           # Composición para SSL
```

### Componentes

1. **Servicio Certbot**: Genera y renueva certificados auto-firmados
2. **Gateway SSL**: Nginx configurado para HTTPS con headers de seguridad
3. **Volúmenes Compartidos**: Certificados compartidos entre certbot y gateway

---

## Configuración Rápida

### Opción 1: Modo Desarrollo (Generación Única)

Ideal para desarrollo y testing:

```bash
# 1. Iniciar servicios con SSL
docker compose -f docker-compose.yml -f docker-compose-prod.yml -f docker-compose.ssl.yml up -d

# 2. Verificar generación de certificados
docker logs peruHCE-certbot

# 3. Acceder a la aplicación
https://localhost
# o
https://192.168.0.200
# o
https://sihsalus.hsc
```

### Opción 2: Modo Producción (Con Auto-Renovación)

Para ambientes productivos con renovación automática cada 30 días:

```bash
# 1. Configurar variables de entorno
export SSL_MODE=prod

# 2. Iniciar servicios
docker compose -f docker-compose.yml -f docker-compose-prod.yml -f docker-compose.ssl.yml up -d

# El servicio certbot permanecerá activo y renovará automáticamente
```

---

## Configuración Avanzada

### Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto:

```bash
# Modo SSL: 'dev' para generación única, 'prod' para auto-renovación
SSL_MODE=dev

# Dominios e IPs (separados por comas)
CERT_WEB_DOMAINS=localhost,127.0.0.1,192.168.0.200,sihsalus.hsc,openmrs.sihsalus.hsc

# Nombre común del certificado (primer dominio por defecto)
CERT_WEB_DOMAIN_COMMON_NAME=sihsalus.hsc

# Parámetros del certificado
CERT_RSA_KEY_SIZE=4096
CERT_TEMP_CERT_DAYS=365
CERT_RENEWAL_INTERVAL=30d

# Información de la organización
CERT_ORG=Centro de Salud Santa Clotilde
CERT_OU=sihsalus
CERT_COUNTRY=PE
CERT_STATE=Loreto
CERT_LOCALITY=Maynas

# Headers de seguridad
FRAME_ANCESTORS=https://dyaku.minsa.gob.pe/fhir
```

### Personalización de Dominios

Para agregar más dominios o IPs:

```bash
CERT_WEB_DOMAINS=localhost,127.0.0.1,192.168.0.200,192.168.0.201,sihsalus.hsc,openmrs.sihsalus.hsc,hospital.local
```

### Headers de Seguridad HTTP

El sistema incluye los siguientes headers de seguridad:

- **Strict-Transport-Security (HSTS)**: Fuerza HTTPS por 1 año
- **X-Frame-Options**: Previene clickjacking
- **X-XSS-Protection**: Protección contra XSS
- **X-Content-Type-Options**: Previene MIME sniffing
- **Content-Security-Policy**: Política de contenido configurable
- **Referrer-Policy**: Control de información de referencia

---

## Instalación de Certificados en Clientes

Para evitar advertencias de seguridad en los navegadores, instala el certificado en los dispositivos clientes.

### Extraer el Certificado

```bash
# Opción 1: Copiar desde el volumen de Docker
docker cp peruHCE-certbot:/etc/letsencrypt/live/sihsalus.hsc/fullchain.pem ./sihsalus.crt

# Opción 2: Descargar desde el navegador
# 1. Visita https://sihsalus.hsc
# 2. Clic en el candado > "Certificado no seguro"
# 3. Exportar certificado
```

### Windows

1. Doble clic en `sihsalus.crt`
2. Clic en "Instalar certificado..."
3. Seleccionar "Máquina local"
4. Elegir "Colocar todos los certificados en el siguiente almacén"
5. Seleccionar "Entidades de certificación raíz de confianza"
6. Finalizar

**PowerShell (como administrador):**
```powershell
Import-Certificate -FilePath ".\sihsalus.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

### Linux (Ubuntu/Debian)

```bash
# Copiar certificado
sudo cp sihsalus.crt /usr/local/share/ca-certificates/sihsalus.crt

# Actualizar almacén de certificados
sudo update-ca-certificates

# Verificar
openssl verify /usr/local/share/ca-certificates/sihsalus.crt
```

### Linux (RHEL/CentOS/Fedora)

```bash
# Copiar certificado
sudo cp sihsalus.crt /etc/pki/ca-trust/source/anchors/

# Actualizar
sudo update-ca-trust

# Verificar
trust list | grep sihsalus
```

### macOS

**Interfaz gráfica:**
1. Doble clic en `sihsalus.crt`
2. Se abre "Acceso a Llaveros"
3. Seleccionar llavero "Sistema"
4. Doble clic en el certificado instalado
5. Expandir "Confianza"
6. Seleccionar "Confiar siempre" en "Al usar este certificado"

**Terminal:**
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain sihsalus.crt
```

### Navegadores (Chrome, Firefox, Edge)

#### Firefox (Configuración independiente)

1. Configuración > Privacidad y seguridad
2. Certificados > Ver certificados
3. Autoridades > Importar
4. Seleccionar `sihsalus.crt`
5. Marcar "Confiar en esta CA para identificar sitios web"

#### Chrome/Edge (usan certificados del sistema)

En Windows/macOS/Linux: Instalar el certificado en el sistema operativo (ver arriba).

---

## Renovación de Certificados

### Renovación Automática (Modo Producción)

En modo `SSL_MODE=prod`, el servicio certbot monitorea el certificado y lo renueva automáticamente cuando quedan menos de 30 días de validez.

```bash
# Verificar logs de renovación
docker logs -f peruHCE-certbot

# Forzar verificación manual
docker exec peruHCE-certbot sh -c "echo 'Manual check triggered'"
```

### Renovación Manual

```bash
# Opción 1: Regenerar certificado
docker compose -f docker-compose.yml -f docker-compose-prod.yml -f docker-compose.ssl.yml down
docker volume rm peruHCE-letsencrypt-data
docker compose -f docker-compose.yml -f docker-compose-prod.yml -f docker-compose.ssl.yml up -d

# Opción 2: Usar el script legacy
cd scripts/utils
./certificate_generate.sh
```

### Verificar Fecha de Expiración

```bash
# Dentro del contenedor certbot
docker exec peruHCE-certbot openssl x509 -enddate -noout -in /etc/letsencrypt/live/sihsalus.hsc/fullchain.pem

# Desde el host (si tienes openssl)
docker cp peruHCE-certbot:/etc/letsencrypt/live/sihsalus.hsc/fullchain.pem ./temp.crt
openssl x509 -enddate -noout -in temp.crt
rm temp.crt
```

---

## Solución de Problemas

### Problema: "ERR_CERT_AUTHORITY_INVALID" en el navegador

**Causa**: El certificado auto-firmado no está instalado en el sistema.

**Solución**: Instalar el certificado según la sección [Instalación de Certificados](#instalación-de-certificados-en-clientes).

---

### Problema: Gateway no inicia con SSL

**Verificar**:
```bash
# Ver logs del gateway
docker logs peruHCE-gateway

# Ver logs de certbot
docker logs peruHCE-certbot

# Verificar que los certificados existen
docker exec peruHCE-certbot ls -la /etc/letsencrypt/live/sihsalus.hsc/
```

**Soluciones**:
1. Asegurar que certbot generó los certificados primero
2. Verificar que la variable `CERT_WEB_DOMAIN_COMMON_NAME` coincide
3. Reiniciar servicios en orden: certbot → gateway

---

### Problema: Certificado no se renueva automáticamente

**Verificar**:
```bash
# Ver si el servicio está corriendo
docker ps | grep certbot

# Ver logs
docker logs peruHCE-certbot

# Verificar configuración
docker exec peruHCE-certbot env | grep SSL_MODE
```

**Solución**: Asegurar que `SSL_MODE=prod` está configurado.

---

### Problema: Nginx no recarga después de renovación

**Verificar**:
```bash
# Ver si watch-certs está corriendo
docker exec peruHCE-gateway ps aux | grep watch-certs

# Verificar señal de reload
docker exec peruHCE-gateway ls -la /var/www/certbot/.reload-nginx
```

**Solución**:
```bash
# Recargar nginx manualmente
docker exec peruHCE-gateway nginx -s reload
```

---

### Problema: "Permission denied" al acceder a certificados

**Causa**: Permisos incorrectos en volúmenes.

**Solución**:
```bash
# Recrear volúmenes
docker compose -f docker-compose.yml -f docker-compose-prod.yml -f docker-compose.ssl.yml down -v
docker compose -f docker-compose.yml -f docker-compose-prod.yml -f docker-compose.ssl.yml up -d
```

---

## Mejores Prácticas de Seguridad

### 1. Renovación Regular

- Configurar `SSL_MODE=prod` en ambientes productivos
- Renovar certificados al menos 30 días antes del vencimiento
- Monitorear logs de renovación semanalmente

### 2. Protección de Claves Privadas

```bash
# Verificar permisos
docker exec peruHCE-certbot ls -la /etc/letsencrypt/live/sihsalus.hsc/privkey.pem

# Debe mostrar: -rw------- (600)
```

### 3. Distribución de Certificados

- **NUNCA** distribuir la clave privada (`.key` o `privkey.pem`)
- **SOLO** distribuir el certificado público (`.crt` o `fullchain.pem`)
- Usar canales seguros (USB, correo cifrado, etc.)

### 4. Monitoreo de Seguridad

```bash
# Test SSL/TLS (desde otro host en la red)
openssl s_client -connect sihsalus.hsc:443 -showcerts

# Verificar headers de seguridad
curl -I https://sihsalus.hsc
```

### 5. Respaldo de Certificados

```bash
# Respaldo completo
docker run --rm -v peruHCE-letsencrypt-data:/data -v $(pwd):/backup alpine tar czf /backup/certificates-backup-$(date +%Y%m%d).tar.gz -C /data .

# Restauración
docker run --rm -v peruHCE-letsencrypt-data:/data -v $(pwd):/backup alpine tar xzf /backup/certificates-backup-YYYYMMDD.tar.gz -C /data
```

### 6. Actualización de Configuración SSL

Mantener actualizadas las configuraciones de cifrado:

```bash
# Revisar configuración actual
docker exec peruHCE-gateway cat /var/www/certbot/conf/options-ssl-nginx.conf

# Después de actualizar, recargar
docker exec peruHCE-gateway nginx -s reload
```

---

## Comparación con OpenMRS Base

### Similitudes

- Estructura de directorios `certbot/` y `gateway/`
- Scripts `watch-certs.sh` y `docker-entrypoint.sh`
- Uso de volúmenes compartidos
- Soporte para múltiples dominios

### Mejoras en peruHCE

| Característica | OpenMRS Base | peruHCE |
|---------------|--------------|---------|
| **RSA Key Size** | 4096 bits (opcional) | 4096 bits (por defecto) |
| **Validez** | 90 días | 365 días (configurable) |
| **Renovación** | Let's Encrypt | Auto-renovación interna |
| **DH Params** | 2048 bits (dev) | 4096 bits |
| **Headers** | Básicos | HSTS + adicionales |
| **Docs** | Básica | Completa (este doc) |
| **Red interna** | Requiere internet | 100% offline |

---

## Referencias

- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Nginx SSL Module](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [OWASP Secure Headers](https://owasp.org/www-project-secure-headers/)

---

## Soporte

Para reportar problemas o sugerir mejoras:

1. Revisar esta guía completa
2. Verificar logs de los contenedores
3. Consultar con el equipo de TI del centro de salud
4. Crear un issue en el repositorio del proyecto

---

**Última actualización**: Octubre 2025
**Versión del documento**: 1.0.0
**Mantenido por**: Equipo peruHCE - Centro de Salud Santa Clotilde
