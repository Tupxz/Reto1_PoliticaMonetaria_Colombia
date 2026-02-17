# Análisis ADL: Transmisión de Política Monetaria a Inflación en Colombia

## Descripción General

Este directorio contiene el análisis econométrico completo de los mecanismos de transmisión de la política monetaria hacia la inflación en Colombia, período 2006-2025. Utiliza un modelo **ADL(1,1,1,1)** estimado por Mínimos Cuadrados Ordinarios.

## Contenido del Directorio

### 📊 Gráficas de Diagnóstico y Proyección

1. **`01_diagnosticos_ADL.pdf`** (47 KB)
   - Cuatro paneles de diagnóstico estándar del modelo:
     - Residuos vs Valores Ajustados (aleatoriedad y homocedasticidad)
     - Q-Q Plot (normalidad de residuos)
     - Scale-Location (heterocedasticidad)
     - Residuos en el Tiempo (autocorrelación visual)

2. **`02_predicciones_ADL.pdf`** (7.5 KB)
   - Comparación de Inflación Real (línea azul) vs Predicción del Modelo (línea roja punteada)
   - Período: 2006-01 a 2025-01
   - Evalúa bondad de ajuste del modelo

3. **`03_distribucion_rezagos_ADL.pdf`** (6.5 KB)
   - Visualización de la distribución Koyck de rezagos
   - Marca **mediana de rezagos** (28.72 meses) - línea roja
   - Marca **media de rezagos** (40.94 meses) - línea naranja
   - Muestra cuán rápido decaen los efectos de shocks

4. **`04_proyeccion_feb2026_ADL.pdf`** (4.9 KB)
   - Proyección de inflación para Febrero 2026
   - Últimos 24 meses de datos reales
   - Proyección: 5.0785% (reducción de 1.34 pb vs Enero 2025)

### 📄 Documentos Académicos

1. **`Analisis_ADL_Completo.pdf`** (160 KB) ⭐ **PRINCIPAL**
   - Documento académico completo en español
   - Secciones:
     - Introducción y motivación
     - Marco metodológico
     - Especificación del modelo ADL(1,1,1,1)
     - **ENFOQUE ESPECIAL**: Análisis detallado de Media y Mediana de Rezagos
     - Multiplicadores de Largo Plazo
     - Diagnósticos del modelo
     - Proyección Feb 2026
     - Conclusiones y recomendaciones de política
   - Tabla de contenidos completa
   - Referencias bibliográficas

2. **`Analisis_ADL_Transmision_Politica_Monetaria.pdf`** (83 KB)
   - Versión extendida con mayor profundidad técnica
   - Más detalles econométricos
   - Secciones adicionales sobre caveats

3. **`Analisis_ADL_Completo.tex`** (código LaTeX)
4. **`Analisis_ADL_Transmision_Politica_Monetaria.tex`** (código LaTeX)

### 🗂️ Archivos de Datos R

- **`modelo_ADL.rds`** (45 KB)
  - Objeto modelo estimado del paquete `dynlm`
  - Puede recuperarse en R con: `modelo <- readRDS("modelo_ADL.rds")`

- **`subdata_ADL.rds`** (9.6 KB)
  - Datos limpios utilizados en la estimación
  - 229 observaciones mensuales, 2006-01 a 2025-01

## Hallazgos Clave

### 1. **Persistencia Inflacionaria Extraordinaria**
```
Coeficiente AR(1): λ = 0.9762
Interpretación: El 97.6% de la inflación de hoy es inercia del mes pasado
```

### 2. **Media y Mediana de Rezagos** ⭐ ENFOQUE PRINCIPAL
```
Mediana de rezagos = 28.72 meses
→ El 50% del efecto total de un shock se alcanza en 28.7 meses
→ Transmisión LENTA

Media de rezagos = 40.94 meses  
→ Duración promedio ponderada del efecto: 3.4 años
→ Inflación es extraordinariamente PEGAJOSA

Tiempo para 95% disipación = 124.13 meses
→ Efectos persisten por más de 10 años
```

### 3. **Efectividad de Política Monetaria**
```
Multiplicador LP de DTF: -0.151
→ Aumento permanente de 100 pb en tasa reduce inflación 15.1 pp en LP
→ Política monetaria ES efectiva, pero con efectos lentos
```

