#!/bin/bash

# ============================================
# INSTALADOR ytdlp-wrapper v1.0
# Script para instalar el wrapper de yt-dlp
# ============================================

set -e  # Salir al primer error

# Colores para mensajes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_message() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para verificar Python
check_python() {
    print_info "Verificando Python..."
    
    if command_exists python3; then
        PYTHON_CMD="python3"
        PYTHON_VERSION=$($PYTHON_CMD --version | cut -d' ' -f2)
        print_message "Python encontrado: $PYTHON_VERSION"
    elif command_exists python; then
        PYTHON_CMD="python"
        PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
        if [[ $PYTHON_VERSION == Python* ]]; then
            print_message "Python encontrado: $PYTHON_VERSION"
        else
            print_error "Python no encontrado o versión incompatible"
            return 1
        fi
    else
        print_error "Python no encontrado"
        return 1
    fi
    
    # Verificar versión mínima de Python
    if $PYTHON_CMD -c "import sys; sys.exit(0 if sys.version_info >= (3, 6) else 1)"; then
        print_message "Versión de Python compatible (>= 3.6)"
        return 0
    else
        print_error "Se requiere Python 3.6 o superior"
        return 1
    fi
}

# Función para instalar dependencias Python
install_python_deps() {
    print_info "Instalando dependencias de Python..."
    
    # Crear entorno virtual si no existe
    if [ ! -d "$INSTALL_DIR/venv" ]; then
        print_info "Creando entorno virtual Python..."
        $PYTHON_CMD -m venv "$INSTALL_DIR/venv"
        print_message "Entorno virtual creado"
    fi
    
    # Activar entorno virtual
    source "$INSTALL_DIR/venv/bin/activate"
    
    # Actualizar pip
    print_info "Actualizando pip..."
    pip install --upgrade pip
    
    # Instalar yt-dlp
    print_info "Instalando yt-dlp..."
    pip install yt-dlp
    
    # Instalar dependencias adicionales si es necesario
    print_info "Instalando dependencias adicionales..."
    pip install requests
    
    print_message "Dependencias Python instaladas"
}

# Función para crear directorios necesarios
create_directories() {
    print_info "Creando estructura de directorios..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$DOWNLOADS_DIR"
    
    print_message "Estructura de directorios creada"
}

