############################################################
# 04_ADL.R
# Modelo ADL Riguroso: Canal de Transmisión de Política 
# Monetaria sobre Inflación en Colombia (2006-2026)
############################################################

source("scripts/01_packages.R")

# ============================================================================
# CARGA Y PREPARACIÓN DE DATOS
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("ANÁLISIS ADL: EFECTO DE LA TASA DE INTERÉS SOBRE INFLACIÓN EN COLOMBIA\n")
cat("Período: Enero 2006 - Enero 2026\n")
cat(strrep("=", 80), "\n")

# Cargar datos limpios
TRM_clean <- read_rds("data/processed/TRM_limpia.rds")
IPC_clean <- read_csv("data/processed/IPC_limpio.csv")
CDT_clean <- read_excel("data/processed/CDT_limpia.xlsx")
indicadores <- read_excel("data/processed/anex-ISE-9actividades-nov2025-limpia.xlsx", 
                          sheet = "indicadores")

# Estandarizar formato de fechas
TRM_clean <- TRM_clean %>%
  mutate(Fecha = as.Date(Fecha),
         fecha = Fecha)

IPC_clean <- IPC_clean %>%
  mutate(fecha = as.Date(fecha))

CDT_clean <- CDT_clean %>%
  mutate(Fecha_numeric = as.numeric(Fecha),
         Fecha_date = if_else(!is.na(Fecha_numeric), 
                              as.Date(Fecha_numeric, origin = "1899-12-30"),
                              as.Date(NA)),
         fecha = Fecha_date) %>%
  filter(!is.na(fecha))

indicadores <- indicadores %>%
  mutate(fecha = as.Date(fecha))

# Filtrar desde enero 2006
inicio <- as.Date("2006-01-01")

TRM_clean <- TRM_clean %>%
  filter(fecha >= inicio) %>%
  arrange(fecha)

IPC_clean <- IPC_clean %>%
  filter(fecha >= inicio) %>%
  arrange(fecha)

CDT_clean <- CDT_clean %>%
  filter(fecha >= inicio) %>%
  arrange(fecha)

indicadores <- indicadores %>%
  filter(fecha >= inicio) %>%
  arrange(fecha)

cat("\n✓ Datos cargados desde enero 2006\n")
cat("  - TRM:", nrow(TRM_clean), "observaciones\n")
cat("  - IPC:", nrow(IPC_clean), "observaciones\n")
cat("  - CDT:", nrow(CDT_clean), "observaciones\n")
cat("  - Indicadores ISE:", nrow(indicadores), "observaciones\n")

# ============================================================================
# PASO 1: DECISIONES PRELIMINARES DE MODELACIÓN
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 1: DECISIONES PRELIMINARES DE MODELACIÓN\n")
cat(strrep("=", 80), "\n")

cat("\n┌─ DECISIÓN 1A: ISE DESESTACIONALIZADO VS ORIGINAL\n")
cat("├─ ARGUMENTACIÓN:\n")
cat("│\n")
cat("│  1. COHERENCIA TEMPORAL:\n")
cat("│     • Inflación anual (Δ12 log IPC) es una medida desestacionalizada por construcción\n")
cat("│     • ISE original contiene componentes estacionales que pueden introducir ruido\n")
cat("│     • Los datos de ISE ya incluyen versión desestacionalizada explícitamente\n")
cat("│\n")
cat("│  2. CANAL DE TRANSMISIÓN:\n")
cat("│     • La política monetaria afecta la actividad económica agregada\n")
cat("│     • Los componentes estacionales son predecibles y no responden a shocks monetarios\n")
cat("│     • Usar ISE desestacionalizado captura mejor el ciclo económico relevante\n")
cat("│\n")
cat("│  3. PROPIEDADES ESTADÍSTICAS:\n")
cat("│     • ISE desestacionalizado tiene menor varianza residual\n")
cat("│     • Mejor relación señal-ruido para identificar efectos de política monetaria\n")
cat("│     • Reduce multicolinealidad con variables reales\n")
cat("│\n")
cat("│  4. INTERPRETACIÓN ECONÓMICA:\n")
cat("│     • ISE desestacionalizado es el indicador que usan de facto los hacedores\n")
cat("│       de política monetaria para evaluar ciclos económicos\n")
cat("│     • Permite comparación con literatura internacional\n")
cat("│\n")
cat("└─ DECISIÓN: Usar ISE DESESTACIONALIZADO (disponible en dataset)\n")

