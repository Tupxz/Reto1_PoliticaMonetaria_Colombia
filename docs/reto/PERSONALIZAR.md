# 🎨 Personalizar el Documento LaTeX

## Cambios Comunes

### 1. Cambiar título

En `reto.tex`, línea ~20:

```latex
% ANTES:
\title{\textbf{Análisis de Política Monetaria y Transmisión de Inflación 
en Colombia (2006-2026)}}

% DESPUÉS (tu título):
\title{\textbf{Tu nuevo título aquí}}
```

### 2. Cambiar autor y fecha

En `reto.tex`, línea ~25:

```latex
% ANTES:
\author{Nombre del estudiante}
\date{16 de febrero de 2026}

% DESPUÉS:
\author{Tu nombre}
\date{\today}  % O una fecha específica: 1 de marzo de 2026
```

### 3. Cambiar márgenes

En `reto.tex`, línea ~8 (agregar):

```latex
\usepackage{geometry}
\geometry{margin=1.5in}  % márgenes de 1.5 pulgadas
% O específicos:
\geometry{top=1in, bottom=1in, left=1.25in, right=1.25in}
```

### 4. Cambiar fuente

En `reto.tex`, después de `\usepackage{amsmath}`:

```latex
\usepackage{times}      % Times New Roman
% O:
\usepackage{palatino}   % Palatino
% O:
\usepackage{fourier}    % Fourier
```

### 5. Cambiar tamaño de fuente

En `\documentclass`:

```latex
% ANTES:
\documentclass[12pt, a4paper, spanish]{article}

% DESPUÉS (11 pt):
\documentclass[11pt, a4paper, spanish]{article}
```

### 6. Cambiar colores

En `reto.tex`, agregar después de `\usepackage{hyperref}`:

```latex
\usepackage{xcolor}

% Entonces usar en el documento:
\textcolor{red}{Texto en rojo}
\textcolor{blue}{Texto en azul}
```

### 7. Agregar un logo de universidad

En `reto.tex`, en la portada (después de `\title{...}`):

```latex
\title{\includegraphics[width=3cm]{logo_universidad.png}\\[0.5cm]
\textbf{Análisis de Política Monetaria...}}
```

---

## Cambios Avanzados

### Cambiar estilo de párrafos

En el preámbulo:

```latex
% Espaciado entre líneas (1.5 espacios)
\usepackage{setspace}
\onehalfspacing

% O doble espaciado:
\doublespacing
```

### Cambiar estilo de secciones

En el preámbulo:

```latex
\usepackage{sectsty}
\sectionfont{\color{blue}\Large}
\subsectionfont{\color{darkblue}\large}
```

### Agregar números de línea (para revisión)

En el preámbulo:

```latex
\usepackage{lineno}
\linenumbers
```

### Cambiar bibliografía de estilo

En la sección de referencias:

```latex
% ANTES:
\begin{thebibliography}{99}

% DESPUÉS (usando bibtex):
\usepackage{natbib}
\bibliographystyle{apalike}
\bibliography{referencias}  % Carga desde referencias.bib
```

---

## Agregar Contenido Nuevo

### Insertar sección nueva

```latex
\section{Tu Nueva Sección}

Texto de introducción.

\subsection{Subtítulo}

Más contenido aquí.
```

### Insertar ecuación numerada

```latex
\begin{equation}
\Delta_y = \alpha + \beta_1 \Delta x_{t-1} + u_t
\label{eq:adl}
\end{equation}

Referencia: ver ecuación \ref{eq:adl}.
```

### Insertar tabla

```latex
\begin{table}[h]
\centering
\begin{tabular}{lcc}
\toprule
Variable & Coef. & P-valor \\
\midrule
DTF & -0.2307 & 0.0025 \\
TRM & 1.5440 & 0.0000 \\
\bottomrule
\end{tabular}
\caption{Coeficientes del modelo}
\label{tab:coef}
\end{table}
```

### Insertar figura

```latex
\begin{figure}[h]
\centering
\includegraphics[width=0.8\textwidth]{outputs/ADL/06_diagnosticos_ADL.pdf}
\caption{Diagnósticos del modelo ADL}
\label{fig:diag}
\end{figure}
```

### Insertar código R

```latex
\begin{verbatim}
# Código R
modelo <- lm(y ~ x1 + x2)
summary(modelo)
\end{verbatim}

% O con más formato (requiere: \usepackage{listings})
\begin{lstlisting}[language=R]
modelo <- lm(y ~ x1 + x2)
summary(modelo)
\end{lstlisting}
```

---

## Errores Comunes y Soluciones

### Error: "Undefined control sequence"

**Causa:** Comando LaTeX no reconocido
**Solución:** Verifica que hayas incluido el paquete correcto

```latex
% Ejemplo: \textcolor no funciona sin xcolor
\usepackage{xcolor}  % Agregar esto
```

### Error: "Missing $ inserted"

**Causa:** Modo matemático no cerrado correctamente
**Solución:** Verifica que matemáticas estén entre $ $ o \[ \]

```latex
% MALO: $x + y
% BUENO: $x + y$
```

### Problema: Gráficos no aparecen

**Causa:** Ruta incorrecta o formato no soportado
**Solución:** Usa rutas relativas correctas

```latex
% MALO:
\includegraphics{outputs/ADL/06_diagnosticos_ADL.pdf}

% BUENO (desde docs/reto/):
\includegraphics{../../outputs/ADL/06_diagnosticos_ADL.pdf}
```

### Problema: Referencias no funcionan

**Causa:** Necesitas compilar dos veces
**Solución:** Ejecuta pdflatex dos veces

```bash
pdflatex reto.tex
pdflatex reto.tex  # Asegúrate de ejecutar dos veces!
```

---

## Recursos Útiles

- **Overleaf:** https://www.overleaf.com (editor LaTeX online)
- **ShareLaTeX:** https://www.sharelatex.com
- **LaTeX Wikibook:** https://en.wikibooks.org/wiki/LaTeX
- **CTAN (paquetes):** https://ctan.org/

---

## Validación Antes de Entrega

```bash
# Compilar sin errores
pdflatex reto.tex

# Verificar que el PDF se creó
ls -lh reto.pdf

# Ver el resultado
open reto.pdf  # macOS
xdg-open reto.pdf  # Linux
```

---

**¡Listo!** Ahora puedes personalizar tu documento LaTeX según tus necesidades.
