---
title: ""
format: 
  html:
    embed-resources: true
editor: visual
execute:
  echo: true
  warning: false
  message: false
editor_options: 
  chunk_output_type: inline
---

<br><br><br>

::: {style="text-align: center;"}
# **Transmisión dinámica de la política monetaria y factores macroeconómicos sobre la inflación en Colombia: un enfoque VAR (quarto)**

<br><br>

### Santiago Tupaz

### Moisés Quintero

<br><br>

**Profesor:** Gustavo García\
**Universidad:** Universidad EAFIT\
**Curso:** Econometría II

<br>

**Fecha de entrega:** 26 de febrero de 2026
:::

<br><br><br>

## 1. Librerias



Para el desarrollo del análisis econométrico se emplean diversas librerías especializadas en manipulación de datos, series de tiempo y estimación de modelos dinámicos multivariados. A continuación, se describe el propósito de cada grupo de paquetes:

Las librerías **`tidyverse`** y **`ggplot2`** se utilizan para la manipulación, limpieza y visualización de datos. Estas herramientas permiten estructurar bases de datos de manera eficiente, transformar variables y generar gráficos descriptivos claros que facilitan el análisis exploratorio previo a la modelación.

El paquete **`lubridate`** se emplea para el manejo adecuado de fechas y formatos temporales, lo cual es fundamental en el tratamiento de series de tiempo macroeconómicas.

Para la estimación y análisis del modelo VAR se utilizan principalmente **`vars`**, que permite estimar modelos autorregresivos vectoriales, generar funciones impulso-respuesta (IRF) y descomposiciones de varianza, y **`urca`** y **`tseries`**, que se emplean para realizar pruebas de raíz unitaria (ADF, Phillips-Perron) y cointegración, garantizando el tratamiento adecuado de la estacionariedad.

La librería **`dynlm`** se utiliza para estimar modelos dinámicos mediante mínimos cuadrados incorporando rezagos explícitos, mientras que **`lmtest`** y **`sandwich`** permiten realizar pruebas de diagnóstico (autocorrelación, heterocedasticidad, estabilidad) y obtener errores estándar robustos.

El paquete **`strucchange`** se emplea para analizar posibles cambios estructurales en las series, elemento particularmente relevante en el estudio de política monetaria y choques macroeconómicos.

Para análisis y modelación complementaria de series de tiempo se utilizan **`forecast`**, **`fpp3`** y **`zoo`**, que facilitan el manejo de estructuras temporales, pronósticos y transformaciones específicas de datos indexados en el tiempo.

Finalmente, **`readxl`** y **`openxlsx`** se emplean para la importación y exportación de datos en formato Excel, asegurando reproducibilidad y compatibilidad con fuentes externas.

En conjunto, estas librerías permiten construir un entorno reproducible y robusto para el análisis de política monetaria mediante técnicas modernas de econometría de series de tiempo.

## 2. Limpieza de bases de datos

### 2.1 Tasa Representativa del Mercado (TRM)



La Tasa Representativa del Mercado (TRM) se incorpora en el modelo como una variable fundamental para capturar los efectos del canal cambiario sobre la dinámica inflacionaria en Colombia. Dado que la economía colombiana es abierta y presenta una alta dependencia de bienes importados, las variaciones en el tipo de cambio afectan directamente los precios internos a través del mecanismo de pass-through cambiario.

En particular, una depreciación del peso colombiano encarece los bienes importados y los insumos intermedios, lo cual puede trasladarse a los precios al consumidor. Por esta razón, la TRM constituye un determinante relevante dentro del sistema VAR, permitiendo evaluar la transmisión de choques externos hacia la inflación doméstica.

### 2.1.1 Transformación de la variable

La TRM se transforma utilizando la diferencia logarítmica a 12 meses:

$$
\Delta_{12} \log(\text{TRM}_t)=\log\left(\frac{\text{TRM}_t}{\text{TRM}_{t-12}}\right)\times 100
$$

Esta transformación responde a tres razones principales:

1.  **Interpretación económica:** La diferencia logarítmica permite aproximar la variación porcentual anual del tipo de cambio, lo que facilita la interpretación económica de los coeficientes.

2.  **Consistencia temporal:** Dado que la inflación suele analizarse en términos anuales, utilizar una variación interanual de la TRM mantiene coherencia en el horizonte temporal.

3.  **Estacionariedad:** Las series en niveles suelen presentar tendencia o comportamiento no estacionario. Tomar logaritmos y diferencias ayuda a estabilizar la media y la varianza, condición necesaria para la estimación válida de modelos VAR.

En consecuencia, la variable `TRM_log` representa la tasa de depreciación (o apreciación) anual del tipo de cambio nominal, expresada en términos porcentuales.

### 2.2 Índice de Precios al Consumidor (IPC)



