# ytdlp-wrapper

Un wrapper simple y eficiente para `yt-dlp` que descarga contenido multimedia en alta calidad con configuración mínima.

## 📋 Características

- ✅ **Calidad garantizada**: Descarga automáticamente el mejor formato disponible (hasta 4K)
- ✅ **Formato flexible**: MP4/AVC1 (H.264) o Matroska con audio MP3 integrado
- ✅ **Manejo de playlists**: Descarga listas completas con un solo comando
- ✅ **Historial inteligente**: Registra todas las descargas para evitar duplicados
- ✅ **Configuración simple**: Todo se controla desde un archivo JSON
- ✅ **Compatibilidad multiplataforma**: Funciona en Linux, macOS y Windows (WSL)

## ⚙️ Prerrequisitos del Sistema

### 1. **Python 3.7 o superior**
```bash
# Verificar instalación
python3 --version
pip3 --version

# Instalar si es necesario (Ubuntu/Debian)
sudo apt update
sudo apt install python3 python3-pip

# Instalar si es necesario (Fedora/RHEL)
sudo dnf install python3 python3-pip

# Instalar si es necesario (macOS)
brew install python3
```

### 2. **yt-dlp (herramienta principal)**
```bash
# Instalar/actualizar yt-dlp
pip3 install --upgrade yt-dlp

# Verificar instalación
yt-dlp --version
```

### 3. **FFmpeg (para procesamiento multimedia)**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ffmpeg

# Fedora/RHEL
sudo dnf install ffmpeg

# macOS
brew install ffmpeg

# Windows (con Chocolatey)
choco install ffmpeg

# Verificar instalación
ffmpeg -version
ffprobe -version
```

### 4. **Dependencias opcionales (recomendadas)**
```bash
# Para mejor rendimiento en Linux
sudo apt install aria2  # Acelerador de descargas

# Para soporte de JavaScript (algunos sitios web)
sudo apt install nodejs  # o instalar desde nodejs.org
```

## 🚀 Instalación Rápida

### Método 1: Clonar repositorio
```bash
# Clonar el repositorio
git clone https://raw.githubusercontent.com/caneyshulemena-boss/install_ytdlp_wrapper/ytdlp-wrapper.git
cd install-ytdlp-wrapper

# Hacer el script ejecutable
chmod +x ytdlp_wrapper.py

# Crear enlace simbólico (opcional, para uso global)
sudo ln -s "$(pwd)/ytdlp_wrapper.py" /usr/local/bin/ytdlp
```

### Método 2: Instalación manual
```bash
# Descargar solo los archivos necesarios
wget https://raw.githubusercontent.com/caneyshulemena-boss/install_ytdlp_wrapper/main/ytdlp_wrapper.py
chmod +x ytdlp_wrapper.py

# Crear directorio de configuración
mkdir -p ~/.config/ytdlp-wrapper/
```

## ⚙️ Configuración Inicial

El script creará automáticamente un archivo de configuración en `~/.config/ytdlp-wrapper/ytdlp_config.json` la primera vez que se ejecute.

### Personalizar configuración:
```bash
# Mostrar configuración actual
./ytdlp_wrapper.py --config mostrar

# Editar manualmente
nano ~/.config/ytdlp-wrapper/ytdlp_config.json
```

### Configuración por defecto:
```json
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
    "verbose": false,
    "create_playlist_dir": true
}
```

## 📖 Uso Básico

### Descargar un video individual
```bash
./ytdlp_wrapper.py https://youtube.com/watch?v=VIDEO_ID
```

### Descargar una playlist completa
```bash
./ytdlp_wrapper.py https://youtube.com/playlist?list=PLAYLIST_ID
```

### Descargar sin crear carpeta para playlist
```bash
./ytdlp_wrapper.py --no-playlist-dir https://youtube.com/playlist?list=PLAYLIST_ID
```

### Descargar desde archivo de texto con URLs
```bash
# Crear archivo lista.txt con una URL por línea
echo "https://youtube.com/watch?v=VIDEO1" > lista.txt
echo "https://youtube.com/watch?v=VIDEO2" >> lista.txt

