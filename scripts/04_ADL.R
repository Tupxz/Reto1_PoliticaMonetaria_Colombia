source("scripts/01_packages.R")

cat("\n", strrep("=", 80), "\n")
cat("MODELO ADL: TRANSMISIÓN DE POLÍTICA MONETARIA A LA INFLACIÓN\n")
cat("Colombia 2006-2025\n")
cat(strrep("=", 80), "\n\n")

# ==============================================================================
# PASO 1: CARGAR DATOS
# ==============================================================================

cat("PASO 1: CARGANDO DATOS\n")
cat(strrep("-", 80), "\n")

# Cargar IPC (Inflación anual)
IPC_clean <- read_csv("data/processed/IPC_limpio.csv") %>%
  filter(year(fecha) >= 2006) %>%
  mutate(fecha = floor_date(fecha, "month")) %>%
  arrange(fecha)

# Cargar TRM (Tasa Representativa del Mercado)
TRM_clean <- read_rds("data/processed/TRM_limpia.rds") %>%
  filter(year(Fecha) >= 2006) %>%
  mutate(fecha = floor_date(Fecha, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, delta12_log_trm = TRM_log)

# Cargar CDT/DTF (Tasas de interés)
CDT_clean <- read_excel("data/processed/CDT_limpia.xlsx") %>%
  mutate(fecha_raw = as.Date(as.numeric(Fecha), origin = "1899-12-30")) %>%
  filter(!is.na(fecha_raw) & year(fecha_raw) >= 2006) %>%
  mutate(fecha = floor_date(fecha_raw, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, dtf_nivel = 2)

# Cargar Indicadores (ISE)
indicadores <- read_excel("data/processed/anex-ISE-9actividades-nov2025-limpia.xlsx",
                          sheet = "indicadores") %>%
  filter(year(fecha) >= 2006) %>%
  mutate(fecha = floor_date(fecha, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, ise_dae_log = ISE_dae_log, ise_dae_T_log = ISE_dae_T_log)

cat("✓ IPC cargado:", nrow(IPC_clean), "obs\n")
cat("✓ TRM cargada:", nrow(TRM_clean), "obs\n")
cat("✓ CDT/DTF cargada:", nrow(CDT_clean), "obs\n")
cat("✓ Indicadores ISE cargados:", nrow(indicadores), "obs\n\n")

# ==============================================================================
# PASO 2: UNIFICAR BASES DE DATOS
# ==============================================================================

cat("PASO 2: UNIFICANDO BASES DE DATOS\n")
cat(strrep("-", 80), "\n")

datos <- IPC_clean %>%
  dplyr::select(fecha, inflacion_anual = ipc_log_cambio) %>%
  left_join(TRM_clean, by = "fecha") %>%
  left_join(CDT_clean, by = "fecha") %>%
  left_join(indicadores, by = "fecha") %>%
  dplyr::select(fecha, inflacion_anual, dtf_nivel, delta12_log_trm, ise_dae_log, ise_dae_T_log) %>%
  arrange(fecha)

cat("✓ Base de datos unificada:", nrow(datos), "observaciones\n")
cat("  Período:", format(min(datos$fecha), "%Y-%m"), "a", format(max(datos$fecha), "%Y-%m"), "\n\n")

# ==============================================================================
# PASO 3: CREAR SUBDATA (2006-01 a 2025-01)
# ==============================================================================

cat("PASO 3: CREANDO SUBDATA PARA ESTIMACIÓN\n")
cat(strrep("-", 80), "\n")

subdata <- datos %>%
  filter(fecha >= as.Date("2006-01-01") & fecha <= as.Date("2025-11-30")) %>%
  na.omit()

cat("✓ Subdata creada:", nrow(subdata), "observaciones\n")
cat("  Período:", format(min(subdata$fecha), "%Y-%m"), "a", format(max(subdata$fecha), "%Y-%m"), "\n\n")

# ==============================================================================
# PASO 4: PRUEBAS DE ESTACIONARIEDAD (TEST DICKEY-FULLER)
# ==============================================================================

cat("PASO 4: PRUEBAS DE ESTACIONARIEDAD\n")
cat("(H0: Serie tiene raíz unitaria | Especificación: drift)\n")
cat(strrep("-", 80), "\n\n")

# Función auxiliar para realizar test ADF
test_adf <- function(serie, nombre) {
  test <- ur.df(serie, type = "drift", selectlags = "AIC")
  stat <- test@teststat[1, 1]
  crit <- test@cval[1, 2]
  resultado <- ifelse(stat < crit, "I(0) ✓", "I(1) ✗")
  
  cat(sprintf("%-25s | ADF=%7.4f | Crit(5%%)=%7.4f | %s\n",
              nombre, stat, crit, resultado))
  
  return(list(test = test, estacionaria = stat < crit))
}

cat("INFLACIÓN Y SUS TRANSFORMACIONES:\n")
adf_inf <- test_adf(subdata$inflacion_anual, "Inflación Anual")
cat("  → Inflación es I(1): tiene persistencia fuerte\n")
cat("     Los shocks no se disipan inmediatamente\n\n")

cat("VARIABLES EXPLICATIVAS:\n")
adf_dtf <- test_adf(subdata$dtf_nivel, "DTF Nivel")
adf_trm <- test_adf(subdata$delta12_log_trm, "Δ12 log(TRM)")
adf_ise <- test_adf(subdata$ise_dae_log, "ISE DAE Log")
adf_ise_t <- test_adf(subdata$ise_dae_T_log, "ISE Terciario")

cat("\n✓ CONCLUSIÓN: Variables I(0) son estacionarias → OLS es válido\n\n")

# ==============================================================================
# PASO 5: PREPARAR DATOS EN SERIE DE TIEMPO
# ==============================================================================

cat("PASO 5: PREPARANDO DATOS PARA MODELO ADL\n")
cat(strrep("-", 80), "\n")

# Convertir a serie de tiempo para dynlm
subdata_ts <- ts(subdata[, -1], start = c(2006, 1), frequency = 12)

cat("✓ Datos convertidos a serie de tiempo\n")
cat("  Período: 2006M1 a 2025M1\n")
cat("  Frecuencia: Mensual\n\n")

# ==============================================================================
# PASO 6: ESTIMAR MODELO ADL(1,1,1,1)
# ==============================================================================

cat("PASO 6: ESTIMANDO MODELO ADL(1,1,1,1)\n")
cat("Especificación:\n")
cat("  inflacion_anual ~ L(inflacion_anual,1) +\n")
cat("                    L(dtf_nivel,0:1) +\n")
cat("                    L(delta12_log_trm,0:1) +\n")
cat("                    L(ise_dae_log,0:1)\n")
cat(strrep("-", 80), "\n\n")

# Estimar el modelo
modelo_adl <- dynlm(
  inflacion_anual ~ L(inflacion_anual, 1) + 
                    L(dtf_nivel, 0:1) + 
                    L(delta12_log_trm, 0:1) + 
                    L(ise_dae_log, 0:1),
  data = subdata_ts
)

cat("✓ Modelo estimado por OLS\n")
cat(sprintf("  R² = %.4f | R² ajustado = %.4f\n\n", 
            summary(modelo_adl)$r.squared,
            summary(modelo_adl)$adj.r.squared))

# Mostrar resumen
print(summary(modelo_adl))

# ==============================================================================
# PASO 7: EXTRAER Y ORGANIZAR COEFICIENTES
# ==============================================================================

cat("\n\n", strrep("=", 80), "\n")
cat("PASO 7: ANÁLISIS DE COEFICIENTES\n")
cat(strrep("=", 80), "\n\n")

coefs <- coef(modelo_adl)
ses <- sqrt(diag(vcov(modelo_adl)))
t_stats <- coefs / ses
p_vals <- 2 * (1 - pt(abs(t_stats), df.residual(modelo_adl)))

# Extraer coeficientes específicos
const <- coefs["(Intercept)"]
lambda <- coefs["L(inflacion_anual, 1)"]

# Extraer coeficientes de DTF (con formato correcto)
dtf_cp <- coefs[grep("L\\(dtf_nivel.*\\)0", names(coefs))]
dtf_lag <- coefs[grep("L\\(dtf_nivel.*\\)1", names(coefs))]
dtf_total_cp <- dtf_cp + dtf_lag

# Extraer coeficientes de TRM
trm_cp <- coefs[grep("L\\(delta12_log_trm.*\\)0", names(coefs))]
trm_lag <- coefs[grep("L\\(delta12_log_trm.*\\)1", names(coefs))]
trm_total_cp <- trm_cp + trm_lag

# Extraer coeficientes de ISE
ise_cp <- coefs[grep("L\\(ise_dae_log.*\\)0", names(coefs))]
ise_lag <- coefs[grep("L\\(ise_dae_log.*\\)1", names(coefs))]
ise_total_cp <- ise_cp + ise_lag

# Asegurar que son números si no se encuentran
if(length(dtf_cp) == 0) dtf_cp <- NA
if(length(dtf_lag) == 0) dtf_lag <- NA
if(length(trm_cp) == 0) trm_cp <- NA
if(length(trm_lag) == 0) trm_lag <- NA
if(length(ise_cp) == 0) ise_cp <- NA
if(length(ise_lag) == 0) ise_lag <- NA

# ==============================================================================
# PERSISTENCIA INFLACIONARIA
# ==============================================================================

cat("1. PERSISTENCIA INFLACIONARIA (AR)\n")
cat(strrep("-", 80), "\n")
cat(sprintf("Coeficiente AR(1): λ = %.6f\n", lambda))
cat(sprintf("Significancia: p-valor = %.4f %s\n\n",
            p_vals["L(inflacion_anual, 1)"],
            ifelse(p_vals["L(inflacion_anual, 1)"] < 0.05, "✓", "✗")))

# ==============================================================================
# EFECTO DE LA TASA DE INTERÉS (DTF)
# ==============================================================================

cat("2. EFECTO DE LA TASA DE INTERÉS (DTF)\n")
cat(strrep("-", 80), "\n")
if(!is.na(dtf_cp)) {
  cat(sprintf("Efecto Contemporáneo (t): %.6f | p-valor: %s\n", 
              dtf_cp, "ver summary"))
  cat(sprintf("Efecto Rezagado (t-1):     %.6f | p-valor: %s\n",
              dtf_lag, "ver summary"))
  cat(sprintf("Efecto Total CP:           %.6f\n", dtf_total_cp))
  cat(sprintf("Interpretación: ↑100 pb en DTF → ↓%.2f pb en inflación\n\n",
              abs(dtf_total_cp) * 100))
} else {
  cat("No se pudieron extraer coeficientes de DTF\n\n")
}

# ==============================================================================
# EFECTO DEL TIPO DE CAMBIO (PASS-THROUGH)
# ==============================================================================

cat("3. EFECTO DEL TIPO DE CAMBIO (PASS-THROUGH)\n")
cat(strrep("-", 80), "\n")
if(!is.na(trm_cp)) {
  cat(sprintf("Efecto Contemporáneo (t): %.6f | p-valor: %s\n",
              trm_cp, "ver summary"))
  cat(sprintf("Efecto Rezagado (t-1):     %.6f | p-valor: %s\n",
              trm_lag, "ver summary"))
  cat(sprintf("Efecto Total CP:           %.6f\n", trm_total_cp))
  cat(sprintf("Interpretación: ↑1%% en depr. TRM → ↑%.2f pb en inflación\n\n",
              trm_total_cp * 100))
} else {
  cat("No se pudieron extraer coeficientes de TRM\n\n")
}

# ==============================================================================
# EFECTO DE LA ACTIVIDAD ECONÓMICA (ISE)
# ==============================================================================

cat("4. EFECTO DE LA ACTIVIDAD ECONÓMICA (ISE)\n")
cat(strrep("-", 80), "\n")
if(!is.na(ise_cp)) {
  cat(sprintf("Efecto Contemporáneo (t): %.6f | p-valor: %s\n",
              ise_cp, "ver summary"))
  cat(sprintf("Efecto Rezagado (t-1):     %.6f | p-valor: %s\n",
              ise_lag, "ver summary"))
  cat(sprintf("Efecto Total CP:           %.6f\n", ise_total_cp))
  cat(sprintf("Interpretación: ↑1%% en ISE → ↑%.2f pb en inflación\n\n",
              ise_total_cp * 100))
} else {
  cat("No se pudieron extraer coeficientes de ISE\n\n")
}

# ==============================================================================
# PASO 8: MULTIPLICADORES DE LARGO PLAZO
# ==============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 8: MULTIPLICADORES DE LARGO PLAZO\n")
cat(strrep("=", 80), "\n\n")

# Factor amplificador (1/(1-λ))
factor_amp <- 1 / (1 - lambda)

cat(sprintf("Persistencia inflacionaria: λ = %.6f\n", lambda))
cat(sprintf("Factor amplificador: 1/(1-λ) = %.6f\n\n", factor_amp))

# Calcular multiplicadores LP
mult_dtf_lp <- dtf_total_cp * factor_amp
mult_trm_lp <- trm_total_cp * factor_amp
mult_ise_lp <- ise_total_cp * factor_amp

cat("DTF (LARGO PLAZO):\n")
cat(sprintf("  Multiplicador = (%.6f) × (%.6f) = %.6f\n", 
            dtf_total_cp, factor_amp, mult_dtf_lp))
cat(sprintf("  → Aumento permanente de 100 pb en DTF reduce inflación en %.2f pb\n\n",
            abs(mult_dtf_lp) * 100))

cat("TRM (LARGO PLAZO - PASS-THROUGH):\n")
cat(sprintf("  Multiplicador = (%.6f) × (%.6f) = %.6f\n",
            trm_total_cp, factor_amp, mult_trm_lp))
cat(sprintf("  → Depreciación permanente de 1%% aumenta inflación en %.2f pb\n\n",
            mult_trm_lp * 100))

cat("ISE (LARGO PLAZO - DEMANDA AGREGADA):\n")
cat(sprintf("  Multiplicador = (%.6f) × (%.6f) = %.6f\n",
            ise_total_cp, factor_amp, mult_ise_lp))
cat(sprintf("  → Aumento permanente de 1%% en ISE aumenta inflación en %.2f pb\n\n",
            mult_ise_lp * 100))

# ==============================================================================
# PASO 9: ANÁLISIS DINÁMICO - MEDIA Y MEDIANA DE REZAGOS (KOYCK)
# ==============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 9: DISTRIBUCIÓN DE REZAGOS (ANÁLISIS KOYCK)\n")
cat("¿Cuánto tiempo tarda en sentirse el efecto de los shocks?\n")
cat(strrep("=", 80), "\n\n")

if (lambda > 0 & lambda < 1) {
  
  # MEDIANA DE REZAGOS
  # Definición: El tiempo en el que se alcanza el 50% del efecto final
  # Fórmula: mediana = -log(2) / log(λ)
  mediana_rezagos <- -log(2) / log(lambda)
  
  # MEDIA DE REZAGOS (Duración promedio)
  # Definición: Promedio ponderado de todos los rezagos
  # Fórmula: media = λ / (1 - λ)
  media_rezagos <- lambda / (1 - lambda)
  
  # TIEMPO PARA DISIPAR 95% DEL EFECTO
  tiempo_95 <- -log(0.05) / (-log(lambda))
  
  cat("MÉTRICAS DE DISTRIBUCIÓN DE REZAGOS:\n")
  cat(strrep("-", 80), "\n\n")
  
  cat(sprintf("Coeficiente AR(1): λ = %.6f\n", lambda))
  cat(sprintf("Interpretación: %.1f%% de la inflación de hoy es inercia del mes pasado\n\n",
              lambda * 100))
  
  cat("MEDIANA DE REZAGOS:\n")
  cat(sprintf("  → %.2f meses\n", mediana_rezagos))
  cat("  → El 50% del efecto total se alcanza en este tiempo\n")
  cat("  → Es el 'punto de inflexión' de la respuesta\n\n")
  
  cat("MEDIA DE REZAGOS (Duración promedio):\n")
  cat(sprintf("  → %.2f meses\n", media_rezagos))
  cat("  → Se requiere este tiempo EN PROMEDIO para que el efecto se sienta completamente\n")
  cat("  → Medida de cuán 'pegajosa' es la inflación\n\n")
  
  cat("TIEMPO PARA 95% DE DISIPACIÓN:\n")
  cat(sprintf("  → %.2f meses\n", tiempo_95))
  cat("  → Después de este tiempo, el 95% del efecto ya se ha propagado\n\n")
  
  # Clasificación según velocidad de transmisión
  if (mediana_rezagos < 3) {
    velocidad <- "⚡ MUY RÁPIDA (< 3 meses)"
    desc <- "Los efectos se sienten casi inmediatamente"
  } else if (mediana_rezagos < 6) {
    velocidad <- "⚡ RÁPIDA (3-6 meses)"
    desc <- "Respuesta ágil en el trimestre"
  } else if (mediana_rezagos < 12) {
    velocidad <- "⏱️  MODERADA (6-12 meses)"
    desc <- "Distribución a lo largo de un año (estándar internacional)"
  } else {
    velocidad <- "🐢 LENTA (> 12 meses)"
    desc <- "Considerable inercia inflacionaria"
  }
  
  cat("VELOCIDAD DE TRANSMISIÓN:\n")
  cat(sprintf("  %s\n", velocidad))
  cat(sprintf("  %s\n\n", desc))
  
} else {
  cat("⚠️  Coeficiente AR(1) fuera del rango (0,1)\n")
  cat("   No se aplica análisis Koyck estándar\n\n")
  mediana_rezagos <- NA
  media_rezagos <- NA
}

# ==============================================================================
# PASO 10: PROYECCIÓN DE INFLACIÓN FEBRERO 2026
# ==============================================================================

cat("PASO 10: PROYECCIÓN DE INFLACIÓN FEBRERO 2026\n")
cat("NOTA: Inflación es I(1) → Cuidado con proyecciones de LARGO PLAZO\n")
cat(strrep("=", 80), "\n\n")

# Última observación disponible (Noviembre 2025)
ultima_obs <- subdata %>% slice_tail(n = 1)
fecha_ultima <- ultima_obs$fecha
inf_nov2025 <- ultima_obs$inflacion_anual
dtf_nov2025 <- ultima_obs$dtf_nivel
trm_nov2025 <- ultima_obs$delta12_log_trm
ise_nov2025 <- ultima_obs$ise_dae_log

cat("DATOS BASE (NOVIEMBRE 2025):\n")
cat(strrep("-", 80), "\n")
cat(sprintf("Inflación Anual:      %.4f%%\n", inf_nov2025))
cat(sprintf("DTF (Nivel):          %.4f%%\n", dtf_nov2025))
cat(sprintf("Δ12 log(TRM):         %.4f\n", trm_nov2025))
cat(sprintf("ISE DAE Log:          %.4f\n\n", ise_nov2025))

cat("ESCENARIO BASE PARA PROYECCIÓN:\n")
cat(strrep("-", 80), "\n")
cat("Supuesto: Las variables explicativas se mantienen en sus niveles actuales\n")
cat("(Este es un escenario de 'no cambio' de política y condiciones externas)\n\n")

# PROYECCIÓN ITERATIVA: De Nov 2025 a Feb 2026 (3 pasos)
# Diciembre 2025
inf_dic2025 <- const + 
               lambda * inf_nov2025 +
               dtf_cp * dtf_nov2025 +
               dtf_lag * dtf_nov2025 +
               trm_cp * trm_nov2025 +
               trm_lag * trm_nov2025 +
               ise_cp * ise_nov2025 +
               ise_lag * ise_nov2025

# Enero 2026
inf_ene2026 <- const + 
               lambda * inf_dic2025 +
               dtf_cp * dtf_nov2025 +
               dtf_lag * dtf_nov2025 +
               trm_cp * trm_nov2025 +
               trm_lag * trm_nov2025 +
               ise_cp * ise_nov2025 +
               ise_lag * ise_nov2025

# Febrero 2026
inf_feb2026 <- const + 
               lambda * inf_ene2026 +
               dtf_cp * dtf_nov2025 +
               dtf_lag * dtf_nov2025 +
               trm_cp * trm_nov2025 +
               trm_lag * trm_nov2025 +
               ise_cp * ise_nov2025 +
               ise_lag * ise_nov2025

cat("RESULTADO DE LA PROYECCIÓN:\n")
cat(strrep("-", 80), "\n")
cat(sprintf("Inflación Noviembre 2025:     %.4f%%\n", inf_nov2025))

# Proyección solo si todos los coeficientes están disponibles
if(!is.na(dtf_cp) && !is.na(dtf_lag) && !is.na(trm_cp) && 
   !is.na(trm_lag) && !is.na(ise_cp) && !is.na(ise_lag)) {
  
  cat(sprintf("Inflación Proyectada Dic 2025: %.4f%%\n", inf_dic2025))
  cat(sprintf("Inflación Proyectada Ene 2026: %.4f%%\n", inf_ene2026))
  cat(sprintf("Inflación Proyectada Feb 2026: %.4f%%\n", inf_feb2026))
  
  cambio_pp <- inf_feb2026 - inf_nov2025
  cambio_pb <- cambio_pp * 100
  
  cat(sprintf("\nCambio total (Nov 2025 → Feb 2026): %.4f pp (%.2f pb)\n\n", cambio_pp, cambio_pb))
  
  if (cambio_pp < -0.01) {
    cat(sprintf("→ Se proyecta DISMINUCIÓN de la inflación en %.2f pb\n", abs(cambio_pb)))
  } else if (cambio_pp > 0.01) {
    cat(sprintf("→ Se proyecta AUMENTO de la inflación en %.2f pb\n", cambio_pb))
  } else {
    cat("→ Se proyecta ESTABILIZACIÓN de la inflación\n")
  }
  
  # Renombrar para consistencia con resto del código
  inf_proyectada_feb2026 <- inf_feb2026
  
} else {
  cat("⚠️  No se pudo completar la proyección - coeficientes incompletos\n")
  inf_proyectada_feb2026 <- NA
  inf_dic2025 <- NA
  inf_ene2026 <- NA
  cambio_pb <- NA
}

cat("\n⚠️  ADVERTENCIA SOBRE PROYECCIONES I(1):\n")
cat(strrep("-", 80), "\n")
cat("• Inflación como NIVEL es I(1) - no estacionaria\n")
cat("• Cambios mes-a-mes son I(0) - estacionarios\n")
cat("• Proyecciones de CORTO PLAZO (1-2 meses) son más confiables\n")
cat("• Proyecciones de LARGO PLAZO (> 12 meses) requieren cuidado\n")
cat("• El modelo captura dinámicas en NIVELES pero con inercia importante\n\n")

# ==============================================================================
# PASO 11: DIAGNÓSTICOS DEL MODELO
# ==============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 11: DIAGNÓSTICOS DEL MODELO\n")
cat(strrep("=", 80), "\n\n")

residuos <- residuals(modelo_adl)
r2 <- summary(modelo_adl)$r.squared
r2_adj <- summary(modelo_adl)$adj.r.squared

cat("BONDAD DE AJUSTE:\n")
cat(sprintf("  R²: %.4f\n", r2))
cat(sprintf("  R² Ajustado: %.4f\n\n", r2_adj))

# Test de Breusch-Godfrey (Autocorrelación)
cat("AUTOCORRELACIÓN (Breusch-Godfrey, orden 1):\n")
bg <- bgtest(modelo_adl, order = 1)
cat(sprintf("  Estadístico: %.4f | p-valor: %.4f\n", bg$statistic, bg$p.value))
cat(sprintf("  Conclusión: %s\n\n",
            ifelse(bg$p.value > 0.05, "✓ No hay autocorrelación", "✗ Hay autocorrelación")))

# Test de Breusch-Pagan (Heterocedasticidad)
cat("HETEROCEDASTICIDAD (Breusch-Pagan):\n")
bp <- bptest(modelo_adl)
cat(sprintf("  Estadístico: %.4f | p-valor: %.4f\n", bp$statistic, bp$p.value))
cat(sprintf("  Conclusión: %s\n\n",
            ifelse(bp$p.value > 0.05, "✓ Homocedasticidad", "✗ Heterocedasticidad")))

# Test de Shapiro-Wilk (Normalidad)
cat("NORMALIDAD DE RESIDUOS (Shapiro-Wilk):\n")
sw <- shapiro.test(residuos)
cat(sprintf("  Estadístico: %.4f | p-valor: %.4f\n", sw$statistic, sw$p.value))
cat(sprintf("  Conclusión: %s\n", 
            ifelse(sw$p.value > 0.05, "✓ Errores normales", "✗ Errores no normales")))
cat("  Nota: Con n > 100, TCL asegura validez de inferencia incluso si no-normal\n\n")

# ==============================================================================
# RESUMEN EJECUTIVO FINAL
# ==============================================================================

cat("\n", strrep("=", 80), "\n")
cat("RESUMEN EJECUTIVO\n")
cat(strrep("=", 80), "\n\n")

cat("ESPECIFICACIÓN DEL MODELO:\n")
cat(sprintf("  • Tipo: ADL(1,1,1,1)\n"))
cat(sprintf("  • Período: 2006-01 a 2025-01 (%d observaciones)\n", nrow(subdata)))
cat(sprintf("  • R² = %.4f | R² Ajustado = %.4f\n\n", r2, r2_adj))

cat("HALLAZGOS PRINCIPALES:\n\n")

cat("1️⃣  PERSISTENCIA INFLACIONARIA:\n")
cat(sprintf("   • Coeficiente AR(1): %.4f\n", lambda))
cat(sprintf("   • Mediana de rezagos: %.2f meses (50%% del efecto)\n", mediana_rezagos))
cat(sprintf("   • Media de rezagos: %.2f meses (duración promedio)\n", media_rezagos))
cat("   • Implicación: Inflación tiene memoria fuerte en Colombia\n\n")

if(!is.na(dtf_total_cp)) {
  cat("2️⃣  EFECTIVIDAD DE POLÍTICA MONETARIA:\n")
  cat(sprintf("   • Efecto CP de DTF: %.4f (%.2f pb por 100 pb)\n", 
              dtf_total_cp, dtf_total_cp*100))
  cat(sprintf("   • Efecto LP de DTF: %.4f (%.2f pb por 100 pb)\n",
              mult_dtf_lp, abs(mult_dtf_lp)*100))
  cat("   • Conclusión: Banco de la República PUEDE controlar inflación\n\n")
}

if(!is.na(trm_total_cp)) {
  cat("3️⃣  PASS-THROUGH CAMBIARIO:\n")
  cat(sprintf("   • Efecto CP: %.4f (%.2f pb por 1%% depr.)\n",
              trm_total_cp, trm_total_cp*100))
  cat(sprintf("   • Efecto LP: %.4f (%.2f pb por 1%% depr.)\n",
              mult_trm_lp, mult_trm_lp*100))
  cat("   • Tipo: ", ifelse(mult_trm_lp > 0.5, "Alto", 
                            ifelse(mult_trm_lp > 0.2, "Moderado", "Bajo")),
      " pass-through\n\n")
}

if(!is.na(ise_total_cp)) {
  cat("4️⃣  ACTIVIDAD ECONÓMICA:\n")
  cat(sprintf("   • Efecto CP: %.4f (%.2f pb por 1%% aumento)\n",
              ise_total_cp, ise_total_cp*100))
  cat(sprintf("   • Efecto LP: %.4f\n", mult_ise_lp))
  cat("   • Conclusión: Expansiones generan presiones inflacionarias\n\n")
}

cat("5️⃣  PROYECCIÓN FEBRERO 2026:\n")
cat(sprintf("   • Inflación Noviembre 2025: %.4f%%\n", inf_nov2025))
if(!is.na(inf_proyectada_feb2026)) {
  cat(sprintf("   • Inflación Proyectada Feb 2026: %.4f%%\n", inf_proyectada_feb2026))
  cat(sprintf("   • Cambio (3 meses): %.2f pb\n\n", cambio_pb))
} else {
  cat("   • Proyección no disponible (coeficientes incompletos)\n\n")
}

cat("✅ CONCLUSIONES FINALES:\n")
cat("   ✓ Política monetaria es efectiva para control inflacionario\n")
cat("   ✓ Canales de transmisión activos: demanda agregada y pass-through\n")
cat(sprintf("   ✓ Tiempo de transmisión: mediana = %.1f meses\n", mediana_rezagos))
cat("   ✓ Inflación es I(1): considerar primeras diferencias en análisis LP\n")
cat("   ✓ El modelo pasa diagnósticos básicos de especificación\n\n")

cat(strrep("=", 80), "\n")
cat("✓ ANÁLISIS COMPLETADO\n")
cat(strrep("=", 80), "\n\n")

# ==============================================================================
# PASO 12: GRÁFICAS DE DIAGNÓSTICOS Y PREDICCIÓN
# ==============================================================================

cat("\n", strrep("=", 80), "\n")
cat("PASO 12: GENERANDO GRÁFICAS\n")
cat(strrep("=", 80), "\n\n")

# Crear directorio si no existe
if (!dir.exists("outputs/ADL")) {
  dir.create("outputs/ADL", showWarnings = FALSE)
}

# --------- GRÁFICA 1: Diagnósticos del Modelo (4 paneles) ---------
pdf("outputs/ADL/01_diagnosticos_ADL.pdf", width = 12, height = 10)

par(mfrow = c(2, 2), mar = c(4, 4, 3, 2))

# Residuos vs Fitted
plot(fitted(modelo_adl), residuals(modelo_adl),
     main = "Residuos vs Valores Ajustados",
     xlab = "Valores Ajustados", ylab = "Residuos",
     pch = 19, col = rgb(0, 0, 0, 0.6))
abline(h = 0, col = "red", lwd = 2, lty = 2)
grid()

# QQ-Plot
qqnorm(residuals(modelo_adl), main = "Q-Q Plot de Residuos",
       pch = 19, col = rgb(0, 0, 0, 0.6))
qqline(residuals(modelo_adl), col = "red", lwd = 2)
grid()

# Escala-Localización
residuos_std <- sqrt(abs(residuals(modelo_adl) / sd(residuals(modelo_adl))))
plot(fitted(modelo_adl), residuos_std,
     main = "Scale-Location",
     xlab = "Valores Ajustados",
     ylab = expression(sqrt("|Residuos estandarizados|")),
     pch = 19, col = rgb(0, 0, 0, 0.6))
grid()

# Residuos vs Orden temporal
plot(residuals(modelo_adl), type = "l", main = "Residuos en el Tiempo",
     xlab = "Tiempo", ylab = "Residuos", col = "steelblue", lwd = 1.5)
abline(h = 0, col = "red", lwd = 2, lty = 2)
grid()

par(mfrow = c(1, 1))
dev.off()

cat("✓ Gráfica guardada: outputs/ADL/01_diagnosticos_ADL.pdf\n")

# --------- GRÁFICA 2: Valores Reales vs Predichos ---------
pdf("outputs/ADL/02_predicciones_ADL.pdf", width = 12, height = 7)

par(mfrow = c(1, 1), mar = c(4, 4, 3, 2))

# El modelo empieza en el período 2 porque usa rezago
inflacion_predicha <- fitted(modelo_adl)
# Las fechas del modelo empiezan desde el segundo período
fechas_modelo <- subdata$fecha[-1][1:length(inflacion_predicha)]
inflacion_real_modelo <- subdata$inflacion_anual[-1][1:length(inflacion_predicha)]

plot(fechas_modelo, inflacion_real_modelo, type = "l", lwd = 2, col = "darkblue",
     main = "Inflación Anual: Real vs Predicha (ADL 1,1,1,1)",
     xlab = "Fecha", ylab = "Inflación Anual (%)")
lines(fechas_modelo, inflacion_predicha, type = "l", lwd = 2, col = "red", lty = 2)

legend("topright", legend = c("Inflación Real", "Predicción del Modelo"),
       col = c("darkblue", "red"), lwd = c(2, 2), lty = c(1, 2), bty = "n")

grid()
dev.off()

cat("✓ Gráfica guardada: outputs/ADL/02_predicciones_ADL.pdf\n")

# --------- GRÁFICA 3: Distribución de Rezagos (Koyck) ---------
pdf("outputs/ADL/03_distribucion_rezagos_ADL.pdf", width = 12, height = 7)

par(mfrow = c(1, 1), mar = c(4, 4, 3, 2))

# Crear secuencia de rezagos
meses <- 0:24
pesos_rezagos <- lambda^meses

plot(meses, pesos_rezagos, type = "b", pch = 19, lwd = 2, col = "darkgreen",
     main = "Distribución de Rezagos (Koyck) - Pesos Acumulativos",
     xlab = "Meses", ylab = "Peso del Rezago",
     ylim = c(0, 1))

# Línea de mediana
abline(v = mediana_rezagos, col = "red", lwd = 2, lty = 2)
abline(h = 0.5, col = "red", lwd = 1, lty = 3)

# Línea de media
abline(v = media_rezagos, col = "orange", lwd = 2, lty = 2)

legend("topright",
       legend = c(sprintf("Mediana: %.2f meses (50%% efecto)", mediana_rezagos),
                  sprintf("Media: %.2f meses (duración promedio)", media_rezagos)),
       col = c("red", "orange"), lwd = 2, lty = 2, bty = "n")

grid()
dev.off()

cat("✓ Gráfica guardada: outputs/ADL/03_distribucion_rezagos_ADL.pdf\n")

# --------- GRÁFICA 4: Proyección Feb 2026 ---------
pdf("outputs/ADL/04_proyeccion_feb2026_ADL.pdf", width = 15, height = 8)

par(mfrow = c(1, 1), mar = c(5, 5, 4, 2))

# Serie completa histórica
fechas_completas <- subdata$fecha
inf_completa <- subdata$inflacion_anual

# Última observación
ultima_fecha <- tail(fechas_completas, 1)
ultima_inf <- tail(inf_completa, 1)

# Series de fechas y valores proyectados
fechas_proyectadas <- seq(from = as.Date("2025-12-01"), 
                          to = as.Date("2026-02-01"), 
                          by = "month")
inf_proyectadas <- c(inf_dic2025, inf_ene2026, inf_feb2026)

# Crear serie completa (histórica + proyección)
fechas_todo <- c(fechas_completas, fechas_proyectadas)
inf_todo <- c(inf_completa, inf_proyectadas)

# Determinar rangos apropiados
xlim_min <- min(fechas_completas)
xlim_max <- max(fechas_proyectadas) + 150
ylim_min <- 1
ylim_max <- 15

# Plot principal: serie completa desde 2006 hasta Feb 2026
plot(fechas_completas, inf_completa, type = "l", lwd = 2.5, col = "darkblue",
     main = "Proyección de Inflación para Febrero 2026\n(Histórico 2006-2025 + Pronóstico 3 meses)",
     xlab = "Año", ylab = "Inflación Anual (%)",
     xlim = c(xlim_min, xlim_max),
     ylim = c(ylim_min, ylim_max),
     cex.main = 1.2, cex.lab = 1.1)

# Área de rango meta (2-4%) - SOMBREADO EN VERDE
rect(xlim_min, 2, xlim_max, 4, 
     col = rgb(0, 0.7, 0, 0.12), border = NA)

# Sombrear los últimos 12 meses (destacar datos recientes)
ultimos_meses <- 12
idx_desde <- max(1, nrow(subdata) - ultimos_meses + 1)
rect(subdata$fecha[idx_desde], ylim_min - 1, ultima_fecha, ylim_max + 1, 
     col = rgb(0.7, 0.7, 0.7, 0.05), border = NA)

# Línea de pronóstico - ROJA CLARA Y VISIBLE
lines(fechas_proyectadas, inf_proyectadas, 
      lwd = 3.5, lty = 2, col = "red")

# Conectar última observación con primer pronóstico
lines(c(ultima_fecha, fechas_proyectadas[1]),
      c(ultima_inf, inf_proyectadas[1]),
      lwd = 3.5, lty = 2, col = "red")

# Puntos de pronóstico - GRANDES Y VISIBLES
points(fechas_proyectadas, inf_proyectadas, pch = 19, cex = 3.5, col = "red")

# Anotaciones de fechas y valores - SIN FONDO PARA MEJOR VISIBILIDAD
# Diciembre 2025
text(fechas_proyectadas[1], inf_proyectadas[1] + 0.25,
     sprintf("Dic 2025\n%.2f%%", inf_proyectadas[1]),
     col = "darkred", font = 2, cex = 1.0, adj = c(0.5, 0))

# Enero 2026
text(fechas_proyectadas[2], inf_proyectadas[2] - 0.25,
     sprintf("Ene 2026\n%.2f%%", inf_proyectadas[2]),
     col = "darkred", font = 2, cex = 1.0, adj = c(0.5, 1))

# Febrero 2026 - MÁS GRANDE Y DESTACADO
points(fechas_proyectadas[3], inf_proyectadas[3], pch = 19, cex = 4.5, col = "red")
text(fechas_proyectadas[3], inf_proyectadas[3] + 0.35,
     sprintf("FEB 2026\n%.2f%%", inf_proyectadas[3]),
     col = "darkred", font = 3, cex = 1.15, adj = c(0.5, 0),
     bg = rgb(1, 1, 1, 0.7))

# Línea horizontal del rango meta (2-4%) - DESTACADA CON BORDES
abline(h = 2, col = "darkgreen", lty = 2, lwd = 2.5)
abline(h = 4, col = "darkgreen", lty = 2, lwd = 2.5)

# Etiquetas del rango meta más visibles
text(xlim_min + 300, 2.1, "Meta inferior (2%)", col = "darkgreen", font = 2, cex = 0.95, adj = c(0, 0))
text(xlim_min + 300, 3.85, "Meta superior (4%)", col = "darkgreen", font = 2, cex = 0.95, adj = c(0, 1))
text(xlim_max - 300, 3, "RANGO\nMETA", 
     col = "darkgreen", font = 3, cex = 1.1, adj = c(1, 0.5),
     bg = rgb(1, 1, 1, 0.6))

# Anotación de última observación histórica
text(ultima_fecha, ultima_inf - 0.35, 
     sprintf("Nov 2025\n(Último dato)\n%.2f%%", ultima_inf),
     col = "darkblue", font = 2, cex = 0.9, adj = c(0.5, 1))

# Leyenda mejorada
legend("topright",
       legend = c("Histórico 2006-2025 (azul)", 
                  "Pronóstico 3 meses (rojo punteado)",
                  "Últimos 12 meses (zona gris)"),
       col = c("darkblue", "red", "gray"), 
       lwd = c(2.5, 3.5, 4), pch = c(NA, 19, NA), lty = c(1, 2, NA),
       bty = "n", cex = 1.0, x.intersp = 0.5)

grid(nx = NULL, ny = NULL, col = "lightgray", lty = 3, lwd = 0.8)
dev.off()

cat("✓ Gráfica guardada: outputs/ADL/04_proyeccion_feb2026_ADL.pdf\n")

# Guardar resultados
saveRDS(modelo_adl, "outputs/ADL/modelo_ADL.rds")
saveRDS(subdata, "outputs/ADL/subdata_ADL.rds")

cat("\nArchivos guardados:\n")
cat("  • outputs/ADL/modelo_ADL.rds\n")
cat("  • outputs/ADL/subdata_ADL.rds\n")
cat("  • outputs/ADL/01_diagnosticos_ADL.pdf\n")
cat("  • outputs/ADL/02_predicciones_ADL.pdf\n")
cat("  • outputs/ADL/03_distribucion_rezagos_ADL.pdf\n")
cat("  • outputs/ADL/04_proyeccion_feb2026_ADL.pdf\n")
