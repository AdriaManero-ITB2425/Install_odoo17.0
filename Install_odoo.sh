#!/bin/bash

set -e

# ===== PREGUNTAR RUTA DE INSTALACIÓN =====
while true; do
    read -p "📁 Introduce la ruta absoluta donde instalar Odoo (ej: /opt/odoo): " ODOO_DIR
    if [[ "$ODOO_DIR" == /* ]]; then
        break
    else
        echo "❌ La ruta debe empezar por '/'."
    fi
done

# ===== PREGUNTAR USUARIO DEL SISTEMA =====
while true; do
    read -p "👤 Introduce el nombre del usuario del sistema que ejecutará Odoo: " SYSTEM_USER
    if id "$SYSTEM_USER" &>/dev/null; then
        DB_NAME="$SYSTEM_USER"
        break
    else
        echo "❌ El usuario '$SYSTEM_USER' no existe en el sistema."
    fi
done

echo
echo "📦 Ruta de instalación: $ODOO_DIR"
echo "👤 Usuario del sistema: $SYSTEM_USER"
echo "🗄️  Base de datos PostgreSQL: $DB_NAME"
echo

read -p "¿Deseas continuar con la instalación? (s/n): " CONFIRM
if [[ "$CONFIRM" != "s" ]]; then
    echo "❌ Instalación cancelada."
    exit 1
fi

# ===== INSTALAR DEPENDENCIAS =====
echo "==== Instalando dependencias necesarias ===="
sudo apt update
sudo apt install -y git python3 python3-pip postgresql postgresql-client

# ===== CREAR RUTA Y DAR PERMISOS =====
echo "==== Creando directorio de instalación: $ODOO_DIR ===="
sudo mkdir -p "$ODOO_DIR"
sudo chown -R "$SYSTEM_USER:$SYSTEM_USER" "$ODOO_DIR"

# ===== CLONAR ODOO =====
echo "==== Clonando Odoo versión 17.0 ===="
sudo -u "$SYSTEM_USER" git clone --depth 1 --branch 17.0 --single-branch https://github.com/odoo/odoo.git "$ODOO_DIR"

# ===== INSTALAR DEPENDENCIAS DE ODOO =====
cd "$ODOO_DIR"
echo "==== Ejecutando script de instalación de dependencias de Odoo ===="
sudo ./setup/debinstall.sh

# ===== CREAR USUARIO Y BASE DE DATOS EN POSTGRES =====
echo "==== Creando usuario y base de datos en PostgreSQL ===="
sudo -u postgres createuser -d -R -S "$SYSTEM_USER" || echo "🔄 Usuario de PostgreSQL ya existe"
createdb "$DB_NAME" || echo "🔄 Base de datos ya existe"

# ===== INICIALIZAR BASE DE DATOS =====
echo "==== Inicializando base de datos '$DB_NAME' ===="
sudo -u "$SYSTEM_USER" python3 "$ODOO_DIR/odoo-bin" -d "$DB_NAME" -i base --without-demo=all --save

# ===== MENSAJE FINAL =====
echo
echo "✅ Odoo 17 ha sido instalado exitosamente para el usuario '$SYSTEM_USER'."
echo
echo "👉 Para volver a iniciar Odoo más tarde, ejecuta:"
echo
echo "    sudo -u $SYSTEM_USER python3 $ODOO_DIRodoo-bin -d $DB_NAME"
echo
echo "🔐 La contraseña del superadministrador la establecerás en el navegador la primera vez que accedas."
echo
