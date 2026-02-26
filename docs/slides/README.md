# Presentación VARX: Transmisión Monetaria en Colombia

## Resumen Ejecutivo

**Archivo:** `slides.tex` (580 líneas)
**PDF compilado:** `slides.pdf` (14 páginas, 131 KB)
**Duración estimada:** 10 minutos

---

## Estructura: 14 Diapositivas (Limpia y Organizada)

### 1. **Portada** 
   - Título, autores, fecha

### 2. **Motivación**
   - Gráfico: Series macroeconómicas (1 figura)
   - Contexto: Inflación 13.1% → 4.1%

### 3. **Pregunta de Investigación**
   - ¿Cómo se transmite la política monetaria?
   - 4 objetivos claros

### 4. **Contribución**
   - ¿Por qué VARX vs univariados?
   - Desempeño predictivo (+47% a +66%)

### 5. **Literatura**
   - 4 canales económicos (Sims, Galí, Stock-Watson)
   - Contexto Colombia

### 6. **Datos**
   - Tabla: Variables endógenas y exógenas
   - Período: 240 obs. mensuales (2006-2025)

### 7. **Diagnósticos**
   - Gráfico: Raíces en círculo unitario (1 figura)
   - p=2 rezagos, estabilidad

### 8. **Especificación VARX(2)**
   - Ecuación forma reducida
   - Métodos: OLS, bootstrap

### 9. **Impulso-Respuesta (IRF)**
   - Gráfico: Bootstrap 95% (1 figura)
   - Picos: TRM 8-12m, ISE 8-11m, DTF 5-7m

### 10. **Descomposición de Varianza (FEVD)**
   - Tabla: 5 columnas × 4 filas
   - Hallazgo: TRM+ISE = 64% a 24m

### 11. **Validación Predictiva**
   - Tabla: Expanding window RMSE
   - Ganancia VARX vs ARIMA por horizonte

### 12. **Pronóstico 2026**
   - Gráfico: Forecast con bandas e inflación target (1 figura)
   - Desinflación gradual 4.1% → 3.3%

### 13. **Hallazgos Principales**
   - 5 puntos clave en numeración

### 14. **Conclusiones**
   - Implicaciones para BanRep
   - Limitaciones y extensiones

---

## Características del Diseño

✅ **Minimalista:** Solo lo esencial, sin redundancias
✅ **Visual:** 3 figuras + 3 tablas de datos empíricos
✅ **Legible:** Fuentes apropiadas, márgenes controlados
✅ **Académico:** Tema Beamer Madrid, colores profesionales
✅ **Rápido:** 14 slides = ~1 minuto/slide = 10 min total

---

## Figuras Automáticamente Incluidas

1. `../VAR/01_series_macroeconomicas_VAR.pdf` — Series mensuales
2. `../VAR/05_raices_varx_circulo_unitario.pdf` — Estabilidad
3. `../VAR/08_irf_bootstrap_inflacion.pdf` — Impulso-respuesta
4. `../VAR/09_forecast_inflacion_varx_banda_meta.pdf` — Pronóstico 2026

---

## Tablas de Datos Embebidas

### Tabla 1: Variables (Slide 6)
| Variable | Transformación | Fuente |
|----------|---|---|
| Inflación | Δ₁₂ log(IPC) | DANE |
| TRM | Δ₁₂ log(TRM) | BanRep |
| ISE | Δ₁₂ log(ISE) | DANE |
| DTF | Nivel (pp) | BanRep |
| Inflación US | Δ₁₂ log(CPI-US) | FRED |
| Brent | Δ₁₂ log(Brent) | FRED |

### Tabla 2: FEVD (Slide 10)
Horizonte × 4 variables = descomposición de varianza a 1m, 3m, 6m, 12m, 24m

### Tabla 3: Validación RMSE (Slide 11)
VARX vs ARIMA vs Naive en h=1m, 3m, 6m, 12m

---

## Alineación con Rúbrica (10 Elementos)

1. ✅ **Presentación** (Slide 2)
2. ✅ **Estructura** (Slides 1-14)
3. ✅ **Motivación** (Slide 2)
4. ✅ **Contribución** (Slide 4)
5. ✅ **Literatura** (Slide 5)
6. ✅ **Datos** (Slide 6)
7. ✅ **Estadísticas** (Slide 7)
8. ✅ **Modelo** (Slide 8)
9. ✅ **Resultados** (Slides 9-11)
10. ✅ **Conclusiones** (Slide 14)

---

## Cambios Radicales Realizados

| Aspecto | Antes | Después |
|---------|-------|---------|
| Líneas de código | 321 | 580 (mejor estructura) |
| Páginas PDF | 15 | 14 |
| Duplicación de contenido | Alta | Nula |
| Párrafos largos | Sí | No (solo bullets) |
| Figuras | 4 | 4 (optimizadas) |
| Tablas | 3 | 3 (claras y concisas) |
| Tiempo presentación | 12+ min | 10 min ✓ |

---

## Compilación Verificada

```bash
$ pdflatex -interaction=nonstopmode slides.tex
Output written on slides.pdf (14 pages, 133703 bytes).
```

✅ **Exitosa sin errores críticos**

---

## Próximos Pasos (Si es necesario)

- Ajustes de contenido específico por slide
- Cambios de énfasis en hallazgos
- Reordenamiento de secciones
- Inclusión de figuras adicionales

---

**Última actualización:** 26 de febrero de 2026
**Estado:** Listo para presentación
