#!/bin/bash
# INSTALADOR RÁPIDO ytdlp-wrapper

echo "=== Instalando ytdlp-wrapper ==="
echo ""

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar mensajes de error
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}"
    echo "Instalación abortada."
    exit 1
}

# Función para mostrar mensajes de éxito
success_msg() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Función para mostrar advertencias
warning_msg() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Verificar que estamos en el directorio correcto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar dependencias
echo "Verificando dependencias..."

# Verificar Python
if ! command -v python3 &> /dev/null; then
    error_exit "Python3 no está instalado. Por favor instala Python3 primero."
fi

# Verificar pip
if ! command -v pip &> /dev/null && ! python3 -m pip --version &> /dev/null; then
    warning_msg "pip no está instalado. Intentando instalar pip..."
    python3 -m ensurepip --upgrade || error_exit "No se pudo instalar pip."
fi

# Verificar que el archivo wrapper existe
if [ ! -f "ytdlp_wrapper.py" ]; then
    error_exit "El archivo 'ytdlp_wrapper.py' no se encuentra en el directorio actual."
fi

# Directorios
INSTALL_DIR="$HOME/.local/share/ytdlp-wrapper"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/ytdlp-wrapper"
DOWNLOADS_DIR="$HOME/ytdlp-downloads"

# Verificar permisos de escritura
echo "Verificando permisos..."

if [ ! -w "$HOME/.local" ] && [ ! -w "$(dirname "$INSTALL_DIR")" ]; then
    if [ ! -d "$HOME/.local" ]; then
        mkdir -p "$HOME/.local" || error_exit "No se pudo crear directorio .local"
    else
        error_exit "No tienes permisos de escritura en $HOME/.local"
    fi
fi

# Crear directorios
echo "Creando directorios..."
mkdir -p "$INSTALL_DIR" || error_exit "No se pudo crear $INSTALL_DIR"
mkdir -p "$BIN_DIR" || error_exit "No se pudo crear $BIN_DIR"
mkdir -p "$CONFIG_DIR" || error_exit "No se pudo crear $CONFIG_DIR"
mkdir -p "$DOWNLOADS_DIR" || error_exit "No se pudo crear $DOWNLOADS_DIR"

# Copiar el wrapper
echo "Copiando script principal..."
cp "ytdlp_wrapper.py" "$INSTALL_DIR/" || error_exit "No se pudo copiar ytdlp_wrapper.py"
chmod +x "$INSTALL_DIR/ytdlp_wrapper.py" || error_exit "No se pudo dar permisos de ejecución"

# Crear entorno virtual e instalar yt-dlp
echo "Creando entorno virtual Python..."
python3 -m venv "$INSTALL_DIR/venv" || error_exit "No se pudo crear entorno virtual"

echo "Instalando yt-dlp..."
# Usar . en lugar de source para mayor compatibilidad
if [ -f "$INSTALL_DIR/venv/bin/activate" ]; then
    . "$INSTALL_DIR/venv/bin/activate"
    pip install --upgrade pip || warning_msg "No se pudo actualizar pip, continuando..."
    pip install yt-dlp || error_exit "No se pudo instalar yt-dlp"
    deactivate
else
    error_exit "No se pudo activar el entorno virtual"
fi

# Crear archivo de configuración
echo "Creando configuración..."
cat > "$CONFIG_DIR/ytdlp_config.json" << 'EOF'
{
    "output_template": "%(title)s.%(ext)s",
    "output_directory": "~/ytdlp-downloads",
    "history_file": "download_history.json",
    "download_playlists": true,
    "max_quality": "1080p",
    "prefer_mp4": true,
    "audio_format": "mp3",
    "audio_quality": "192",
    "embed_thumbnail": false,
    "write_info_json": false,
    "write_description": false,
    "write_annotations": false,
    "write_subs": false,
    "restrict_filenames": false,
    "retries": 10,
    "fragment_retries": 10,
    "skip_existing": true,
    "console_title": false,
    "quiet": false,
    "verbose": false
}
EOF