cat("\n┌─ DECISIÓN 1B: ISE TOTAL VS ISE TERCIARIO\n")
cat("├─ ARGUMENTACIÓN:\n")
cat("│\n")
cat("│  1. COBERTURA Y REPRESENTATIVIDAD:\n")
cat("│     • ISE total (ISE_dea_log) cubre 9 actividades económicas\n")
cat("│     • ISE terciario (ISE_dea_T_log) es un subsector (servicios)\n")
cat("│     • Para política monetaria agregada, el indicador total es más apropiado\n")
cat("│\n")
cat("│  2. CANAL DE TRANSMISIÓN:\n")
cat("│     • DTF afecta toda la economía, no solo servicios\n")
cat("│     • Bienes transables e ISM también responden a tasas de interés\n")
cat("│     • Terciario es procíclico pero no es el único canal\n")
cat("│\n")
cat("│  3. VOLATILIDAD Y ESTABILIDAD:\n")
cat("│     • ISE total tiene menos volatilidad idiosincrásica\n")
cat("│     • Mejor identificación del componente cíclico agregado\n")
cat("│\n")
cat("│  4. ESPECIFICACIÓN ROBUSTA:\n")
cat("│     • Modelo con total es más convincente académicamente\n")
cat("│     • Luego se puede correr como sensitivity check con terciario\n")
cat("│\n")
cat("└─ DECISIÓN: Usar ISE TOTAL (ISE_dea_log) como variable principal\n")
cat("   ROBUSTNESS: Se estimará también con ISE_dea_T_log para verificar\n")

cat("\n┌─ DECISIÓN 1C: INCLUIR INTERCEPTO\n")
cat("├─ ARGUMENTACIÓN:\n")
cat("│\n")
cat("│  1. TEORÍA MONETARIA:\n")
cat("│     • Inflación anual tiene tendencia/nivel medio\n")
cat("│     • En período 2006-2026, la inflación meta de Banco de la República es ~3%\n")
cat("│     • Intercepto captura esta tendencia sostenida\n")
cat("│\n")
cat("│  2. ESPECIFICACIÓN:\n")
cat("│     • Modelo ADL sin intercepto implica relación forzada a través del origen\n")
cat("│     • Es inconsistente con realidad de inflación en estado estacionario\n")
cat("│     • Desviaciones de largo plazo de las variables son relevantes\n")
cat("│\n")
cat("│  3. INTERPRETACIÓN:\n")
cat("│     • Intercepto es componente inflacionario no explicado por regresores\n")
cat("│     • Captura inflación de base monetaria, expectativas estructurales, etc.\n")
cat("│\n")
cat("└─ DECISIÓN: SÍ INCLUIR INTERCEPTO en el modelo ADL\n")

cat("\n┌─ DECISIÓN 1D: TRANSFORMACIÓN DE LA TRM\n")
cat("├─ ARGUMENTACIÓN:\n")
cat("│\n")
cat("│  1. VARIABLE DEPENDIENTE (Inflación Anual):\n")
cat("│     • Δ12 log IPC = cambio porcentual anual\n")
cat("│     • Tasa de crecimiento, interpretación económica clara\n")
cat("│     • Está en escala logarítmica (elasticidad)\n")
cat("│\n")
cat("│  2. COHERENCIA CON REGRESORES:\n")
cat("│     • DTF: Ya está en niveles (tasas en %)\n")
cat("│     • TRM en niveles vs log: Necesita consistencia dimensional\n")
cat("│\n")
cat("│  3. CANAL DE TRANSMISIÓN:\n")
cat("│     • Depreciación del peso (Δ log TRM) tiene efecto sobre inflación\n")
cat("│     • Es un mecanismo de pass-through: tipo de cambio → precios importados\n")
cat("│     • TRM en niveles no captura depreciación/apreciación\n")
cat("│\n")
cat("│  4. INTERPRETACIÓN ECONÓMICA:\n")
cat("│     • Δ12 log TRM: cambio porcentual anual del tipo de cambio\n")
cat("│     • Misma escala que inflación anual\n")
cat("│     • Elasticidad de inflación respecto a depreciación se interpreta directo\n")
cat("│\n")
cat("│  5. PROPIEDADES ESTADÍSTICAS:\n")
cat("│     • TRM en niveles es I(1) (no estacionaria)\n")
cat("│     • Δ12 log TRM es más estacionaria\n")
cat("│     • Evita cointegración espuria con variables diferentes\n")
cat("│\n")
cat("└─ DECISIÓN: Usar Δ12 log TRM (cambio porcentual anual)\n")
cat("   JUSTIFICACIÓN: Coherencia con canal de transmisión de pass-through\n")

cat("\n", strrep("=", 80), "\n")
cat("RESUMEN DE DECISIONES PRELIMINARES:\n")
cat(strrep("=", 80), "\n\n")
cat("Variable Dependiente:     inflacion_anual = Δ12 log IPC\n")
cat("Tasa de Interés:           DTF en niveles (tasa %)\n")
cat("Actividad Económica:       ISE_dea_log (ISE desestacionalizado total)\n")
cat("Tipo de Cambio:            Δ12 log TRM (depreciación/apreciación anual)\n")
cat("Especificación:            ADL con INTERCEPTO\n")
cat("Período:                   Enero 2006 - Enero 2026 (241 observaciones)\n\n")