El Índice de Precios al Consumidor (IPC) se incorpora como la variable dependiente principal del análisis, dado que constituye la medida oficial de la inflación en Colombia. El IPC refleja la variación en los precios de una canasta representativa de bienes y servicios consumidos por los hogares, permitiendo evaluar la evolución del poder adquisitivo y la estabilidad de precios.

En el contexto del modelo VAR, la inflación se modela como una variable endógena que puede responder dinámicamente a choques provenientes del tipo de cambio, variables financieras y factores externos. Por tanto, su correcta transformación resulta fundamental para garantizar coherencia econométrica e interpretación económica clara.

### 2.2.1 Transformación de la variable

La inflación se construye a partir de la variación logarítmica interanual del IPC:

$$
\Delta_{12} \log(\text{IPC}_t)
=
\log\left(\frac{\text{IPC}_t}{\text{IPC}_{t-12}}\right)\times 100
$$

Esta especificación se adopta por tres razones principales:

1.  **Interpretación económica:** La diferencia logarítmica aproxima la tasa de inflación anual en términos porcentuales.

2.  **Consistencia temporal:** Dado que los efectos macroeconómicos suelen analizarse en horizontes anuales, la variación interanual captura mejor los procesos inflacionarios persistentes.

3.  **Propiedades econométricas:** Trabajar en diferencias logarítmicas contribuye a reducir problemas de no estacionariedad asociados a series en niveles y facilita la estimación válida de modelos VAR.

En consecuencia, la variable `inflacion_anual` representa la tasa de inflación anual expresada en porcentaje, coherente con la transformación aplicada a la TRM y con el marco metodológico del modelo, aunque para el caso de Colombia la transformación de esta variable no necesariamente la vuelve estacionaria y posiblemente haya que diferenciarla de nuevo.

### 2.3 Tasa de Interés DTF (CDT a 90 días)



La tasa DTF, correspondiente al promedio mensual de los Certificados de Depósito a Término (CDT) a 90 días, se incorpora en el modelo como proxy de las condiciones monetarias domésticas de corto plazo. Esta variable refleja el costo del dinero en el mercado financiero colombiano y constituye un canal relevante de transmisión de la política monetaria hacia la actividad económica y la dinámica inflacionaria.

En el marco de un modelo VAR, la DTF permite capturar el efecto de los choques monetarios internos sobre la inflación. Movimientos en la tasa de interés afectan el consumo, la inversión y las expectativas, incidiendo finalmente en la trayectoria de los precios.

### 2.3.1 Especificación de la variable

A diferencia del IPC y la TRM, la DTF no corresponde a un índice acumulativo sino a una tasa porcentual expresada en niveles. Por esta razón, no se transforma mediante diferencias logarítmicas.

La variable se incorpora como:

$$
\text{DTF}_t
$$

Esta elección se fundamenta en tres consideraciones:

1.  **Naturaleza de la variable:** Al ser una tasa de interés nominal, su interpretación económica se realiza directamente en niveles.

2.  **Consistencia econométrica:** Las tasas de interés suelen presentar propiedades de estacionariedad en niveles o en primera diferencia, lo cual debe verificarse mediante pruebas de raíz unitaria.

3.  **Interpretación dinámica:** Incluir la DTF en niveles facilita la lectura de las funciones impulso–respuesta, permitiendo analizar cómo un aumento de un punto porcentual en la tasa afecta la inflación.

En consecuencia, la variable `DTF_nivel` representa la tasa de interés promedio mensual de los CDT a 90 días, utilizada como indicador de las condiciones monetarias internas.

### 2.4 Indicador de Seguimiento a la Economía (ISE)



El Indicador de Seguimiento a la Economía (ISE) se emplea en este trabajo como una medida mensual de la actividad económica agregada en Colombia. Dado que el Producto Interno Bruto (PIB) se publica con frecuencia trimestral y con rezagos temporales, el ISE constituye un proxy adecuado de alta frecuencia, permitiendo capturar de manera más oportuna la dinámica del ciclo económico.

La depuración y estructuración inicial de la base de datos se realizó principalmente en Excel. En esta etapa se verificó la consistencia de las fechas, la correcta identificación de las series y el cálculo de las transformaciones necesarias. Posteriormente, la base limpia fue importada a R exclusivamente para su integración con las demás variables del modelo y para asegurar la homogeneidad en el formato temporal.

Para el análisis se utiliza la serie del ISE desestacionalizada. Esta elección responde a que las fluctuaciones estacionales pueden introducir patrones sistemáticos no relacionados con la dinámica económica estructural, lo cual podría generar relaciones espurias en el modelo VAR. Al emplear la serie ajustada por estacionalidad se elimina el componente recurrente asociado al calendario, reduciendo ruido y mejorando la identificación de choques macroeconómicos.

### 2.4.1 Transformación de la variable

Adicionalmente, se trabaja con la variación logarítmica interanual del ISE:

$$
\Delta_{12} \log(ISE_t) = \log\left(\frac{ISE_t}{ISE_{t-12}}\right) \times 100
$$

