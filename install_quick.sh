#!/bin/bash
# INSTALADOR RÁPIDO ytdlp-wrapper

echo "=== Instalando ytdlp-wrapper ==="
echo ""

# Directorios
INSTALL_DIR="$HOME/.local/share/ytdlp-wrapper"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/ytdlp-wrapper"

# Crear directorios
echo "Creando directorios..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$HOME/ytdlp-downloads"

# Copiar el wrapper
echo "Copiando script..."
cp ytdlp_wrapper.py "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/ytdlp_wrapper.py"

# Crear entorno virtual e instalar yt-dlp
echo "Creando entorno virtual Python..."
python3 -m venv "$INSTALL_DIR/venv"

echo "Instalando yt-dlp..."
source "$INSTALL_DIR/venv/bin/activate"
pip install --upgrade pip
pip install yt-dlp

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

# Crear script de lanzamiento
echo "Creando script de lanzamiento..."
cat > "$INSTALL_DIR/ytdlp-launcher.sh" << 'EOF'
#!/bin/bash
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$INSTALL_DIR/venv/bin/activate"
python "$INSTALL_DIR/ytdlp_wrapper.py" "$@"
EOF

chmod +x "$INSTALL_DIR/ytdlp-launcher.sh"

# Crear enlace simbólico
echo "Creando enlace simbólico..."
ln -sf "$INSTALL_DIR/ytdlp-launcher.sh" "$BIN_DIR/ytdlp"

# Verificar PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo "⚠ Advertencia: $HOME/.local/bin no está en tu PATH"
    echo "Añade esta línea a ~/.bashrc o ~/.zshrc:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo ""
    echo "Luego ejecuta: source ~/.bashrc"
fi

# Crear script de desinstalación
echo "Creando script de desinstalación..."
cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
echo "=== Desinstalando ytdlp-wrapper ==="
read -p "¿Eliminar ytdlp-wrapper? (s/N): " confirm
if [[ $confirm == [sS] ]]; then
    rm -f ~/.local/bin/ytdlp
    rm -rf ~/.local/share/ytdlp-wrapper
    rm -rf ~/.config/ytdlp-wrapper
    echo "✅ ytdlp-wrapper desinstalado"
else
    echo "❌ Desinstalación cancelada"
fi
EOF

chmod +x "$INSTALL_DIR/uninstall.sh"

echo ""
echo "✅ Instalación completada!"
echo ""
echo "Para usar:"
echo "  1. Reinicia tu terminal o ejecuta: source ~/.bashrc"
echo "  2. Usa el comando: ytdlp --help"
echo ""
echo "Ejemplos:"
echo "  ytdlp https://youtube.com/watch?v=VIDEO_ID"
echo "  ytdlp -p https://youtube.com/playlist?list=PLAYLIST_ID"
echo ""
echo "Para desinstalar:"
echo "  $INSTALL_DIR/uninstall.sh"