# Función para instalar el script principal
install_scripts() {
    print_info "Instalando scripts..."
    
    # Copiar el wrapper
    cp "$SCRIPT_DIR/ytdlp_wrapper.py" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/ytdlp_wrapper.py"
    
    # Crear script de lanzamiento
    cat > "$LAUNCHER_SCRIPT" << 'EOF'
#!/bin/bash

# Script de lanzamiento para ytdlp-wrapper

# Directorio de instalación
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para mostrar ayuda
show_help() {
    echo -e "${GREEN}ytdlp-wrapper - Herramienta de descarga de videos${NC}"
    echo ""
    echo "Uso:"
    echo "  ytdlp [OPCIONES] [URL]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help            Mostrar esta ayuda"
    echo "  -v, --version         Mostrar versión"
    echo "  -i, --info            Mostrar información de instalación"
    echo "  -u, --update          Actualizar yt-dlp y el wrapper"
    echo "  -c, --config          Mostrar/editar configuración"
    echo "  --gui                 Iniciar interfaz gráfica (si está disponible)"
    echo ""
    echo "Ejemplos:"
    echo "  ytdlp https://youtube.com/watch?v=VIDEO_ID"
    echo "  ytdlp -p https://youtube.com/playlist?list=PLAYLIST_ID"
    echo "  ytdlp -f lista_urls.txt"
    echo ""
    echo "Para más opciones, ver: ytdlp --help-detailed"
}

# Función para mostrar información
show_info() {
    echo -e "${GREEN}=== Información de ytdlp-wrapper ===${NC}"
    echo ""
    echo "Directorio de instalación: $INSTALL_DIR"
    echo "Directorio de descargas: $INSTALL_DIR/downloads"
    echo "Directorio de configuración: $INSTALL_DIR/config"
    echo "Directorio de logs: $INSTALL_DIR/logs"
    echo ""
    
    # Verificar entorno virtual
    if [ -f "$INSTALL_DIR/venv/bin/activate" ]; then
        echo -e "${GREEN}✓ Entorno virtual activo${NC}"
        source "$INSTALL_DIR/venv/bin/activate"
        echo "Versión Python: $(python --version 2>&1)"
        echo "Versión yt-dlp: $(yt-dlp --version 2>&1 || echo 'No disponible')"
    else
        echo -e "${YELLOW}⚠ Entorno virtual no encontrado${NC}"
    fi
}

# Función para actualizar
update_wrapper() {
    echo -e "${GREEN}Actualizando ytdlp-wrapper...${NC}"
    
    # Actualizar yt-dlp
    source "$INSTALL_DIR/venv/bin/activate"
    pip install --upgrade yt-dlp
    
    # Actualizar script wrapper si hay una nueva versión disponible
    # (esto requeriría un sistema de versionado, por ahora solo reinstalamos)
    
    echo -e "${GREEN}✓ Actualización completada${NC}"
}

# Función para mostrar/editar configuración
show_config() {
    CONFIG_FILE="$INSTALL_DIR/config/ytdlp_config.json"
    
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}=== Configuración actual ===${NC}"
        echo ""
        cat "$CONFIG_FILE"
        echo ""
        echo -e "Para editar: ${YELLOW}nano $CONFIG_FILE${NC}"
    else
        echo -e "${YELLOW}⚠ Archivo de configuración no encontrado${NC}"
        echo "Se creará al ejecutar el wrapper por primera vez"
    fi
}

# Verificar argumentos
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        echo "ytdlp-wrapper v1.0"
        echo "Wrapper para yt-dlp con soporte para MP4/AVC1 + MP3"
        exit 0
        ;;
    -i|--info)
        show_info
        exit 0
        ;;
    -u|--update)
        update_wrapper
        exit 0
        ;;
    -c|--config)
        show_config
        exit 0
        ;;
    --gui)
        echo -e "${YELLOW}Interfaz gráfica no disponible aún${NC}"
        echo "Usa la versión de línea de comandos por ahora"
        exit 0
        ;;
    --help-detailed)
        # Ejecutar el wrapper con --help
        source "$INSTALL_DIR/venv/bin/activate"
        python "$INSTALL_DIR/ytdlp_wrapper.py" --help
        exit 0
        ;;
esac

# Ejecutar el wrapper Python
if [ -f "$INSTALL_DIR/venv/bin/activate" ]; then
    source "$INSTALL_DIR/venv/bin/activate"
    python "$INSTALL_DIR/ytdlp_wrapper.py" "$@"
else
    echo -e "${RED}Error: Entorno virtual no encontrado${NC}"
    echo "Ejecuta el instalador nuevamente: ./install_ytdlp.sh"
    exit 1
fi
EOF
    
    chmod +x "$LAUNCHER_SCRIPT"
    
    # Crear script de desinstalación
    cat > "$UNINSTALL_SCRIPT" << 'EOF'
#!/bin/bash

# Desinstalador de ytdlp-wrapper

INSTALL_DIR="$HOME/.local/share/ytdlp-wrapper"
BIN_DIR="$HOME/.local/bin"

echo "=== Desinstalación de ytdlp-wrapper ==="
echo ""
echo "Esto eliminará:"
echo "  - $INSTALL_DIR"
echo "  - $BIN_DIR/ytdlp"
echo ""
read -p "¿Continuar con la desinstalación? (s/N): " confirm

if [[ $confirm != [sS] ]]; then
    echo "Desinstalación cancelada"
    exit 0
fi