if [ $? -ne 0 ]; then
    warning_msg "No se pudo crear el archivo de configuración"
fi

# Crear script de lanzamiento CORREGIDO
echo "Creando script de lanzamiento..."
cat > "$INSTALL_DIR/ytdlp-launcher.sh" << EOF
#!/bin/bash
# Script de lanzamiento para ytdlp-wrapper
INSTALL_DIR="$INSTALL_DIR"
. "\$INSTALL_DIR/venv/bin/activate"
python "\$INSTALL_DIR/ytdlp_wrapper.py" "\$@"
EOF

chmod +x "$INSTALL_DIR/ytdlp-launcher.sh" || error_exit "No se pudo dar permisos al launcher"

# Crear enlace simbólico
echo "Creando enlace simbólico..."
ln -sf "$INSTALL_DIR/ytdlp-launcher.sh" "$BIN_DIR/ytdlp" || error_exit "No se pudo crear enlace simbólico"

# Verificar PATH
echo "Verificando configuración del PATH..."
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warning_msg "$HOME/.local/bin no está en tu PATH"
    
    # Detectar shell actual
    SHELL_NAME=$(basename "$SHELL")
    
    case "$SHELL_NAME" in
        "bash")
            RC_FILE="$HOME/.bashrc"
            ;;
        "zsh")
            RC_FILE="$HOME/.zshrc"
            ;;
        "fish")
            RC_FILE="$HOME/.config/fish/config.fish"
            warning_msg "Para Fish shell, añade manualmente: set -gx PATH \$HOME/.local/bin \$PATH"
            ;;
        *)
            RC_FILE="$HOME/.profile"
            ;;
    esac
    
    if [ -n "$RC_FILE" ] && [ "$SHELL_NAME" != "fish" ]; then
        echo ""
        echo "Añade esta línea a $RC_FILE:"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
        echo ""
        echo "Luego ejecuta: source $RC_FILE"
    fi
else
    # Verificar que el enlace funciona
    echo "Verificando instalación..."
    if [ -f "$BIN_DIR/ytdlp" ] && [ -L "$BIN_DIR/ytdlp" ]; then
        if [ -f "$INSTALL_DIR/venv/bin/activate" ] && [ -f "$INSTALL_DIR/ytdlp_wrapper.py" ]; then
            success_msg "Instalación verificada correctamente"
        else
            warning_msg "Algunos archivos de instalación no se encontraron"
        fi
    fi
fi

# Crear script de desinstalación
echo "Creando script de desinstalación..."
cat > "$INSTALL_DIR/uninstall.sh" << EOF
#!/bin/bash
echo "=== Desinstalando ytdlp-wrapper ==="
read -p "¿Eliminar ytdlp-wrapper? (s/N): " confirm
if [[ \$confirm == [sS] ]]; then
    rm -f "$BIN_DIR/ytdlp"
    rm -rf "$INSTALL_DIR"
    rm -rf "$CONFIG_DIR"
    echo "✅ ytdlp-wrapper desinstalado"
else
    echo "❌ Desinstalación cancelada"
fi
EOF

chmod +x "$INSTALL_DIR/uninstall.sh" || warning_msg "No se pudo dar permisos al script de desinstalación"

echo ""
success_msg "Instalación completada!"
echo ""
echo "Para usar:"
echo "  1. Asegúrate de tener $HOME/.local/bin en tu PATH"
echo "  2. Usa el comando: ytdlp --help"
echo ""
echo "Ejemplos:"
echo "  ytdlp https://youtube.com/watch?v=VIDEO_ID"
echo "  ytdlp -p https://youtube.com/playlist?list=PLAYLIST_ID"
echo ""
echo "Directorio de descargas: $DOWNLOADS_DIR"
echo "Directorio de instalación: $INSTALL_DIR"
echo ""
echo "Para desinstalar:"
echo "  $INSTALL_DIR/uninstall.sh"
echo ""