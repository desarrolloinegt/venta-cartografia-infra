#!/bin/bash

# Colores para los mensajes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con formato
print_message() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}
# Verificar si existe el archivo .env
if [ ! -f ".env" ]; then
    print_error "Archivo .env no encontrado. Por favor, crea el archivo .env primero."
    exit 1
fi
if [ ! -f "./laravel-app/.env" ]; then
    print_error "Archivo .env de LARAVEL no encontrado. Por favor, crea el archivo .env primero."
    exit 1
fi

# Cargar variables del archivo .env
set -a
source .env
set +a

# Detener contenedores existentes
print_message "Deteniendo contenedores existentes..."
docker compose down

# Construir y levantar contenedores
print_message "Construyendo y levantando contenedores..."
docker compose up -d --build

# Esperar a que el contenedor de MySQL esté listo
print_message "Esperando a que MySQL esté listo..."
sleep 10

# Ejecutar comandos en el contenedor de Laravel
print_message "Instalando dependencias y configurando Laravel..."
docker exec laravel composer install --no-interaction --optimize-autoloader
docker exec laravel npm install
docker exec laravel yarn install
docker exec laravel yarn build
docker exec laravel php artisan config:clear
docker exec laravel php artisan cache:clear
docker exec laravel php artisan storage:link
docker exec laravel php artisan config:cache
docker exec laravel php artisan route:cache 
docker exec laravel php artisan view:cache
# Verificar si los contenedores están corriendo
if docker compose ps | grep -q "laravel.*running"; then
    print_success "Despliegue completado exitosamente!"
    print_message "La aplicación está corriendo en: http://localhost:${LARAVEL_PORT:-80}"
    print_message "PhpMyAdmin está disponible en: http://localhost:${PHPMYADMIN_PORT:-8080}"
else
    print_error "Hubo un problema con el despliegue. Por favor, verifica los logs con 'docker compose logs'"
    exit 1
fi