# Eliminar enlace simbólico
if [ -L "$BIN_DIR/ytdlp" ]; then
    echo "Eliminando enlace simbólico..."
    rm "$BIN_DIR/ytdlp"
fi

# Eliminar directorio de instalación
if [ -d "$INSTALL_DIR" ]; then
    echo "Eliminando directorio de instalación..."
    rm -rf "$INSTALL_DIR"
fi

# Eliminar configuración del usuario (opcional)
read -p "¿Eliminar también archivos de configuración y descargas? (s/N): " del_config

if [[ $del_config == [sS] ]]; then
    CONFIG_DIR="$HOME/.config/ytdlp-wrapper"
    DOWNLOADS_DIR="$HOME/ytdlp-downloads"
    
    if [ -d "$CONFIG_DIR" ]; then
        echo "Eliminando configuración..."
        rm -rf "$CONFIG_DIR"
    fi
    
    if [ -d "$DOWNLOADS_DIR" ]; then
        echo "Eliminando descargas..."
        rm -rf "$DOWNLOADS_DIR"
    fi
fi

echo ""
echo "✅ ytdlp-wrapper desinstalado correctamente"
EOF
    
    chmod +x "$UNINSTALL_SCRIPT"
    
    print_message "Scripts instalados"
}

# Función para crear enlaces simbólicos
create_symlinks() {
    print_info "Creando enlaces simbólicos..."
    
    # Crear directorio bin si no existe
    mkdir -p "$HOME/.local/bin"
    
    # Crear enlace simbólico
    if [ -L "$HOME/.local/bin/ytdlp" ]; then
        rm "$HOME/.local/bin/ytdlp"
    fi
    
    ln -sf "$LAUNCHER_SCRIPT" "$HOME/.local/bin/ytdlp"
    
    # Verificar que esté en el PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_warning "$HOME/.local/bin no está en tu PATH"
        print_warning "Añade esta línea a ~/.bashrc o ~/.zshrc:"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
    else
        print_message "Enlace simbólico creado: ytdlp -> $LAUNCHER_SCRIPT"
    fi
}

# Función para crear configuración por defecto
create_default_config() {
    print_info "Creando configuración por defecto..."
    
    CONFIG_FILE="$CONFIG_DIR/ytdlp_config.json"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
{
    "output_template": "%(title)s.%(ext)s",
    "output_directory": "./downloads",
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
    "console_title": false
}
EOF
        print_message "Configuración por defecto creada"
    else
        print_message "Configuración ya existe, manteniendo actual"
    fi
}

# Función para configurar el entorno
setup_environment() {
    print_info "Configurando entorno..."
    
    # Crear alias para bash/zsh
    SHELL_CONFIG=""
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        # Verificar si ya existe la configuración
        if ! grep -q "ytdlp-wrapper" "$SHELL_CONFIG"; then
            echo "" >> "$SHELL_CONFIG"
            echo "# ytdlp-wrapper configuration" >> "$SHELL_CONFIG"
            echo "export YTDLP_WRAPPER_DIR=\"$INSTALL_DIR\"" >> "$SHELL_CONFIG"
            echo "alias ytdlp-update=\"cd \$YTDLP_WRAPPER_DIR && source venv/bin/activate && pip install --upgrade yt-dlp\"" >> "$SHELL_CONFIG"
            print_message "Alias añadido a $SHELL_CONFIG"
        fi
    fi
}

# Función para verificar instalación
verify_installation() {
    print_info "Verificando instalación..."
    
    echo ""
    echo -e "${CYAN}=== Resumen de instalación ===${NC}"
    echo ""
    
    # Verificar archivos
    declare -a files_to_check=(
        "$INSTALL_DIR/ytdlp_wrapper.py"
        "$LAUNCHER_SCRIPT"
        "$CONFIG_DIR/ytdlp_config.json"
        "$INSTALL_DIR/venv/bin/activate"
    )
    
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓${NC} $(basename "$file")"
        else
            echo -e "${RED}✗${NC} $(basename "$file") (no encontrado)"
        fi
    done
    
    # Verificar enlace simbólico
    if [ -L "$HOME/.local/bin/ytdlp" ]; then
        echo -e "${GREEN}✓${NC} Enlace simbólico ytdlp"
    else
        echo -e "${RED}✗${NC} Enlace simbólico ytdlp"
    fi
    
    # Verificar dependencias
    source "$INSTALL_DIR/venv/bin/activate"
    if python -c "import yt_dlp" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} yt-dlp instalado"
    else
        echo -e "${RED}✗${NC} yt-dlp no instalado"
    fi
    
    echo ""
}