### 4. **Pass-through Cambiario**
```
Multiplicador LP de TRM: 0.284
→ Depreciación de 1% aumenta inflación 28.4 pb en LP
→ Pass-through moderado, canal importante de transmisión
```

### 5. **Proyección Febrero 2026**
```
Inflación Enero 2025: 5.0919%
Inflación Proyectada: 5.0785%
Cambio: -1.34 pb
Supuesto: Variables mantienen niveles de enero 2025
```

## Diagnósticos del Modelo

| Prueba | Resultado | Conclusión |
|--------|-----------|-----------|
| R² | 0.9892 | Excelente ajuste |
| R² Ajustado | 0.9889 | Muy buena bondad |
| Autocorrelación (BG) | p = 0.0000 | Presente (rechaza H₀) |
| Heterocedasticidad (BP) | p = 0.0156 | Presente (rechaza H₀) |
| Normalidad (Shapiro-Wilk) | p = 0.1093 | Cumplida (no rechaza) |

**Nota**: Presencia de autocorrelación y heterocedasticidad sugiere que aunque el modelo ajusta bien, los errores estándar pueden estar sesgados. Se recomienda usar errores estándar robustos para inferencia.

## Especificación del Modelo

```
Inf_t = α + λ·Inf_{t-1} 
        + β₀^{DTF}·DTF_t + β₁^{DTF}·DTF_{t-1}
        + β₀^{TRM}·ΔlogTRM_t + β₁^{TRM}·ΔlogTRM_{t-1}
        + β₀^{ISE}·ISE_t + β₁^{ISE}·ISE_{t-1}
        + ε_t

Período: 2006-01 a 2025-01 (229 observaciones)
Método: OLS vía dynlm
```

## Cómo Usar Estos Resultados

### Para Presentaciones
- Usar **Analisis_ADL_Completo.pdf** como documento principal
- Incrustar las 4 gráficas PDF en presentaciones
- Destacar los valores de **media y mediana de rezagos**

### Para Análisis Adicional en R
```r
# Cargar modelo y datos
modelo <- readRDS("modelo_ADL.rds")
datos <- readRDS("subdata_ADL.rds")

# Ver resumen
summary(modelo)

# Extraer predicciones
pred <- fitted(modelo)
residuos <- residuals(modelo)
```

### Para Futuras Investigaciones
- Estimación de modelos asimétricos (shocks positivos vs negativos)
- Análisis de quiebres estructurales (2020-2021 COVID)
- Incorporación de expectativas explícitas
- Modelos VAR alternativos para comparación

## Limitaciones Importantes

1. **Inflación es I(1)**: Variable dependiente no es estacionaria
   - Proyecciones de corto plazo (1-2 meses) son confiables
   - Proyecciones de largo plazo (>12 meses) requieren cuidado

2. **Autocorrelación presente**: Sugiere posible especificación incompleta
   - Posibles variables omitidas (expectativas, shocks de oferta)
   - Posibles no-linealidades no capturadas

3. **Heterocedasticidad**: Varianza de errores no es constante
   - Períodos de alta volatilidad (2008-2009, 2020-2021) tienen residuos más grandes

4. **Período muestral limitado**: 19 años de datos
   - Efectos de largo plazo estimados con cierta incertidumbre

## Recomendaciones de Política

1. **Horizonte de evaluación**: Adoptar 3-4 años como horizonte estándar para evaluar efectos de política
2. **Comunicación**: Explicar explícitamente que los efectos son lentos (mediana 28.7 meses)
3. **Monitoreo**: Con alta persistencia, monitores mensuales de indicadores adelantados son esenciales
4. **Pass-through**: Mayor atención al canal cambiario dado su potencia

## Referencias de Datos

- **IPC**: DANE (Índice de Precios al Consumidor, año base 2018=100)
- **DTF**: Banco de la República (Tasa de Depósitos a Término Fijo)
- **TRM**: Banco de la República (Tasa Representativa del Mercado)
- **ISE**: Banco de la República (Índice de Seguimiento a la Economía)

---

**Fecha de análisis**: Febrero 2026
**Script principal**: `/scripts/ADL.R`
**Última actualización**: 2026-02-16
