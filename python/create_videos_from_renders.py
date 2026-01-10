"""
Generador de Videos desde Renders
==================================
Este script toma los renders guardados durante el entrenamiento y genera
un video por cada cámara mostrando la evolución del proceso.

Requisitos:
    pip install opencv-python numpy

Uso:
    python create_videos_from_renders.py
"""

import cv2
import numpy as np
import os
from pathlib import Path
import re


def natural_sort_key(s):
    """Clave para ordenar archivos de forma natural (iter_0005, iter_0010, etc.)"""
    return [int(text) if text.isdigit() else text.lower() 
            for text in re.split('([0-9]+)', str(s))]


def create_video_from_camera(camera_folder, output_path, fps=10):
    """
    Crea un video a partir de los renders de una cámara.
    
    Args:
        camera_folder: Ruta a la carpeta con los renders de la cámara
        output_path: Ruta donde guardar el video
        fps: Frames por segundo del video
    """
    # Obtener lista de imágenes ordenadas
    image_files = sorted(
        [f for f in camera_folder.glob('*.png')],
        key=natural_sort_key
    )
    
    if not image_files:
        print(f"  ⚠ No se encontraron imágenes en {camera_folder.name}")
        return False
    
    # Leer primera imagen para obtener dimensiones
    first_image = cv2.imread(str(image_files[0]))
    if first_image is None:
        print(f"  ✗ Error al leer {image_files[0]}")
        return False
    
    height, width, _ = first_image.shape
    
    # Configurar video writer
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video_writer = cv2.VideoWriter(
        str(output_path),
        fourcc,
        fps,
        (width, height)
    )
    
    # Escribir frames
    print(f"  - Procesando {len(image_files)} frames...")
    for img_path in image_files:
        frame = cv2.imread(str(img_path))
        if frame is not None:
            video_writer.write(frame)
    
    video_writer.release()
    print(f"  ✓ Video guardado: {output_path.name}")
    return True


def main():
    # Rutas base
    script_dir = Path(__file__).parent
    renders_dir = script_dir.parent / 'results' / 'renders'
    videos_dir = script_dir.parent / 'results' / 'videos'
    
    # Crear carpeta de videos si no existe
    videos_dir.mkdir(parents=True, exist_ok=True)
    
    print("=" * 70)
    print("GENERADOR DE VIDEOS DESDE RENDERS")
    print("=" * 70)
    
    # Verificar que existe la carpeta de renders
    if not renders_dir.exists():
        print(f"\n✗ Error: No se encontró la carpeta de renders en:")
        print(f"  {renders_dir}")
        print("\nAsegúrate de haber ejecutado el entrenamiento primero.")
        return
    
    # Obtener carpetas de cámaras
    camera_folders = sorted([
        d for d in renders_dir.iterdir() 
        if d.is_dir() and d.name.startswith('cam')
    ])
    
    if not camera_folders:
        print(f"\n✗ Error: No se encontraron carpetas de cámaras en:")
        print(f"  {renders_dir}")
        return
    
    print(f"\nEncontradas {len(camera_folders)} cámaras")
    print(f"Carpeta de entrada: {renders_dir}")
    print(f"Carpeta de salida: {videos_dir}")
    print()
    
    # Crear videos
    videos_created = 0
    for cam_folder in camera_folders:
        cam_name = cam_folder.name
        video_path = videos_dir / f"{cam_name}.mp4"
        
        print(f"Procesando {cam_name}...")
        if create_video_from_camera(cam_folder, video_path, fps=10):
            videos_created += 1
        print()
    
    # Resumen
    print("=" * 70)
    print(f"✓ Proceso completado: {videos_created}/{len(camera_folders)} videos generados")
    print(f"Videos guardados en: {videos_dir}")
    print("=" * 70)


if __name__ == "__main__":
    main()
