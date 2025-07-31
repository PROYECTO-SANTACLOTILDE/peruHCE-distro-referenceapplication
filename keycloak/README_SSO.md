# Keycloak SSO Integration para OpenMRS PeruHCE

Este documento describe la integración de Single Sign-On (SSO) usando Keycloak para la aplicación OpenMRS PeruHCE. Para cualquier referencia:
https://github.com/icrc/openmrs-distro-sso (ejemplo de implementación)
https://github.com/openmrs/openmrs-module-oauth2login (omod)

## Características

- Autenticación centralizada con Keycloak
- Usuarios predefinidos para diferentes roles
- Integración transparente con el setup existente
- Mantenimiento de la funcionalidad actual

## Configuración

### 1. Variables de Entorno

Copie `template-enviromentVariables.env` a `.env` y configure las variables de Keycloak:

```bash
# Keycloak SSO Variables
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=admin
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak  
POSTGRES_PASSWORD=keycloak
KEYCLOAK_REALM=openmrs
KEYCLOAK_CLIENT_ID=openmrs
KEYCLOAK_CLIENT_SECRET=openmrs-secret
```

### 2. Usuarios Predefinidos

Los siguientes usuarios se crean automáticamente:

| Usuario | Contraseña | Rol | Email |
|---------|------------|-----|-------|
| admin   | Admin123   | System Developer | admin@openmrs.org |
| clerk   | Clerk123   | Data Assistant | clerk@openmrs.org |
| doctor  | Doctor123  | Provider | doctor@openmrs.org |
| nurse   | Nurse123   | Provider | nurse@openmrs.org |

### 3. Servicios

- **Keycloak**: http://localhost:8081
- **OpenMRS**: http://localhost:8080
- **Admin Console Keycloak**: http://localhost:8081/admin

## Despliegue

### Usando script fullInit.sh (Recomendado)

```bash
# Solo OpenMRS (setup original)
cd utils/
./fullInit.sh -m development

# OpenMRS + Keycloak SSO
cd utils/
./fullInit.sh -m development --sso

# Producción con SSO (requiere archivo enviromentVariables.env)
./fullInit.sh -m production --sso
```

### Manual con docker-compose

```bash
# Con SSO (Keycloak)
docker-compose up -d

# Solo aplicación existente (sin SSO)
docker-compose up -d portainer gateway frontend backend db db-replic dns fua-generator fua-generator-db
```

## Configuración OAuth2

### Configuración Automática

Después de iniciar los servicios, ejecute:

```bash
cd utils/
./setup-oauth2.sh
```

Este script:
1. Copia la configuración OAuth2 desde Keycloak al contenedor OpenMRS
2. Proporciona instrucciones para completar la configuración

### Configuración Manual

Si prefiere configurar manualmente, el archivo `oauth2.properties` debe copiarse al directorio de datos de OpenMRS (`/openmrs/data/`) con:

- **Authorization URL**: http://localhost:8081/realms/openmrs/protocol/openid-connect/auth
- **Token URL**: http://localhost:8081/realms/openmrs/protocol/openid-connect/token
- **User Info URL**: http://localhost:8081/realms/openmrs/protocol/openid-connect/userinfo
- **Logout URL**: http://localhost:8081/realms/openmrs/protocol/openid-connect/logout

## Flujo de Autenticación

1. Usuario accede a OpenMRS
2. Es redirigido a Keycloak para autenticación
3. Después de login exitoso, regresa a OpenMRS
4. Se crea/actualiza el usuario en OpenMRS automáticamente

## Personalización

### Agregar Usuarios

Edite el archivo `keycloak/users.csv` y reconstruya el contenedor:

```bash
docker-compose build keycloak
docker-compose up -d keycloak
```

### Modificar Configuración OAuth2

Edite `distro/configuration/oauth2/oauth2.properties` según sus necesidades.

## Troubleshooting

### Problema: Keycloak no inicia
- Verifique que el puerto 8081 esté disponible
- Revise los logs: `docker-compose logs keycloak`

### Problema: OpenMRS no redirige a Keycloak  
- Verifique que el módulo oauth2login esté instalado
- Revise la configuración en `oauth2.properties`

### Problema: Error de autenticación
- Verifique las credenciales del usuario
- Confirme que el realm y client están configurados correctamente

## Mantenimiento

Para mantener solo el setup original sin SSO, simplemente no levante los servicios `keycloak` y `keycloak-db`. El resto de la aplicación funcionará normalmente.