# MiniGaussianSplatting

Implementación de un pipeline simplificado de **3D Gaussian Splatting**,  
desarrollado como Trabajo del Máster en Sistemas Inteligentes y Aplicaciones  
Numéricas en Ingeniería (SIANI) – ULPGC, curso 2025/2026.

**Autor:** Acaymo Jesús Granado Sánchez  
**Asignatura:** Programación y Prototipado  
**Fecha:** Enero 2026  

Este proyecto implementa desde cero un pipeline funcional inspirado en *3D Gaussian
Splatting*, combinando C++ (renderizado) y MATLAB (optimización).

A diferencia de implementaciones industriales, esta versión:

- Utiliza gaussianas 3D simplificadas.
- Realiza la optimización mediante gradientes por diferencias finitas.
- Está pensada como herramienta experimental y de aprendizaje.

---

## Estructura del proyecto

MiniGaussianSplatting/  
├── cpp/  
│   ├── image.cpp  
│   ├── image.h  
│   ├── render_mex.cpp  
│   ├── render_mex.mexw64 (MEX ya compilado para Windows)  
│   └── stb_image_write.h  
│  
├── data/  
│   ├── cameras.mat  
│   └── targets/  
│       ├── cam01.png  
│       ├── cam02.png  
│       ├── cam03.png  
│       ├── cam04.png  
│       ├── cam05.png  
│       ├── cam06.png  
│       ├── cam07.png  
│       └── cam08.png  
│  
├── matlab/  
│   ├── utils/  
│   │   ├── create_camera_ring.m  
│   │   ├── generate_multiview_dataset.m  
│   │   ├── plot_initial_scene.m  
│   │   ├── plot_training_progress.m  
│   │   ├── plot_trajectories.m  
│   │   ├── print_iteration_info.m  
│   │   └── print_final_results.m  
│   │  
│   ├── compute_metrics.m  
│   ├── setup_paths.m  
│   └── train_multiview.m  
│  
├── python/  
│   └── create_videos_from_renders.py  
│  
└── results/  
    ├── renders/  
    └── videos/  

---

## Flujo de ejecución

1. Preparar el entorno en MATLAB

Desde la raíz del proyecto:

    setup_paths

2. Generar un dataset multivista sintético

Antes de entrenar, ejecuta:

    generate_multiview_dataset

Este script:
- Crea un anillo de cámaras alrededor de la escena.
- Genera imágenes objetivo multivista.
- Guarda las imágenes en `data/targets/`.
- Guarda las cámaras en `data/cameras.mat`.

3. Entrenamiento

Una vez generado el dataset:

    train_multiview

Este script:
- Inicializa un conjunto de gaussianas.
- Selecciona vistas aleatoriamente.
- Renderiza mediante el MEX en C++.
- Calcula la función de pérdida (L1 + D-SSIM).
- Estima gradientes por diferencias finitas.
- Actualiza posición y escala de las gaussianas.
- Guarda renders intermedios en `results/renders/`.

4. Generar un vídeo del entrenamiento (opcional)

Desde la carpeta `python/`:

    python create_videos_from_renders.py

Esto genera vídeos en `results/videos/` a partir de los renders.