Esta transformación permite:

-   Interpretar la variable como una tasa de crecimiento porcentual anual.
-   Reducir problemas de no estacionariedad en niveles.
-   Homogeneizar las unidades de medida con las demás variables transformadas en el modelo.

En consecuencia, el ISE desestacionalizado en variación logarítmica anual se incorpora como proxy del componente real de la economía dentro del sistema VAR.

### 2.5 Variable Exógena: Inflación de Estados Unidos



Con el fin de capturar la influencia de las condiciones macroeconómicas externas sobre la economía colombiana, se incorpora como variable exógena la inflación de Estados Unidos.

### 2.5.1 Transformación de la variable

La serie utilizada corresponde al índice *Consumer Price Index for All Urban Consumers (All Items), Seasonally Adjusted* (CPIAUCSL). Dado que esta serie se encuentra en niveles, se transforma en variación logarítmica interanual con el objetivo de obtener una tasa de inflación anual y reducir posibles problemas de no estacionariedad:

$$
\Delta_{12} \log(CPI_t^{US}) =
\log\left(\frac{CPI_t^{US}}{CPI_{t-12}^{US}}\right) \times 100
$$

La inclusión de esta variable se fundamenta en que Colombia es una economía pequeña y abierta, por lo que los choques inflacionarios internacionales pueden afectar las condiciones financieras globales, las expectativas, los flujos de capital y, en consecuencia, el comportamiento del tipo de cambio y la dinámica inflacionaria interna.

Esta variable se incorpora como exógena en el modelo VAR bajo el supuesto de que la economía colombiana no influye en la determinación de la inflación estadounidense.

### 2.6 Variable Exógena: Precio Internacional del Petróleo (Brent)



El precio internacional del petróleo Brent se incorpora como variable exógena con el objetivo de capturar choques externos reales que afectan a la economía colombiana. Dado el papel del sector petrolero en las exportaciones, en los términos de intercambio y en las cuentas fiscales, las variaciones del precio internacional del crudo constituyen un determinante relevante de la dinámica macroeconómica doméstica.

### 2.6.1 Transformación de la variable

La serie original se encuentra en frecuencia diaria. Con el fin de hacerla consistente con el resto de las variables del modelo (frecuencia mensual), se construye el promedio mensual del precio diario:

$$
Brent_{m} = \frac{1}{N_m} \sum_{d=1}^{N_m} Brent_{d}
$$

donde (N_m) corresponde al número de días observados en el mes (m). El uso del promedio mensual reduce la volatilidad de alta frecuencia y permite aproximar el precio representativo enfrentado por la economía durante cada periodo.

Posteriormente, la serie mensual se transforma en variación logarítmica interanual:

$$
\Delta_{12} \log(Brent_t) =
\log\left(\frac{Brent_t}{Brent_{t-12}}\right) \times 100
$$

Esta transformación permite interpretar la variable como la tasa de crecimiento porcentual anual del precio del petróleo y contribuye a mitigar problemas de no estacionariedad asociados a series en niveles.

Dado que el cálculo de la variación interanual requiere 12 observaciones previas, la serie transformada inicia en enero de 2006, utilizando como base el valor correspondiente a enero de 2005. Esta decisión garantiza consistencia temporal en la construcción de la variable y alineación con el periodo de análisis del modelo.\
\
**Nota**: para este trabajo se unificaron todas las variables en una misma base datos que empieza desde el 2006-1 hasta 2026-1 (solo algunas variables pero conssrvando NA's para no perder datos reales)



## 3. Analisís exploratorio

### 3.1 Gráficas de las series 


::: {.cell}
::: {.cell-output-display}
![](VAR_files/figure-pdf/eda_series_6_variables_estetico-1.pdf)
:::
:::


### 3.2 Histogramas


::: {.cell}
::: {.cell-output-display}
![](VAR_files/figure-pdf/eda_histogramas_6_variables-1.pdf)
:::

::: {.cell-output-display}
![](VAR_files/figure-pdf/eda_histogramas_6_variables-2.pdf)
:::

::: {.cell-output-display}
\begin{table}

\caption{\label{tab:eda_histogramas_6_variables}Asimetría y curtosis de las variables del modelo VAR}
\centering
\begin{tabular}[t]{lrr}
\toprule
Variable & Asimetria & Curtosis\\
\midrule
Inflación Colombia (log 12) & 1.2445 & 4.1946\\
TRM (log 12) & 0.4660 & 3.5525\\
DTF (nivel) & 0.8530 & 3.0320\\
ISE (log 12, DAE) & -1.4565 & 13.6334\\
Inflación EE.UU. (log 12) & 1.0118 & 4.7052\\
\addlinespace
Precio del petróleo Brent (log 12) & -0.3224 & 3.5258\\
\bottomrule
\end{tabular}
\end{table}


:::
:::


