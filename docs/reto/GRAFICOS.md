# 📊 Cómo Insertar Gráficos en el LaTeX

## Paso 1: Ubicar los gráficos

Los gráficos del ADL están en:

```
outputs/ADL/06_diagnosticos_ADL.pdf
```

Este PDF contiene 6 gráficos de diagnóstico:
1. Residuales en el tiempo
2. Histograma + Densidad
3. Q-Q Plot
4. ACF
5. PACF
6. Fitted vs Residuals

## Paso 2: Insertar en el LaTeX

En `docs/reto/reto.tex`, añade en la sección de Resultados (después de Tabla 1):

```latex
\subsection{Análisis de Diagnósticos}

Los gráficos de diagnóstico en la Figura \ref{fig:diagnosticos} 
muestran que los residuales del modelo satisfacen los supuestos 
de normalidad, homocedasticidad y ausencia de autocorrelación.

\begin{figure}[h]
  \centering
  \includegraphics[width=1\textwidth]{../../outputs/ADL/06_diagnosticos_ADL.pdf}
  \caption{Diagnósticos del modelo ADL(2,2,2,2). 
  Panel superior izquierdo: Series de residuales. 
  Panel superior derecho: Histograma y densidad. 
  Panel medio izquierdo: Q-Q plot. 
  Panel medio derecho: ACF. 
  Panel inferior izquierdo: PACF. 
  Panel inferior derecho: Valores ajustados vs residuales.}
  \label{fig:diagnosticos}
\end{figure}
```

## Paso 3: Añadir encabezados de figuras

En el preámbulo del LaTeX, asegúrate que esté:

```latex
\usepackage{graphicx}
\usepackage{float}
```

Ya están incluidos en `reto.tex`.

## Paso 4: Compilar nuevamente

```bash
cd docs/reto/
pdflatex -interaction=nonstopmode reto.tex
pdflatex -interaction=nonstopmode reto.tex
```

## Resultado

El PDF `reto.pdf` tendrá los gráficos embebidos en la sección de Resultados.

---

## Opcional: Crear más gráficos desde R

Si necesitas gráficos adicionales, puedes cargar el modelo y crear nuevos:

```R
# En R
load("outputs/ADL/datos_adl.rds")  # Cargar datos
load("outputs/ADL/modelo_ADL.rds") # Cargar modelo

# Crear gráfico personalizado
pdf("outputs/ADL/07_analisis_impulso_respuesta.pdf", width=10, height=6)
# Tu código de gráfico aquí
dev.off()
```

Luego inserta en LaTeX con el mismo comando `\includegraphics`.
