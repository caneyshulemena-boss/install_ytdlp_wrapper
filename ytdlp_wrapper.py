#!/usr/bin/env python3
"""
Wrapper simple para yt-dlp que descarga solo contenido en alta calidad:
- Formato: mp4 (AVC1/H.264) o Matroska
- Audio: mp3
- Maneja playlists y historial de descargas
- Configuración super simple con JSON
"""

import json
import os
import sys
import subprocess
import argparse
from datetime import datetime
from pathlib import Path

class YTDLPWrapper:
    def __init__(self, config_file=None):
        """
        Inicializa el wrapper con configuración desde archivo JSON
        """
        self.config = {}  # Inicializar config como diccionario vacío primero
        
        if config_file is None:
            # Buscar configuración en directorios estándar
            config_locations = [
                os.path.expanduser("~/.config/ytdlp-wrapper/ytdlp_config.json"),
                os.path.join(os.path.dirname(os.path.abspath(__file__)), "config", "ytdlp_config.json"),
                "ytdlp_config.json"
            ]
            
            for location in config_locations:
                if os.path.exists(location):
                    config_file = location
                    break
        
        self.config_file = config_file or os.path.expanduser("~/.config/ytdlp-wrapper/ytdlp_config.json")
        self.config = self.load_config()  # Ahora cargar la configuración
        
        # Determinar directorio para historial
        self.history_file = self.config.get("history_file", "download_history.json")
        if not os.path.isabs(self.history_file):
            # Si es relativo, guardar en directorio de configuración
            config_dir = os.path.dirname(self.config_file)
            os.makedirs(config_dir, exist_ok=True)
            self.history_file = os.path.join(config_dir, self.history_file)
            
        self.history = self.load_history()
        
    def load_config(self):
        """Carga la configuración desde archivo JSON o crea una por defecto"""
        default_config = {
            "output_template": "%(title)s.%(ext)s",
            "output_directory": os.path.expanduser("~/ytdlp-downloads"),
            "history_file": "download_history.json",
            "download_playlists": True,
            "max_quality": "1080p",
            "prefer_mp4": True,
            "audio_format": "mp3",
            "audio_quality": "192",
            "embed_thumbnail": False,
            "write_info_json": False,
            "write_description": False,
            "write_annotations": False,
            "write_subs": False,
            "restrict_filenames": False,
            "retries": 10,
            "fragment_retries": 10,
            "skip_existing": True,
            "console_title": False,
            "quiet": False,
            "verbose": False
        }
        
        try:
            # Crear directorio si no existe
            config_dir = os.path.dirname(self.config_file)
            os.makedirs(config_dir, exist_ok=True)
            
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                    # Actualizar configuración por defecto con valores del usuario
                    default_config.update(user_config)
                    
                    if not default_config.get("quiet", False):  # Usar default_config, no self.config
                        print(f"✓ Configuración cargada desde {self.config_file}")
            else:
                # Crear archivo de configuración por defecto
                with open(self.config_file, 'w', encoding='utf-8') as f:
                    json.dump(default_config, f, indent=4, ensure_ascii=False)
                
                if not default_config.get("quiet", False):  # Usar default_config, no self.config
                    print(f"✓ Archivo de configuración creado: {self.config_file}")
                    print("  Edita el archivo para personalizar la configuración.")
                
        except Exception as e:
            if not default_config.get("quiet", False):  # Usar default_config, no self.config
                print(f"⚠ Error cargando configuración: {e}, usando valores por defecto")
            
        return default_config
    
    def load_history(self):
        """Carga el historial de descargas desde archivo JSON"""
        history = {"downloads": []}
        try:
            if os.path.exists(self.history_file):
                with open(self.history_file, 'r', encoding='utf-8') as f:
                    history = json.load(f)
        except Exception as e:
            if not self.config.get("quiet", False):
                print(f"⚠ Error cargando historial: {e}, creando nuevo historial")
        return history
    
    def save_history(self):
        """Guarda el historial de descargas en archivo JSON"""
        try:
            with open(self.history_file, 'w', encoding='utf-8') as f:
                json.dump(self.history, f, indent=4, ensure_ascii=False, default=str)
        except Exception as e:
            if not self.config.get("quiet", False):
                print(f"⚠ Error guardando historial: {e}")
    
    def add_to_history(self, url, title, filename, success=True):
        """Añade una descarga al historial"""
        download_record = {
            "url": url,
            "title": title,
            "filename": filename,
            "date": datetime.now().isoformat(),
            "success": success
        }
        
        # Mantener solo las últimas 1000 descargas
        self.history["downloads"].append(download_record)
        if len(self.history["downloads"]) > 1000:
            self.history["downloads"] = self.history["downloads"][-1000:]
        
        self.save_history()
    
    def get_format_selection(self):
        """
        Define los formatos preferidos en orden de prioridad:
        1. MP4 con video H.264 y audio AAC (mejor compatibilidad)
        2. WebM/Matroska con video VP9/AV1 y audio Opus
        3. Mejor combinación disponible
        """
        max_height = self.config["max_quality"].replace("p", "")
        
        formats = []
        
        # Prioridad 1: MP4 con H.264 (hasta la calidad máxima configurada)
        if self.config["prefer_mp4"]:
            # Formatos MP4 con video H.264
            formats.append(f"bestvideo[ext=mp4][vcodec^=avc1][height<={max_height}]+bestaudio[ext=m4a]/best[ext=mp4][vcodec^=avc1][height<={max_height}]")
            formats.append(f"bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4][vcodec^=avc1]")
        
        # Prioridad 2: Matroska/WebM con codecs modernos
        formats.append(f"bestvideo[ext=webm][vcodec^=vp9][height<={max_height}]+bestaudio[ext=webm]/best[ext=webm][vcodec^=vp9][height<={max_height}]")
        formats.append(f"bestvideo[ext=webm]+bestaudio[ext=webm]/best[ext=webm]")
        
        # Prioridad 3: Mejor combinación disponible (fallback)
        formats.append(f"bestvideo[height<={max_height}]+bestaudio/best[height<={max_height}]")
        formats.append("best")
        
        return "/".join(formats)
    
    def check_ytdlp_version(self):
        """Verifica la versión de yt-dlp y ajusta las opciones disponibles"""
        try:
            if self.config.get("verbose", False):
                result = subprocess.run(["yt-dlp", "--version"], capture_output=True, text=True)
                version_output = result.stdout.strip()
                print(f"✅ yt-dlp versión: {version_output}")
            
            # Intentar obtener opciones disponibles
            result = subprocess.run(["yt-dlp", "--help"], capture_output=True, text=True)
            help_text = result.stdout
            
            # Verificar opciones disponibles
            self.has_skip_existing = "--skip-existing" in help_text
            self.has_embed_thumbnail = "--embed-thumbnail" in help_text
            self.has_write_info_json = "--write-info-json" in help_text
            self.has_console_title = "--console-title" in help_text
            
            if not self.has_skip_existing and self.config.get("verbose", False):
                print("⚠ Tu versión de yt-dlp no soporta --skip-existing")
            if not self.has_embed_thumbnail and self.config.get("verbose", False):
                print("⚠ Tu versión de yt-dlp no soporta --embed-thumbnail")
                
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            if not self.config.get("quiet", False):
                print("❌ Error: yt-dlp no está instalado o no está en el PATH")
                print("Instala yt-dlp con: pip install yt-dlp")
            return False
    
    def is_playlist_url(self, url):
        """Determina si una URL es una playlist"""
        playlist_indicators = [
            'list=',
            'playlist?',
            '/playlist/',
            '&index=',
            'start_radio=',
            'video_ids='
        ]
        
        # Patrones específicos de diferentes plataformas
        youtube_playlist = 'youtube.com' in url and ('list=' in url or 'playlist?' in url)
        
        return youtube_playlist or any(indicator in url.lower() for indicator in playlist_indicators)
    
    def build_command(self, url, output_path=None, force_playlist=False):
        """Construye el comando para yt-dlp"""
        if output_path is None:
            output_path = self.config["output_directory"]
        
        # Asegurar que el directorio de salida existe
        os.makedirs(output_path, exist_ok=True)
        
        # Plantilla de salida
        output_template = os.path.join(output_path, self.config["output_template"])
        
        # Construir comando base
        cmd = [
            "yt-dlp",
            "--newline",  # Mostrar progreso en líneas nuevas
            "-o", output_template,
            "-f", self.get_format_selection(),
            "--merge-output-format", "mp4" if self.config["prefer_mp4"] else "mkv",
            "--audio-format", self.config["audio_format"],
            "--audio-quality", self.config["audio_quality"],
            "--retries", str(self.config["retries"]),
            "--fragment-retries", str(self.config["fragment_retries"]),
        ]
        
        # Añadir opciones de verbosidad
        if self.config.get("quiet", False):
            cmd.append("--quiet")
        elif self.config.get("verbose", False):
            cmd.append("--verbose")
        
        # Determinar si es playlist
        is_playlist = force_playlist or self.is_playlist_url(url)
        
        # Manejar opciones de playlist
        if is_playlist:
            # Para playlists, siempre usar --yes-playlist
            cmd.append("--yes-playlist")
        else:
            # Para videos individuales, usar --no-playlist
            cmd.append("--no-playlist")
        
        # Usar --no-overwrites si --skip-existing no está disponible
        if self.config.get("skip_existing", True):
            if hasattr(self, 'has_skip_existing') and self.has_skip_existing:
                cmd.append("--skip-existing")
            else:
                cmd.append("--no-overwrites")
                if self.config.get("verbose", False):
                    print("⚠ Usando --no-overwrites en lugar de --skip-existing")
            
        if self.config.get("embed_thumbnail", False):
            if hasattr(self, 'has_embed_thumbnail') and self.has_embed_thumbnail:
                cmd.append("--embed-thumbnail")
            elif self.config.get("verbose", False):
                print("⚠ Opción --embed-thumbnail no disponible en tu versión")
            
        if self.config.get("write_info_json", False):
            if hasattr(self, 'has_write_info_json') and self.has_write_info_json:
                cmd.append("--write-info-json")
            elif self.config.get("verbose", False):
                print("⚠ Opción --write-info-json no disponible en tu versión")
            
        if self.config.get("write_description", False):
            cmd.append("--write-description")
            
        if self.config.get("write_annotations", False):
            cmd.append("--write-annotations")
            
        if self.config.get("write_subs", False):
            cmd.append("--write-subs")
            
        if self.config.get("restrict_filenames", False):
            cmd.append("--restrict-filenames")
            
        if self.config.get("console_title", False):
            if hasattr(self, 'has_console_title') and self.has_console_title:
                cmd.append("--console-title")
            elif self.config.get("verbose", False):
                print("⚠ Opción --console-title no disponible en tu versión")
        
        # Añadir URL al final
        cmd.append(url)
        
        return cmd, is_playlist
    
    def get_video_info(self, url):
        """Obtiene información del video antes de descargar"""
        try:
            info_cmd = [
                "yt-dlp",
                "--skip-download",
                "--quiet",
                "--print", "%(title)s",
                "--print", "%(uploader)s",
                "--print", "%(duration)s",
                "--print", "%(playlist_title)s",
                "--print", "%(playlist_count)s",
                url
            ]
            result = subprocess.run(info_cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                return {
                    "title": lines[0] if len(lines) > 0 else "Desconocido",
                    "uploader": lines[1] if len(lines) > 1 else "Desconocido",
                    "duration": lines[2] if len(lines) > 2 else "0",
                    "playlist_title": lines[3] if len(lines) > 3 else None,
                    "playlist_count": lines[4] if len(lines) > 4 else None
                }
        except subprocess.TimeoutExpired:
            if self.config.get("verbose", False):
                print("⚠ Tiempo de espera agotado obteniendo información del video")
        except Exception as e:
            if self.config.get("verbose", False):
                print(f"⚠ Error obteniendo información: {e}")
        
        return {
            "title": "Desconocido", 
            "uploader": "Desconocido", 
            "duration": "0",
            "playlist_title": None,
            "playlist_count": None
        }
    
    def download(self, url, output_path=None, force_playlist=False):
        """Ejecuta la descarga con yt-dlp"""
        if not self.config.get("quiet", False):
            print(f"\n📥 Preparando descarga: {url}")
        
        # Verificar si yt-dlp está instalado y obtener versión
        if not self.check_ytdlp_version():
            return False
        
        # Obtener información del video
        video_info = self.get_video_info(url)
        title = video_info["title"]
        
        # Formatear duración
        try:
            duration_sec = int(video_info["duration"])
            if duration_sec > 0:
                minutes, seconds = divmod(duration_sec, 60)
                hours, minutes = divmod(minutes, 60)
                if hours > 0:
                    duration_str = f"{hours}h {minutes}m {seconds}s"
                elif minutes > 0:
                    duration_str = f"{minutes}m {seconds}s"
                else:
                    duration_str = f"{seconds}s"
            else:
                duration_str = "Desconocido"
        except:
            duration_str = "Desconocido"
        
        # Construir comando de descarga
        cmd, is_playlist = self.build_command(url, output_path, force_playlist)
        
        # Mostrar información
        if not self.config.get("quiet", False):
            print(f"📁 Directorio: {output_path or self.config['output_directory']}")
            print(f"🎬 Título: {title}")
            print(f"👤 Creador: {video_info['uploader']}")
            print(f"⏱ Duración: {duration_str}")
            
            # Información adicional para playlists
            if video_info.get("playlist_title") and video_info.get("playlist_count"):
                print(f"📂 Playlist: {video_info['playlist_title']}")
                print(f"🎵 Videos en playlist: {video_info['playlist_count']}")
            
            print(f"⚙️ Formato: {'MP4/AVC1' if self.config['prefer_mp4'] else 'Matroska'} + MP3 {self.config['audio_quality']}kbps")
            print(f"📦 Tipo: {'Playlist' if is_playlist else 'Video individual'}")
            print("-" * 50)
        
        try:
            # Ejecutar yt-dlp
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Mostrar salida en tiempo real si no está en modo quiet
            if not self.config.get("quiet", False):
                last_line_was_progress = False
                for line in process.stdout:
                    line = line.strip()
                    if not line:
                        continue
                        
                    # Manejar diferentes tipos de mensajes
                    if '[download]' in line and '%' in line:
                        # Línea de progreso - mostrar en la misma línea
                        if last_line_was_progress:
                            print(f"\r{line}", end='', flush=True)
                        else:
                            print(f"{line}", end='', flush=True)
                        last_line_was_progress = True
                    elif '[download]' in line and 'Downloading item' in line:
                        # Nuevo video en playlist
                        if last_line_was_progress:
                            print()  # Nueva línea después del progreso
                        print(f"\n{line}")
                        last_line_was_progress = False
                    elif 'ERROR' in line or 'WARNING' in line:
                        if last_line_was_progress:
                            print()  # Nueva línea después del progreso
                        print(f"{line}")
                        last_line_was_progress = False
                    elif line:
                        if last_line_was_progress:
                            print()  # Nueva línea después del progreso
                        print(f"{line}")
                        last_line_was_progress = False
                
                if last_line_was_progress:
                    print()  # Nueva línea final después del progreso
            else:
                # En modo quiet, solo capturar la salida
                process.communicate()
            
            process.wait()
            
            if process.returncode == 0:
                if not self.config.get("quiet", False):
                    print(f"\n✅ Descarga completada: {title}")
                # Añadir al historial
                self.add_to_history(url, title, "", success=True)
                return True
            else:
                if not self.config.get("quiet", False):
                    print(f"\n❌ Error en la descarga: {title}")
                self.add_to_history(url, title, "", success=False)
                return False
                
        except KeyboardInterrupt:
            if not self.config.get("quiet", False):
                print("\n⏹ Descarga interrumpida por el usuario")
            return False
        except Exception as e:
            if not self.config.get("quiet", False):
                print(f"\n❌ Error ejecutando yt-dlp: {e}")
            self.add_to_history(url, title, "", success=False)
            return False
    
    def download_playlist(self, playlist_url, output_path=None):
        """Descarga una playlist completa"""
        if not self.config.get("quiet", False):
            print(f"\n🎵 Descargando playlist: {playlist_url}")
        
        if output_path is None:
            output_path = self.config["output_directory"]
        
        # Obtener información de la playlist
        video_info = self.get_video_info(playlist_url)
        playlist_name = video_info.get("playlist_title") or "playlist"
        playlist_count = video_info.get("playlist_count") or "?"
        
        # Crear subdirectorio para la playlist
        safe_name = "".join(c for c in playlist_name if c.isalnum() or c in (' ', '-', '_')).strip()
        safe_name = safe_name[:50]  # Limitar longitud
        playlist_dir = os.path.join(output_path, safe_name)
        
        if not self.config.get("quiet", False):
            print(f"📂 Playlist: {playlist_name}")
            print(f"🎵 Videos: {playlist_count}")
            print(f"📁 Directorio: {playlist_dir}")
        
        # Forzar descarga como playlist
        success = self.download(playlist_url, playlist_dir, force_playlist=True)
        
        return success
    
    def download_from_list(self, file_path, output_path=None, is_playlist=False):
        """Descarga múltiples URLs desde un archivo de texto"""
        if not os.path.exists(file_path):
            print(f"❌ Archivo no encontrado: {file_path}")
            return False
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]
            
            if not urls:
                print(f"❌ No se encontraron URLs en el archivo: {file_path}")
                return False
            
            if not self.config.get("quiet", False):
                print(f"\n📄 Procesando {len(urls)} URLs desde: {file_path}")
            
            success_count = 0
            for i, url in enumerate(urls, 1):
                if not self.config.get("quiet", False):
                    print(f"\n{'='*60}")
                    print(f"📥 Procesando URL {i}/{len(urls)}")
                    print(f"{'='*60}")
                
                if is_playlist or self.is_playlist_url(url):
                    if self.download_playlist(url, output_path):
                        success_count += 1
                else:
                    if self.download(url, output_path):
                        success_count += 1
            
            if not self.config.get("quiet", False):
                print(f"\n{'='*60}")
                print(f"📊 Resumen: {success_count}/{len(urls)} descargas exitosas")
                print(f"{'='*60}")
            
            return success_count > 0
            
        except Exception as e:
            print(f"❌ Error procesando archivo: {e}")
            return False
    
    def show_history(self, limit=20):
        """Muestra el historial de descargas"""
        if not self.history.get("downloads"):
            print("📭 Historial vacío")
            return
        
        print(f"\n📋 Historial de descargas (últimas {min(limit, len(self.history['downloads']))}):")
        print("-" * 80)
        
        for i, record in enumerate(reversed(self.history["downloads"][-limit:])):
            idx = len(self.history["downloads"]) - i
            date_str = datetime.fromisoformat(record["date"]).strftime("%Y-%m-d %H:%M")
            status = "✅" if record.get("success", True) else "❌"
            title_display = record.get('title', 'Desconocido')
            if len(title_display) > 60:
                title_display = title_display[:57] + "..."
            print(f"{idx:4d}. {date_str} {status} {title_display}")
            url_display = record.get('url', 'Desconocida')
            if len(url_display) > 70:
                url_display = url_display[:67] + "..."
            print(f"     🔗 {url_display}")
        
        print(f"\nTotal descargas en historial: {len(self.history['downloads'])}")
        print(f"Archivo de historial: {self.history_file}")
    
    def clear_history(self):
        """Limpia el historial de descargas"""
        confirm = input("¿Estás seguro de querer borrar todo el historial? (s/N): ")
        if confirm.lower() == 's':
            self.history = {"downloads": []}
            self.save_history()
            print("✅ Historial borrado")
        else:
            print("❌ Operación cancelada")

