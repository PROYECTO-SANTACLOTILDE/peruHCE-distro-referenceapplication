#!/bin/bash

set -e

echo "=== Despliegue OpenMRS PeruHCE con Keycloak SSO ==="

# Verificar si existe .env
if [ ! -f ".env" ]; then
    echo "Copiando template de variables de entorno..."
    cp template-enviromentVariables.env .env
    echo "⚠️  IMPORTANTE: Edite el archivo .env con sus configuraciones antes de continuar"
    echo "   Especialmente las variables de Keycloak si desea cambiar las por defecto"
    read -p "Presione Enter para continuar cuando haya configurado .env..."
fi

echo "🔍 Validando configuración..."

# Validar docker-compose
if ! docker-compose config --quiet; then
    echo "❌ Error en la configuración de docker-compose"
    exit 1
fi

# Validar Maven
echo "🔍 Validando configuración Maven..."
if ! mvn validate -f distro/pom.xml -q; then
    echo "❌ Error en la configuración Maven"
    exit 1
fi

echo "✅ Configuración validada"

# Opciones de despliegue
echo ""
echo "Seleccione el modo de despliegue:"
echo "1) Completo con SSO (Keycloak + OpenMRS)"
echo "2) Solo OpenMRS (sin SSO - setup original)"
read -p "Ingrese su opción (1-2): " option

case $option in
    1)
        echo "🚀 Desplegando con Keycloak SSO..."
        docker-compose up -d --build
        echo ""
        echo "✅ Despliegue completado!"
        echo ""
        echo "🌐 Servicios disponibles:"
        echo "   - OpenMRS: http://localhost:8080"
        echo "   - Keycloak: http://localhost:8081" 
        echo "   - Keycloak Admin: http://localhost:8081/admin"
        echo ""
        echo "👤 Usuarios predefinidos:"
        echo "   - admin/Admin123 (System Developer)"
        echo "   - doctor/Doctor123 (Provider)"
        echo "   - nurse/Nurse123 (Provider)"
        echo "   - clerk/Clerk123 (Data Assistant)"
        ;;
    2)
        echo "🚀 Desplegando solo OpenMRS (sin SSO)..."
        docker-compose up -d gateway frontend backend db db-replic dns fua-generator fua-generator-db portainer
        echo ""
        echo "✅ Despliegue completado!"
        echo ""
        echo "🌐 Servicios disponibles:"
        echo "   - OpenMRS: http://localhost:8080"
        echo ""
        echo "ℹ️  Login directo con usuarios de OpenMRS"
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "📋 Para ver logs: docker-compose logs -f [servicio]"
echo "🔄 Para reiniciar: docker-compose restart [servicio]"
echo "🛑 Para detener: docker-compose down"