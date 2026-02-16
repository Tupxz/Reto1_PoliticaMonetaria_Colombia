# Reto 1 – Haciendo Macroeconomía
**Econometría II – Programa de Economía**  
**Universidad EAFIT | 2026-I**

**Profesor:** Gustavo Adolfo García  
**Fecha máxima de entrega:** 26 de febrero de 2026  

## Integrantes
- **Santiago Tupaz**
- **Moisés Quintero**

---

## 1. Descripción general del proyecto

Este proyecto se desarrolla en el marco del **Reto 1: Haciendo Macroeconomía**, correspondiente al curso **Econometría II** del Programa de Economía de la Universidad EAFIT.

El objetivo principal es **evaluar la efectividad de la política monetaria en Colombia**, específicamente el uso de la **tasa de interés** como instrumento para controlar la inflación. Para ello, se construye y estima un **modelo VAR (Vector Autoregressive)** empleando datos reales de series de tiempo mensuales, siguiendo las metodologías vistas hasta el **examen parcial 1** del curso.

El curso y sus lineamientos oficiales pueden consultarse en:
https://gusgarciacruz.github.io/EconometriaII/

---

## 2. Pregunta de investigación

> ¿Cuál es el efecto dinámico de la tasa de interés sobre la inflación en Colombia y qué tan efectiva ha sido la política monetaria para contener la inflación?

---

## 3. Variables y datos

### Variables principales

- **Inflación:** Variación anual del Índice de Precios al Consumidor (IPC), anualizada.
- **Tasa de interés:** Tasa de los Certificados de Depósito a Término (CDT) a 90 días.

### Frecuencia y periodo

- **Frecuencia:** Mensual  
- **Periodo de análisis:** Determinado según disponibilidad de datos y criterios del grupo, y especificado en el documento final.

### Fuentes de información

Las series de tiempo utilizadas provienen de **fuentes oficiales**, principalmente:

- **Banco de la República de Colombia**
- **DANE**

Las fuentes exactas y los enlaces de descarga se detallan explícitamente en el documento escrito del proyecto.

---

## 4. Metodología econométrica

Se estima un **modelo VAR (Vector Autoregressive)** para capturar la relación dinámica conjunta entre la inflación y la tasa de interés. Este enfoque permite:

- Analizar la interacción bidireccional entre las variables.
- Evaluar los efectos dinámicos mediante **funciones impulso–respuesta**.
- Analizar la descomposición de la varianza del error de pronóstico.
- Realizar **predicciones fuera de muestra** de la inflación.

El número de rezagos del VAR se selecciona utilizando criterios de información estándar (AIC, BIC, HQ), y el tratamiento de la estacionariedad de las series se justifica en el documento final.

---

## 5. Predicción de inflación para 2026

Con base en el modelo VAR estimado, se realizan **pronósticos de la inflación para el año 2026**, haciendo énfasis en:

- **Predicción puntual de la inflación para febrero de 2026**, cuyo valor exacto se reporta explícitamente.
- Comparación posterior con el dato oficial publicado a mediados de marzo de 2026.

---

## 6. Resultados esperados y evaluación

El proyecto permite:

- Evaluar empíricamente la efectividad de la política monetaria en Colombia.
- Analizar los mecanismos de transmisión de la tasa de interés hacia la inflación.
- Evaluar la capacidad predictiva de un modelo VAR aplicado a datos macroeconómicos.

### Bonos

- **Bono de 0.5:** Para el grupo cuya predicción de inflación para febrero de 2026 sea la más cercana al dato real.
- **Bono de 1.0:** Para los dos grupos con mayor número de *likes* en la publicación en redes sociales explicando el trabajo y los resultados.

---

## 7. Archivos y estructura del proyecto

Todos los archivos del proyecto cumplen estrictamente con el siguiente formato de nombre: apellido1_apellido2_apellido3_apellido4_R1
El archivo comprimido (ZIP) entregado contiene:

- Documento escrito del proyecto.
- Bases de datos utilizadas.
- Código completo y reproducible.
- Este archivo `README.md`.

---

## 8. Reproducibilidad

El código incluido en el proyecto permite:

- Cargar o reproducir la base de datos utilizada.
- Replicar todas las estimaciones del modelo VAR.
- Generar los resultados, gráficos y predicciones presentados en el documento final.

---

## 9. Referencias

Las referencias académicas, metodológicas y de fuentes de datos se encuentran detalladas en la sección de referencias del documento escrito, siguiendo normas académicas.

---

## Reproducibility

All results in this project can be reproduced by running the scripts
in the `/scripts` folder in numerical order.