def main():
    parser = argparse.ArgumentParser(
        description="Wrapper para yt-dlp - Descarga videos en alta calidad (MP4/Matroska + MP3)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  ytdlp https://youtube.com/watch?v=VIDEO_ID
  ytdlp -p https://youtube.com/playlist?list=PLAYLIST_ID
  ytdlp -f lista.txt                     # Descargar desde archivo de URLs
  ytdlp -H                               # Mostrar historial
  ytdlp --config mostrar                 # Mostrar configuración
  ytdlp -o ./mis_descargas URL           # Directorio personalizado
  ytdlp --playlist-file lista.txt        # Descargar playlists desde archivo

Archivo de lista de URLs:
  # Comentarios con #
  https://youtube.com/watch?v=VIDEO1
  https://youtube.com/watch?v=VIDEO2
  https://youtube.com/playlist?list=PLAYLIST

Opciones de calidad:
  --max-quality 720p|1080p|1440p|2160p   # Calidad máxima
  --audio-quality 64|128|192|256|320     # Calidad de audio (kbps)
  --no-mp4                               # Usar Matroska en lugar de MP4

Modos:
  --quiet                                # Modo silencioso
  --verbose                              # Modo detallado
        """
    )
    
    parser.add_argument("url", nargs="?", help="URL del video o playlist a descargar")
    parser.add_argument("-p", "--playlist", action="store_true", help="Descargar como playlist (detecta automáticamente)")
    parser.add_argument("-f", "--file", help="Archivo de texto con lista de URLs a descargar")
    parser.add_argument("--playlist-file", help="Archivo de texto con lista de playlists a descargar")
    parser.add_argument("-o", "--directorio", help="Directorio de salida personalizado")
    parser.add_argument("-c", "--config", choices=["mostrar", "ruta"], help="Mostrar configuración o ruta del archivo")
    parser.add_argument("-H", "--historial", action="store_true", help="Mostrar historial de descargas")
    parser.add_argument("--limpiar-historial", action="store_true", help="Borrar historial de descargas")
    parser.add_argument("--config-file", help="Archivo de configuración personalizado")
    parser.add_argument("--max-quality", help="Calidad máxima (720p, 1080p, 1440p, 2160p)")
    parser.add_argument("--audio-quality", help="Calidad de audio en kbps (64, 128, 192, 256, 320)")
    parser.add_argument("--no-mp4", action="store_true", help="Usar Matroska en lugar de MP4")
    parser.add_argument("--quiet", action="store_true", help="Modo silencioso")
    parser.add_argument("--verbose", action="store_true", help="Modo detallado")
    
    args = parser.parse_args()
    
    # Inicializar wrapper con archivo de configuración personalizado
    wrapper = YTDLPWrapper(args.config_file)
    
    # Aplicar opciones de línea de comandos
    if args.max_quality:
        wrapper.config["max_quality"] = args.max_quality
    if args.audio_quality:
        wrapper.config["audio_quality"] = args.audio_quality
    if args.no_mp4:
        wrapper.config["prefer_mp4"] = False
    if args.quiet:
        wrapper.config["quiet"] = True
    if args.verbose:
        wrapper.config["verbose"] = True
    
    # Mostrar información de configuración
    if args.config == "mostrar":
        if not wrapper.config.get("quiet", False):
            print("\n⚙️ Configuración actual:")
            print(json.dumps(wrapper.config, indent=4, ensure_ascii=False))
        return
    elif args.config == "ruta":
        print(f"📄 Archivo de configuración: {os.path.abspath(wrapper.config_file)}")
        return
    
    # Manejar historial
    if args.historial:
        wrapper.show_history()
        return
    elif args.limpiar_historial:
        wrapper.clear_history()
        return
    
    # Descargar desde archivo
    if args.file:
        wrapper.download_from_list(args.file, args.directorio, is_playlist=False)
        return
    elif args.playlist_file:
        wrapper.download_from_list(args.playlist_file, args.directorio, is_playlist=True)
        return
    
    # Verificar que se proporcionó una URL
    if not args.url:
        parser.print_help()
        print("\n❌ Error: Debes proporcionar una URL o usar -f/--file")
        return
    
    # Ejecutar descarga
    if args.playlist or wrapper.is_playlist_url(args.url):
        wrapper.download_playlist(args.url, args.directorio)
    else:
        wrapper.download(args.url, args.directorio)

if __name__ == "__main__":
    # Solo mostrar banner si no está en modo quiet
    if "--quiet" not in sys.argv and "-q" not in sys.argv:
        print("=" * 60)
        print("🎬 ytdlp-wrapper - Descargas de alta calidad")
        print("=" * 60)
    main()