# Descargar todo
./ytdlp_wrapper.py --file lista.txt
```

## 🎯 Ejemplos Prácticos

### Ejemplo 1: Descargar música en alta calidad
```bash
./ytdlp_wrapper.py --directorio ./musica --audio-quality 320 https://youtube.com/watch?v=CANCIÓN
```

### Ejemplo 2: Descargar playlist de videos 4K
```bash
./ytdlp_wrapper.py --max-quality 2160p --directorio ./videos_4k PLAYLIST_URL
```

### Ejemplo 3: Procesar lista grande de URLs
```bash
./ytdlp_wrapper.py --file lista_grande.txt --no-playlist-dir --directorio ./descargas
```

### Ejemplo 4: Solo audio (extraer MP3)
```bash
./ytdlp_wrapper.py --no-mp4 --audio-quality 256 URL_VIDEO
```

## 🔧 Opciones Avanzadas

### Calidad y formato
```bash
--max-quality 720p|1080p|1440p|2160p    # Calidad máxima de video
--audio-quality 64|128|192|256|320      # Calidad de audio (kbps)
--no-mp4                                # Usar Matroska en lugar de MP4
```

### Directorios y organización
```bash
-o, --directorio DIR                    # Directorio de salida personalizado
--no-playlist-dir                       # No crear subcarpetas para playlists
```

### Modos de ejecución
```bash
--quiet                                 # Modo silencioso (sin output)
--verbose                               # Modo detallado (debug)
```

### Historial y configuración
```bash
-H, --historial                         # Mostrar historial de descargas
--limpiar-historial                     # Borrar historial completo
-c, --config [mostrar|ruta]            # Mostrar configuración o ruta
```

## 📁 Estructura de Archivos

```
~/.config/ytdlp-wrapper/
├── ytdlp_config.json          # Configuración principal
└── download_history.json      # Historial de descargas

~/ytdlp-downloads/             # Directorio por defecto (configurable)
├── video1.mp4
├── video2.mkv
└── nombre-playlist/           # Carpeta de playlist (opcional)
    ├── video3.mp4
    └── video4.mp4
```

## 🐛 Solución de Problemas

### Error: "yt-dlp no está instalado"
```bash
pip3 install --upgrade yt-dlp
```

### Error: "FFmpeg no encontrado"
```bash
# Instalar FFmpeg según tu sistema (ver sección Prerrequisitos)
# Verificar con:
ffmpeg -version
```

### Error: "No supported JavaScript runtime"
```bash
# Instalar Node.js
sudo apt install nodejs  # Ubuntu/Debian
```

### Las descargas son muy lentas
```bash
# Instalar aria2 para acelerar
sudo apt install aria2

# El wrapper usa yt-dlp que soporta aria2 automáticamente
```

### Archivos separados (video + audio)
```bash
# Asegúrate que FFmpeg esté instalado correctamente
ffmpeg -version

# Reinstalar si es necesario
sudo apt reinstall ffmpeg
```

## 🔄 Actualización

```bash
# Actualizar yt-dlp
pip3 install --upgrade yt-dlp

# Actualizar FFmpeg
sudo apt update && sudo apt upgrade ffmpeg  # Ubuntu/Debian

# Actualizar wrapper (si clonaste el repositorio)
cd /ruta/a/ytdlp-wrapper
git pull origin main
```

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver archivo `LICENSE` para más detalles.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, sigue estos pasos:

1. Haz fork del proyecto
2. Crea una rama para tu funcionalidad (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## ⚠️ Aviso Legal

Este software es para uso personal. Asegúrate de cumplir con los Términos de Servicio de las plataformas de video y las leyes de copyright de tu país.

El autor no se hace responsable del mal uso de esta herramienta.

---