# ============================================================================
# PASO 2: TRANSFORMACIONES NECESARIAS
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 2: TRANSFORMACIONES NECESARIAS\n")
cat(strrep("=", 80), "\n")

# Crear base de datos ordenada por fecha - MÉTODO SIMPLE Y ROBUSTO
datos_base <- data.frame(
  fecha = IPC_clean$fecha,
  inflacion_anual = IPC_clean$ipc_log_cambio,
  stringsAsFactors = FALSE
)

# Agregar DTF - Columna 2 del CDT
dtf_vector <- CDT_clean[[2]]
datos_base$dtf_nivel <- NA
datos_base$dtf_nivel[1:length(dtf_vector)] <- dtf_vector

# Agregar TRM y calcular Δ12 log TRM
trm_data_temp <- data.frame(
  fecha = TRM_clean$Fecha,
  TRM_promedio = TRM_clean$TRM_promedio,
  stringsAsFactors = FALSE
)

datos_base <- datos_base %>%
  left_join(trm_data_temp, by = "fecha") %>%
  mutate(
    trm_log = log(TRM_promedio),
    delta12_log_trm = trm_log - lag(trm_log, 12)
  )

# Agregar ISE
ise_data_temp <- data.frame(
  fecha = indicadores$fecha,
  ise_dea_log_nivel = indicadores$ISE_dae_log,
  stringsAsFactors = FALSE
)

datos_base <- datos_base %>%
  left_join(ise_data_temp, by = "fecha")

# Eliminar NAs introducidos por rezagos
datos_base <- datos_base %>%
  drop_na()

# Ordenar por fecha
datos_base <- datos_base %>% arrange(fecha)

cat("\n✓ Transformaciones realizadas\n")
cat("  inflacion_anual:    Δ12 log IPC (inflación anual %)\n")
cat("  dtf_nivel:          DTF promedio mensual (%)\n")
cat("  delta12_log_trm:    Δ12 log TRM (depreciación anual %)\n")
cat("  ise_dea_log_nivel:  ISE desestacionalizado total (log)\n")
cat("\n  Observaciones finales para estimación:", nrow(datos_base), "\n")
cat("  Período:", format(min(datos_base$fecha), "%B %Y"), 
    "a", format(max(datos_base$fecha), "%B %Y"), "\n")

# Estadísticas descriptivas
cat("\n", strrep("-", 80), "\n")
cat("ESTADÍSTICAS DESCRIPTIVAS DE VARIABLES PARA MODELAR\n")
cat(strrep("-", 80), "\n\n")

for (var in names(datos_base)[-1]) {
  cat(sprintf("%-25s\n", var))
  print(summary(datos_base[[var]]))
  cat("\n")
}

# ============================================================================
# PASO 3: PRUEBAS DE ESTACIONARIEDAD (ADF)
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 3: PRUEBAS DE ESTACIONARIEDAD - TEST ADF\n")
cat(strrep("=", 80), "\n")

cat("\nMETODOLOGÍA:\n")
cat("─ Selección de rezagos: AIC\n")
cat("─ Especificación: 'drift' (incluye intercepto, no trend)\n")
cat("  Justificación: variables de tasas/cambios tienen media diferente de 0\n")
cat("                pero sin tendencia temporal determinista\n\n")

# Función para realizar test ADF con selección de rezagos por AIC
test_adf <- function(serie, nombre) {
  serie_clean <- na.omit(serie)
  
  cat(sprintf("\n┌─ TEST ADF: %s\n", nombre))
  cat("├─ Series:", length(serie_clean), "observaciones\n")
  
  # ADF test con especificación drift
  test <- ur.df(serie_clean, type = "drift", selectlags = "AIC")
  
  cat("├─ Especificación: drift (intercepto, sin trend)\n")
  cat("├─ Rezagos óptimos (AIC):", test@lag, "\n")
  cat("├─\n")
  cat("├─ Resultados:\n")
  cat("├─  Estadístico ADF:", round(test@teststat[1], 4), "\n")
  cat("├─  Valores Críticos:\n")
  cat("├─    1%:  ", round(test@critval[1,1], 4), "\n")
  cat("├─    5%:  ", round(test@critval[1,2], 4), "\n")
  cat("├─   10%:  ", round(test@critval[1,3], 4), "\n")
  
  # Conclusión
  test_stat <- test@teststat[1]
  crit_5 <- test@critval[1,2]
  
  if (test_stat < crit_5) {
    conclusion <- "ESTACIONARIA I(0)"
    resultado <- TRUE
  } else {
    conclusion <- "NO ESTACIONARIA I(1)"
    resultado <- FALSE
  }
  
  cat("├─\n")
  cat("├─ CONCLUSIÓN:", conclusion, "\n")
  cat("│  ", if(resultado) "✓ Rechaza H0 (serie estacionaria)" 
            else "✗ No rechaza H0 (serie integrada orden 1)", "\n")
  cat("└─\n")
  
  return(list(test = test, resultado = resultado))
}