# Función para mostrar mensaje de finalización
show_completion_message() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    INSTALACIÓN COMPLETADA              ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "📦 ytdlp-wrapper ha sido instalado correctamente."
    echo ""
    echo "📂 Directorios:"
    echo "   Instalación:    $INSTALL_DIR"
    echo "   Configuración:  $CONFIG_DIR"
    echo "   Descargas:      $DOWNLOADS_DIR"
    echo "   Logs:           $LOG_DIR"
    echo ""
    echo "🚀 Para usar:"
    echo "   1. Reinicia tu terminal o ejecuta:"
    echo "      source ~/.bashrc  (o ~/.zshrc)"
    echo ""
    echo "   2. Usa el comando:"
    echo "      ${CYAN}ytdlp --help${NC}      para ver ayuda"
    echo "      ${CYAN}ytdlp [URL]${NC}       para descargar"
    echo "      ${CYAN}ytdlp -i${NC}          para información"
    echo ""
    echo "🔄 Para actualizar:"
    echo "      ${CYAN}ytdlp -u${NC}          o"
    echo "      ${CYAN}ytdlp-update${NC}      (después de reiniciar)"
    echo ""
    echo "🗑️  Para desinstalar:"
    echo "      ${CYAN}$INSTALL_DIR/uninstall.sh${NC}"
    echo ""
    echo "📝 Ejemplos rápidos:"
    echo "      ytdlp https://youtube.com/watch?v=VIDEO_ID"
    echo "      ytdlp -p https://youtube.com/playlist?list=PLAYLIST_ID"
    echo "      ytdlp -f lista_urls.txt"
    echo ""
    echo -e "${GREEN}========================================${NC}"
}

# Función principal
main() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║         INSTALADOR ytdlp-wrapper         ║"
    echo "║         Versión 1.0                      ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Variables de directorio
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_DIR="$HOME/.local/share/ytdlp-wrapper"
    CONFIG_DIR="$HOME/.config/ytdlp-wrapper"
    LOG_DIR="$HOME/.local/share/ytdlp-wrapper/logs"
    DOWNLOADS_DIR="$HOME/ytdlp-downloads"
    
    LAUNCHER_SCRIPT="$INSTALL_DIR/ytdlp-launcher.sh"
    UNINSTALL_SCRIPT="$INSTALL_DIR/uninstall.sh"
    
    # Verificar Python
    if ! check_python; then
        print_error "Python 3.6+ es requerido"
        print_info "Instala Python desde: https://www.python.org/downloads/"
        exit 1
    fi
    
    # Crear directorios
    create_directories
    
    # Instalar dependencias
    install_python_deps
    
    # Verificar que el wrapper existe
    if [ ! -f "$SCRIPT_DIR/ytdlp_wrapper.py" ]; then
        print_error "No se encuentra ytdlp_wrapper.py en $SCRIPT_DIR"
        print_error "Asegúrate de que el archivo está en el mismo directorio que este instalador"
        exit 1
    fi
    
    # Instalar scripts
    install_scripts
    
    # Crear enlaces simbólicos
    create_symlinks
    
    # Crear configuración
    create_default_config
    
    # Configurar entorno
    setup_environment
    
    # Verificar instalación
    verify_installation
    
    # Mostrar mensaje de finalización
    show_completion_message
}

# Ejecutar función principal
main "$@"