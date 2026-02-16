# 📝 LaTeX para Reto 1

## Compilar PDF

### Opción 1: Con `pdflatex` (recomendado)

```bash
cd docs/reto/
pdflatex -interaction=nonstopmode reto.tex
pdflatex -interaction=nonstopmode reto.tex  # Ejecutar dos veces
```

### Opción 2: Con `xelatex` (mejor para UTF-8 y fuentes)

```bash
cd docs/reto/
xelatex -interaction=nonstopmode reto.tex
xelatex -interaction=nonstopmode reto.tex
```

### Opción 3: Con Pandoc (convertir de Markdown)

```bash
cd docs/reto/
pandoc DOCUMENTO_ACADEMICO_ADL.md \
  --to latex \
  --output reto_from_md.tex \
  --standalone \
  --number-sections \
  -V documentclass=article \
  -V geometry:margin=1in
```

## Resultado

Se generará `reto.pdf` en `docs/reto/`

## Estructura del archivo LaTeX

El archivo `reto.tex` incluye:

- ✓ **Portada** con título, autor y fecha
- ✓ **Resumen Ejecutivo** (1 página)
- ✓ **Introducción** y Marco Teórico
- ✓ **Sección de Datos y Variables** (completa)
- ✓ **Metodología Econométrica** (ADL, OLS, multiplicadores)
- ✓ **Resultados** (tabla de coeficientes, diagnósticos)
- ✓ **Conclusiones** con limitaciones y recomendaciones
- ✓ **Apéndice** con referencias y código R
- ✓ **Bibliografía** (APA style)

## Customización

Para adaptar el documento, edita:

```latex
% Cambiar título
\title{Tu nuevo título aquí}

% Cambiar autor
\author{Tu nombre}

% Cambiar márgenes
\geometry{margin=1.5in}

% Cambiar fuente
\usepackage{palatino}
\usepackage{times}
```

## Requisitos

Necesitas tener instalado LaTeX. En macOS:

```bash
# Con Homebrew
brew install --cask mactex

# O instalar BasicTeX (más ligero)
brew install --cask basictex
```

En Linux:
```bash
sudo apt-get install texlive-full
```

En Windows:
Descargar MiKTeX desde https://miktex.org/

## Archivos en `docs/reto/`

| Archivo | Descripción |
|---------|------------|
| **reto.tex** | Documento LaTeX completo listo para compilar |
| **DOCUMENTO_ACADEMICO_ADL.md** | Fuente original en Markdown |
| **RESUMEN_ANALISIS_ADL.md** | Resumen técnico (puede usarse como referencia) |
| **GUIA_LECTURA.md** | Orientación sobre qué leer |
| **QUICK_REFERENCE_ADL.md** | Resumen ejecutivo rápido |
| **ESTADO_FINAL_ANALISIS.md** | Estado del proyecto |

---

**Nota:** El archivo `reto.tex` está basado en `DOCUMENTO_ACADEMICO_ADL.md` 
pero con formato LaTeX profesional para una mejor presentación académica.