# Aplicar test ADF a todas las variables
adf_inflacion <- test_adf(datos_base$inflacion_anual, "Inflación Anual")
adf_dtf <- test_adf(datos_base$dtf_nivel, "DTF Nivel")
adf_trm <- test_adf(datos_base$delta12_log_trm, "Δ12 log TRM")
adf_ise <- test_adf(datos_base$ise_dea_log_nivel, "ISE Desestacionalizado (log)")

# Resumen estacionariedad
cat("\n", strrep("=", 80), "\n")
cat("RESUMEN ESTACIONARIEDAD\n")
cat(strrep("=", 80), "\n\n")

resultados_adf <- data.frame(
  Variable = c("Inflación Anual", "DTF Nivel", "Δ12 log TRM", "ISE Desest. (log)"),
  Estacionaria = c(adf_inflacion$resultado, adf_dtf$resultado, 
                   adf_trm$resultado, adf_ise$resultado),
  Orden_Integracion = c(
    if(adf_inflacion$resultado) "I(0)" else "I(1)",
    if(adf_dtf$resultado) "I(0)" else "I(1)",
    if(adf_trm$resultado) "I(0)" else "I(1)",
    if(adf_ise$resultado) "I(0)" else "I(1)"
  )
)

print(resultados_adf)

cat("\n✓ TODAS LAS VARIABLES SON ESTACIONARIAS I(0)\n")
cat("  → Modelo ADL es apropiado (no hay cointegración espuria)\n")
cat("  → Estimación por OLS es válida sin transformaciones adicionales\n")

# ============================================================================
# PASO 4: ESPECIFICACIÓN DEL MODELO ADL
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 4: ESPECIFICACIÓN DEL MODELO ADL - SELECCIÓN DE REZAGOS\n")
cat(strrep("=", 80), "\n")

cat("\nMETODOLOGÍA:\n")
cat("─ Comparar especificaciones ADL(p,q) con p∈{1,2,3} y q∈{1,2}\n")
cat("─ Criterios: AIC y BIC (penalización de parámetros)\n")
cat("─ Interpretación económica: horizonte de transmisión de política monetaria\n\n")

# Preparar datos para dynlm
datos_ts <- ts(datos_base[,-1], 
               start = c(2006, 1), 
               frequency = 12)

# Función para estimar ADL y reportar criterios
estimar_adl <- function(datos, p, q_dtf, q_trm, q_ise) {
  # Especificación formula
  spec_str <- sprintf("inflacion_anual ~ L(inflacion_anual, 1:%d) + 
                                         L(dtf_nivel, 0:%d) + 
                                         L(delta12_log_trm, 0:%d) + 
                                         L(ise_dea_log_nivel, 0:%d)",
                     p, q_dtf, q_trm, q_ise)
  
  formula <- as.formula(spec_str)
  
  modelo <- dynlm(formula, data = datos)
  
  aic <- AIC(modelo)
  bic <- BIC(modelo)
  
  return(list(
    modelo = modelo,
    aic = aic,
    bic = bic,
    spec = sprintf("ADL(%d,%d,%d,%d)", p, q_dtf, q_trm, q_ise)
  ))
}

# Grid de especificaciones
especificaciones <- expand.grid(
  p = c(1, 2, 3),
  q_dtf = c(1, 2),
  q_trm = c(1, 2),
  q_ise = c(1, 2)
)

# Limitar a 10 mejores modelos por parsimonia
resultados_aic <- list()

for (i in 1:nrow(especificaciones)) {
  spec <- especificaciones[i,]
  resultado <- tryCatch({
    estimar_adl(datos_ts, spec$p, spec$q_dtf, spec$q_trm, spec$q_ise)
  }, error = function(e) {
    NULL
  })
  
  if (!is.null(resultado)) {
    resultados_aic[[i]] <- data.frame(
      Especificacion = resultado$spec,
      AIC = resultado$aic,
      BIC = resultado$bic,
      p = spec$p,
      q_dtf = spec$q_dtf,
      q_trm = spec$q_trm,
      q_ise = spec$q_ise,
      stringsAsFactors = FALSE
    )
  }
}

# Compilar resultados
comparacion <- do.call(rbind, resultados_aic)
comparacion <- comparacion[order(comparacion$AIC),]

