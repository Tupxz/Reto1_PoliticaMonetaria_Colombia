# 📚 Documentación - Reto 1

## Estructura

```
docs/
├── README.md                    ← Estás aquí
├── reto/
│   ├── DOCUMENTO_ACADEMICO_ADL.md    (análisis riguroso, 45 min)
│   ├── RESUMEN_ANALISIS_ADL.md       (reporte técnico, 20 min)
│   ├── GUIA_LECTURA.md               (navegación, 5 min)
│   ├── QUICK_REFERENCE_ADL.md        (resumen ejecutivo, 5 min)
│   ├── ESTADO_FINAL_ANALISIS.md      (estado del proyecto, 5 min)
│   ├── COMPILAR.md                   (cómo compilar LaTeX)
│   ├── GRAFICOS.md                   (cómo insertar gráficos)
│   └── reto.tex                      (documento LaTeX - PRINCIPAL)
└── slides/
    └── (vacío, para futuras presentaciones)
```

## Empezar

### ⚡ Si tienes 5 minutos
Lee: `reto/QUICK_REFERENCE_ADL.md` o `reto/ESTADO_FINAL_ANALISIS.md`

### ⏱️ Si tienes 20 minutos
Lee: `reto/RESUMEN_ANALISIS_ADL.md`

### 📖 Si tienes 45+ minutos
Lee: `reto/DOCUMENTO_ACADEMICO_ADL.md`

### 🗺️ No sabes por dónde empezar
Lee: `reto/GUIA_LECTURA.md`

### 📝 Para usar el LaTeX
Ve a `reto/COMPILAR.md` para instrucciones paso a paso

---

## Archivos en `reto/`

| Archivo | Duración | Contenido |
|---------|----------|----------|
| **reto.tex** ⭐ | - | **Documento LaTeX listo para compilar a PDF** |
| **COMPILAR.md** | 5 min | Instrucciones para compilar reto.tex |
| **GRAFICOS.md** | 5 min | Cómo insertar diagnósticos en el LaTeX |
| **QUICK_REFERENCE_ADL.md** | 5 min | Resumen de hallazgos principales |
| **GUIA_LECTURA.md** | 5 min | Orientación sobre qué leer y en qué orden |
| **RESUMEN_ANALISIS_ADL.md** | 20 min | Reporte técnico con ecuaciones e interpretación |
| **DOCUMENTO_ACADEMICO_ADL.md** | 45 min | Análisis riguroso con teoría, metodología y discusión |
| **ESTADO_FINAL_ANALISIS.md** | 5 min | Estado del proyecto, archivo de cambios |

---

## Compilar LaTeX (Resumen Rápido)

```bash
cd docs/reto/
pdflatex reto.tex
pdflatex reto.tex  # Ejecutar dos veces
```

Resultado: `docs/reto/reto.pdf`

**Para más detalles:** Ver `reto/COMPILAR.md`

---

## Contenido de `reto.tex`

✓ Portada con título, autor y fecha  
✓ Resumen Ejecutivo  
✓ Introducción y Marco Teórico (4 canales de transmisión)  
✓ Datos y Variables (IPC, DTF, TRM, ISE)  
✓ Metodología Econométrica (ADL, OLS, multiplicadores)  
✓ Resultados (tabla de coeficientes, diagnósticos)  
✓ Conclusiones  
✓ Apéndice con referencias y código R  

---

## Estructura del Proyecto

```
Reto1_PoliticaMonetaria_Colombia/
├── data/
│   ├── raw/           (datos sin procesar)
│   └── processed/     (datos limpios para análisis)
├── outputs/
│   ├── EDA/          (gráficos exploratorios)
│   └── ADL/          (resultados del modelo ADL) ⭐
├── scripts/
│   ├── 00_main.R      (maestro)
│   ├── 01_packages.R
│   ├── 02_limpieza.R
│   ├── 03_descriptivas.R
│   └── 04_ADL_SIMPLIFICADO.R  (modelo ADL) ⭐
├── docs/             (documentación académica)
│   ├── reto/        (análisis ADL)
│   └── slides/      (presentaciones)
└── README.md
```

---

## Próximos Pasos

1. **Compilar el LaTeX:** Ve a `reto/COMPILAR.md`
2. **Insertar gráficos:** Ve a `reto/GRAFICOS.md`
3. **Customizar el documento:** Edita `reto.tex` directamente
4. **Crear presentación:** Usa `docs/slides/` para Beamer o RevealJS