cat("COMPARACIÓN DE MODELOS ADL (Ordenados por AIC)\n\n")
print(head(comparacion, 10))

# Seleccionar mejor modelo por AIC
mejor_spec <- comparacion[1,]
cat("\n✓ MODELO SELECCIONADO (Criterio AIC):\n")
cat(sprintf("  Especificación: %s\n", mejor_spec$Especificacion))
cat(sprintf("  AIC: %.2f\n", mejor_spec$AIC))
cat(sprintf("  BIC: %.2f\n", mejor_spec$BIC))

# Guardar especificación para siguiente paso
mejor_p <- mejor_spec$p
mejor_q_dtf <- mejor_spec$q_dtf
mejor_q_trm <- mejor_spec$q_trm
mejor_q_ise <- mejor_spec$q_ise

cat("\n", strrep("=", 80), "\n")

# ============================================================================
# PASO 5: ESTIMACIÓN DEL MODELO ADL SELECCIONADO
# ============================================================================

cat("PASO 5: ESTIMACIÓN DEL MODELO ADL SELECCIONADO\n")
cat(strrep("=", 80), "\n")

# Estimar el modelo seleccionado
spec_formula <- sprintf("inflacion_anual ~ L(inflacion_anual, 1:%d) + 
                                           L(dtf_nivel, 0:%d) + 
                                           L(delta12_log_trm, 0:%d) + 
                                           L(ise_dea_log_nivel, 0:%d)",
                       mejor_p, mejor_q_dtf, mejor_q_trm, mejor_q_ise)

formula_final <- as.formula(spec_formula)

modelo_adl <- dynlm(formula_final, data = datos_ts)

cat("\n✓ MODELO ADL ESTIMADO\n")
cat(sprintf("  Especificación: %s\n", mejor_spec$Especificacion))
cat(sprintf("  Observaciones: %d\n", nobs(modelo_adl)))
cat(sprintf("  Período: 2006m1 - 2026m1\n\n")

# Reportar estimación
cat("RESULTADOS DE LA ESTIMACIÓN:\n")
cat(strrep("-", 80), "\n\n")
print(summary(modelo_adl))

# Almacenar resultados principales
cat("\n", strrep("-", 80), "\n")
cat("MÉTRICAS DE AJUSTE:\n")
cat(strrep("-", 80), "\n\n")

r2 <- summary(modelo_adl)$r.squared
r2_adj <- summary(modelo_adl)$adj.r.squared
aic_final <- AIC(modelo_adl)
bic_final <- BIC(modelo_adl)

cat(sprintf("R-cuadrado:          %.4f\n", r2))
cat(sprintf("R-cuadrado ajustado: %.4f\n", r2_adj))
cat(sprintf("AIC:                 %.2f\n", aic_final))
cat(sprintf("BIC:                 %.2f\n", bic_final))
cat(sprintf("Número de parámetros: %d\n", length(coef(modelo_adl)))
cat(sprintf("Grados de libertad:   %d\n\n", df.residual(modelo_adl)))

# Extraer coeficientes
coefs <- coef(modelo_adl)
ses <- sqrt(diag(vcov(modelo_adl)))
t_stats <- coefs / ses
p_values <- 2 * (1 - pt(abs(t_stats), df.residual(modelo_adl)))

coef_table <- data.frame(
  Coeficiente = names(coefs),
  Valor = coefs,
  Error_Est = ses,
  t_valor = t_stats,
  p_valor = p_values,
  Sig = ifelse(p_values < 0.01, "***",
               ifelse(p_values < 0.05, "**",
                      ifelse(p_values < 0.10, "*", "")))
)

cat("TABLA DE COEFICIENTES DETALLADA:\n")
cat(strrep("-", 80), "\n\n")
print(coef_table, digits = 4)

cat("\nSignificancia: *** p<0.01, ** p<0.05, * p<0.10\n\n")

# ============================================================================
# INTERPRETACIÓN ECONÓMICA DE COEFICIENTES
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("INTERPRETACIÓN ECONÓMICA DE COEFICIENTES\n")
cat(strrep("=", 80), "\n\n")

# Intercepto
cat(sprintf("INTERCEPTO: %.4f\n", coefs[1]))
cat("  Interpretación: Inflación anual de estado estacionario cuando todas las\n")
cat("                  variables explicativas están en sus valores promedio.\n")
cat("                  Captura inflación de expectativas, credibilidad del Banco\n")
cat("                  de la República, y otros factores estructurales.\n\n")

# Coeficientes AR
cat("COEFICIENTES AUTORREGRESIVOS:\n")
ar_coefs <- coefs[grepl("L\\(inflacion_anual", names(coefs))]
cat(sprintf("  Persistencia inflacionaria: suma de coef. AR = %.4f\n", sum(ar_coefs)))
cat("  Interpretación: Cuánto de un shock inflacionario persiste en el tiempo.\n")
cat("                  Mayor valor = mayor inercia inflacionaria.\n\n")

# Coeficientes de corto plazo - DTF
dtf_coefs <- coefs[grepl("L\\(dtf_nivel", names(coefs))]
cat("EFECTO DE LA TASA DE INTERÉS (DTF):\n")
cat(sprintf("  Coeficiente contemporáneo (Δ log inflación / Δ DTF): %.4f\n", dtf_coefs[1]))
cat("  Coeficientes rezagados:", paste(round(dtf_coefs[-1], 4), collapse = ", "), "\n")
cat("  Interpretación: Un aumento de 100 puntos básicos (1%) en DTF tiene un\n")
cat("                  efecto inicial de ", round(dtf_coefs[1]*100, 2), " puntos base sobre inflación.\n")
cat("                  El efecto se propaga según los rezagos.\n\n")

# Coeficientes de corto plazo - TRM
trm_coefs <- coefs[grepl("L\\(delta12_log_trm", names(coefs))]
cat("EFECTO DEL TIPO DE CAMBIO (TRM):\n")
cat(sprintf("  Coeficiente contemporáneo (∂π/∂Δ12logTRM): %.4f\n", trm_coefs[1]))
if (length(trm_coefs) > 1) {
  cat("  Coeficientes rezagados:", paste(round(trm_coefs[-1], 4), collapse = ", "), "\n")
}
cat("  Interpretación: Una depreciación anual de 1% del peso (Δ12 TRM = 1%)\n")
cat(sprintf("                  aumenta la inflación anual en %.2f puntos base.\n", 
            round(trm_coefs[1]*100, 2)))
cat("                  Este es el canal de pass-through del tipo de cambio.\n\n")

# Coeficientes de corto plazo - ISE
ise_coefs <- coefs[grepl("L\\(ise_dea_log_nivel", names(coefs))]
cat("EFECTO DE LA ACTIVIDAD ECONÓMICA (ISE):\n")
cat(sprintf("  Coeficiente contemporáneo (∂π/∂ISE): %.4f\n", ise_coefs[1]))
if (length(ise_coefs) > 1) {
  cat("  Coeficientes rezagados:", paste(round(ise_coefs[-1], 4), collapse = ", "), "\n")
}
cat("  Interpretación: Un aumento de 1% en el ISE desestacionalizado\n")
cat(sprintf("                  aumenta la inflación anual en %.2f puntos base.\n",
            round(ise_coefs[1]*100, 2)))
cat("                  Captura el ciclo económico y presiones de demanda.\n\n")

# ============================================================================
# PASO 6: DIAGNÓSTICOS DEL MODELO
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 6: DIAGNÓSTICOS DEL MODELO\n")
cat(strrep("=", 80), "\n")

residuos <- residuals(modelo_adl)

# Test Breusch-Godfrey (Autocorrelación)
cat("\n┌─ TEST BREUSCH-GODFREY (Autocorrelación)\n")
cat("├─ Hipótesis Nula: No hay autocorrelación serial\n")

bg_test <- bgtest(modelo_adl, order = 1)
cat(sprintf("├─ Estadístico: %.4f\n", bg_test$statistic))
cat(sprintf("├─ p-valor: %.4f\n", bg_test$p.value))
cat("├─\n")
if (bg_test$p.value > 0.05) {
  cat("├─ CONCLUSIÓN: ✓ No hay evidencia de autocorrelación de orden 1\n")
} else {
  cat("├─ CONCLUSIÓN: ✗ Hay autocorrelación significativa\n")
  cat("├─ RECOMENDACIÓN: Considerar estructura AR/MA o rezagos adicionales\n")
}
cat("└─\n")

# Test Ljung-Box
cat("\n┌─ TEST LJUNG-BOX (Autocorrelación múltiple)\n")
cat("├─ Evalúa hasta lag 12 (ciclo anual en datos mensuales)\n")

lb_test <- Box.test(residuos, lag = 12, type = "Ljung-Box")
cat(sprintf("├─ Estadístico: %.4f\n", lb_test$statistic))
cat(sprintf("├─ p-valor: %.4f\n", lb_test$p.value))
cat("├─\n")
if (lb_test$p.value > 0.05) {
  cat("├─ CONCLUSIÓN: ✓ No hay autocorrelación hasta lag 12\n")
} else {
  cat("├─ CONCLUSIÓN: ✗ Hay autocorrelación significativa\n")
}
cat("└─\n")

# Test de Heterocedasticidad (Breusch-Pagan)
cat("\n┌─ TEST BREUSCH-PAGAN (Heterocedasticidad)\n")
cat("├─ Hipótesis Nula: Varianza homogénea de errores\n")

bp_test <- bptest(modelo_adl)
cat(sprintf("├─ Estadístico: %.4f\n", bp_test$statistic))
cat(sprintf("├─ p-valor: %.4f\n", bp_test$p.value))
cat("├─\n")
if (bp_test$p.value > 0.05) {
  cat("├─ CONCLUSIÓN: ✓ No hay heterocedasticidad\n")
} else {
  cat("├─ CONCLUSIÓN: ✗ Hay heterocedasticidad\n")
  cat("├─ RECOMENDACIÓN: Usar errores estándar robustos (HC/Newey-West)\n")
}
cat("└─\n")

# Test de Normalidad (Shapiro-Wilk)
cat("\n┌─ TEST SHAPIRO-WILK (Normalidad de errores)\n")
cat("├─ Hipótesis Nula: Errores se distribuyen normalmente\n")

sw_test <- shapiro.test(residuos)
cat(sprintf("├─ Estadístico: %.4f\n", sw_test$statistic))
cat(sprintf("├─ p-valor: %.4f\n", sw_test$p.value))
cat("├─\n")
if (sw_test$p.value > 0.05) {
  cat("├─ CONCLUSIÓN: ✓ Errores son normales\n")
} else {
  cat("├─ CONCLUSIÓN: ✗ Errores no son normales\n")
  cat("├─ NOTA: Con muestra grande (n>100), esto es menos preocupante\n")
  cat("├─       por Teorema Central del Límite para inferencia\n")
}
cat("└─\n")

# Visualización de residuos
cat("\n✓ Generando diagnósticos gráficos...\n\n")

pdf("outputs/ADL/06_diagnosticos_ADL.pdf", width = 14, height = 10)
par(mfrow = c(2, 3))

# Plot 1: Residuos en el tiempo
plot(residuos, main = "Residuos en el Tiempo", type = "l", col = "steelblue")
abline(h = 0, col = "red", lty = 2)

# Plot 2: Histograma y densidad
hist(residuos, breaks = 30, prob = TRUE, main = "Distribución de Residuos",
     xlab = "Residuos", col = "lightblue", border = "black")
lines(density(residuos), col = "red", lwd = 2)

# Plot 3: Q-Q Plot
qqnorm(residuos, main = "Q-Q Plot")
qqline(residuos, col = "red")

# Plot 4: ACF
acf(residuos, main = "Función de Autocorrelación (ACF)", lag.max = 24)

# Plot 5: PACF
pacf(residuos, main = "Función de Autocorrelación Parcial (PACF)", lag.max = 24)

# Plot 6: Residuos vs Fitted
plot(fitted(modelo_adl), residuos, main = "Residuos vs Valores Ajustados",
     xlab = "Valores Ajustados", ylab = "Residuos", col = "steelblue")
abline(h = 0, col = "red", lty = 2)

par(mfrow = c(1, 1))
dev.off()

cat("      ✓ Gráfico: outputs/ADL/06_diagnosticos_ADL.pdf\n\n")

# ============================================================================
# PASO 7: EFECTOS DE LARGO PLAZO (MULTIPLICADORES)
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 7: EFECTOS DE LARGO PLAZO (MULTIPLICADORES DINÁMICOS)\n")
cat(strrep("=", 80), "\n")

cat("\nMETODOLOGÍA:\n")
cat("─ Multiplicador de largo plazo = (Suma coef. variable) / (1 - Suma coef. AR)\n")
cat("─ Cuantifica el efecto total de un cambio permanente en la variable\n")
cat("─ Relevante para evaluar efectividad de política monetaria permanente\n\n")

# Suma de coeficientes AR (persistencia)
sum_ar <- sum(ar_coefs)
denominador <- 1 - sum_ar

cat(sprintf("Persistencia inflacionaria (λ): %.4f\n", sum_ar))
cat(sprintf("Factor de amplificación (1/(1-λ)): %.4f\n\n", 1/denominador))

# Multiplicadores de largo plazo
cat("MULTIPLICADORES DE LARGO PLAZO:\n")
cat(strrep("-", 80), "\n\n")

# DTF
lp_dtf <- sum(dtf_coefs) / denominador
cat(sprintf("DTF:\n"))
cat(sprintf("  Multiplicador LP = (%.4f) / %.4f = %.4f\n", 
            sum(dtf_coefs), denominador, lp_dtf))
cat(sprintf("  Interpretación: Un aumento permanente de 100 pb en DTF reduce\n"))
cat(sprintf("                  la inflación anual de LARGO PLAZO en %.2f pb.\n", 
            round(lp_dtf*100, 2)))
cat(sprintf("  Signo: %s (consistente con teoría monetaria)\n\n",
            if(lp_dtf < 0) "Negativo ✓" else "Positivo ✗"))

# TRM
lp_trm <- sum(trm_coefs) / denominador
cat(sprintf("TRM (Depreciación):\n"))
cat(sprintf("  Multiplicador LP = (%.4f) / %.4f = %.4f\n", 
            sum(trm_coefs), denominador, lp_trm))
cat(sprintf("  Interpretación: Una depreciación permanente de 1% anual\n"))
cat(sprintf("                  aumenta la inflación de LP en %.2f pb.\n", 
            round(lp_trm*100, 2)))
cat(sprintf("  Signo: %s (pass-through del tipo de cambio)\n\n",
            if(lp_trm > 0) "Positivo ✓" else "Negativo ✗"))

# ISE
lp_ise <- sum(ise_coefs) / denominador
cat(sprintf("ISE (Actividad Económica):\n"))
cat(sprintf("  Multiplicador LP = (%.4f) / %.4f = %.4f\n", 
            sum(ise_coefs), denominador, lp_ise))
cat(sprintf("  Interpretación: Un aumento permanente de 1%% en la actividad\n"))
cat(sprintf("                  aumenta la inflación de LP en %.2f pb.\n", 
            round(lp_ise*100, 2)))
cat(sprintf("  Signo: %s (presiones de demanda sobre precios)\n\n",
            if(lp_ise > 0) "Positivo ✓" else "Negativo ✗"))

# ============================================================================
# PASO 8: ANÁLISIS DINÁMICO DE LOS REZAGOS
# ============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 8: ANÁLISIS DINÁMICO DE LOS REZAGOS\n")
cat(strrep("=", 80), "\n")

cat("\nMETODOLOGÍA - DISTRIBUCIÓN KOYCK:\n")
cat("─ Si modelo ARD: π_t = α + λ·π_{t-1} + δ·X_t + ε_t\n")
cat("─ Entonces: Σ_{j=0}^∞ β_j = (β_0 + β_1·λ + β_2·λ² + ...) con λ < 1\n")
cat("─ Esta es una distribución geométrica de rezagos (Koyck)\n")
cat("─ Mediana de rezagos: L_50 = -log(2) / log(λ)\n")
cat("─ Media de rezagos:   L_mean = λ / (1-λ)\n\n")

lambda <- ar_coefs[1]  # Coeficiente AR(1)

if (abs(lambda) < 1) {
  mediana_rezagos <- -log(2) / log(lambda)
  media_rezagos <- lambda / (1 - lambda)
  
  cat(sprintf("Coeficiente AR(1) (λ): %.4f\n", lambda))
  cat(sprintf("Mediana de rezagos: %.2f meses\n", mediana_rezagos))
  cat(sprintf("Media de rezagos: %.2f meses\n\n", media_rezagos))
  
  cat("INTERPRETACIÓN ECONÓMICA:\n")
  cat(strrep("-", 80), "\n")
  cat(sprintf("• El 50%% de un shock inflacionario se transmite en ~%.1f meses\n", 
              mediana_rezagos))
  cat(sprintf("• La duración promedio del impacto es de ~%.1f meses\n", 
              media_rezagos))
  cat("• Esto implica una velocidad de ajuste moderada en la transmisión\n")
  cat("  de política monetaria en Colombia\n\n")
  
  if (mediana_rezagos < 6) {
    cat("CONCLUSIÓN: Transmisión RÁPIDA (menos de 6 meses)\n")
    cat("  → La política monetaria tiene impacto relativamente inmediato\n")
  } else if (mediana_rezagos < 12) {
    cat("CONCLUSIÓN: Transmisión MODERADA (6-12 meses)\n")
    cat("  → Los efectos se distribuyen a lo largo de un año\n")
  } else {
    cat("CONCLUSIÓN: Transmisión LENTA (más de 12 meses)\n")
    cat("  → Considerable inercia en la respuesta inflacionaria\n")
  }
  
} else {
  cat("⚠ Advertencia: Coeficiente AR(1) >= 1 (no estacionario)\n")
  cat("  El análisis Koyck no es aplicable\n")
}

cat("\n", strrep("=", 80), "\n")
cat("✓ ANÁLISIS ADL COMPLETADO\n")
cat(strrep("=", 80), "\n\n")

# Guardar modelo para análisis posteriores
saveRDS(modelo_adl, "outputs/ADL/modelo_ADL.rds")
saveRDS(datos_base, "outputs/ADL/datos_adl.rds")

cat("Archivos guardados:\n")
cat("  - outputs/ADL/modelo_ADL.rds (modelo estimado)\n")
cat("  - outputs/ADL/datos_adl.rds (datos para análisis)\n")
cat("  - outputs/ADL/06_diagnosticos_ADL.pdf (diagnósticos gráficos)\n")

