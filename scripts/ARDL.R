source("scripts/01_packages.R")

cat("\n", strrep("=", 80), "\n")
cat("MODELO ARDL(2,2,2,4): TRANSMISIÓN DE POLÍTICA MONETARIA A LA INFLACIÓN\n")
cat("Colombia 2006-2025 | Enfoque de Cointegración\n")
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
# PASO 3: CREAR SUBDATA (2006-01 a 2025-11)
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

# Realizar tests
test_inf <- test_adf(subdata$inflacion_anual, "Inflación")
test_dtf <- test_adf(subdata$dtf_nivel, "DTF")
test_trm <- test_adf(subdata$delta12_log_trm, "TRM (log)")
test_ise <- test_adf(subdata$ise_dae_log, "ISE")

cat("\n⚠️  NOTA: Variables I(1) → Posible cointegración\n")
cat("     ARDL es el método apropiado para este caso\n\n")

# ==============================================================================
# PASO 5: ESTIMACIÓN DEL MODELO ARDL(2,2,2,4)
# ==============================================================================

cat(strrep("=", 80), "\n")
cat("PASO 5: ESTIMACIÓN DEL MODELO ARDL(2,2,2,4)\n")
cat("Especificación: inflación_t = f(inflación_{t-1,t-2},\n")
cat("                                 dtf_t, dtf_{t-1,t-2},\n")
cat("                                 trm_t, trm_{t-1,t-2},\n")
cat("                                 ise_{t}, ise_{t-1,t-2,t-3,t-4})\n")
cat(strrep("=", 80), "\n\n")

# Crear objeto de series de tiempo
datos_ts <- ts(subdata %>% dplyr::select(inflacion_anual, dtf_nivel, delta12_log_trm, ise_dae_log),
               start = c(2006, 1), frequency = 12)

# Estimar modelo ARDL(2,2,2,4) usando dynlm
modelo_ardl <- dynlm(inflacion_anual ~ 
                      L(inflacion_anual, 1:2) +
                      dtf_nivel + L(dtf_nivel, 1:2) +
                      delta12_log_trm + L(delta12_log_trm, 1:2) +
                      L(ise_dae_log, 0:4),
                    data = datos_ts)

cat("✓ Modelo ARDL(2,2,2,4) estimado\n")
cat("  Observaciones utilizadas:", nrow(model.frame(modelo_ardl)), "\n\n")

# ==============================================================================
# PASO 6: RESULTADOS DE LA ESTIMACIÓN
# ==============================================================================

cat("PASO 6: RESULTADOS DE LA ESTIMACIÓN\n")
cat(strrep("=", 80), "\n\n")

# Resumen del modelo
print(summary(modelo_ardl))

# Extraer coeficientes y estadísticas clave
coef_ardl <- coef(modelo_ardl)
se_ardl <- sqrt(diag(vcov(modelo_ardl)))
t_stat <- coef_ardl / se_ardl
p_valores <- 2 * (1 - pt(abs(t_stat), df = modelo_ardl$df.residual))

# R² y estadísticas generales
R2 <- summary(modelo_ardl)$r.squared
R2_adj <- summary(modelo_ardl)$adj.r.squared
AIC_ardl <- AIC(modelo_ardl)
BIC_ardl <- BIC(modelo_ardl)

cat("\n\nESTADÍSTICAS DEL MODELO:\n")
cat(strrep("-", 80), "\n")
cat(sprintf("R²:                    %8.4f\n", R2))
cat(sprintf("R² Ajustado:           %8.4f\n", R2_adj))
cat(sprintf("AIC:                   %8.4f\n", AIC_ardl))
cat(sprintf("BIC:                   %8.4f\n", BIC_ardl))
cat(sprintf("Suma de residuos²:     %8.4f\n", sum(residuals(modelo_ardl)^2)))
cat("\n")

# ==============================================================================
# PASO 7: MULTIPLICADORES DE LARGO PLAZO (COINTEGRACIÓN)
# ==============================================================================

cat("PASO 7: ANÁLISIS DE COINTEGRACIÓN Y MULTIPLICADORES\n")
cat(strrep("=", 80), "\n\n")

# Extraer coeficientes para cálculo
lambda_1 <- coef_ardl[2]  # L(inflacion_anual, 1)
lambda_2 <- coef_ardl[3]  # L(inflacion_anual, 2)

# Coeficientes de DTF
beta_dtf_0 <- coef_ardl[4]
beta_dtf_1 <- coef_ardl[5]
beta_dtf_2 <- coef_ardl[6]

# Coeficientes de TRM
beta_trm_0 <- coef_ardl[7]
beta_trm_1 <- coef_ardl[8]
beta_trm_2 <- coef_ardl[9]

# Coeficientes de ISE (4 rezagos)
beta_ise_0 <- coef_ardl[10]
beta_ise_1 <- coef_ardl[11]
beta_ise_2 <- coef_ardl[12]
beta_ise_3 <- coef_ardl[13]
beta_ise_4 <- coef_ardl[14]

# Denominador: (1 - λ₁ - λ₂)
denominador <- 1 - lambda_1 - lambda_2

cat("PARÁMETROS AUTOREGRESIVOS:\n")
cat(sprintf("  λ₁ (L1 inflación):      %8.6f (sig: %s)\n", lambda_1, 
            ifelse(p_valores[2] < 0.05, "***", " ")))
cat(sprintf("  λ₂ (L2 inflación):      %8.6f (sig: %s)\n", lambda_2, 
            ifelse(p_valores[3] < 0.05, "***", " ")))
cat(sprintf("  Denominador (1-λ₁-λ₂): %8.6f\n\n", denominador))

# Cálculo de multiplicadores de largo plazo
if (abs(denominador) > 0.01) {
  # DTF
  numerador_dtf <- beta_dtf_0 + beta_dtf_1 + beta_dtf_2
  mult_lp_dtf <- numerador_dtf / denominador
  
  # TRM
  numerador_trm <- beta_trm_0 + beta_trm_1 + beta_trm_2
  mult_lp_trm <- numerador_trm / denominador
  
  # ISE
  numerador_ise <- beta_ise_0 + beta_ise_1 + beta_ise_2 + beta_ise_3 + beta_ise_4
  mult_lp_ise <- numerador_ise / denominador
  
  cat("MULTIPLICADORES DE LARGO PLAZO:\n")
  cat(strrep("-", 80), "\n\n")
  cat(sprintf("DTF:  %.4f\n", mult_lp_dtf))
  cat(sprintf("  → Aumento de 100pb en DTF afecta inflación en %.2f pb (LP)\n\n", mult_lp_dtf * 100))
  
  cat(sprintf("TRM:  %.4f\n", mult_lp_trm))
  cat(sprintf("  → Aumento de 1%% en TRM afecta inflación en %.2f pp (LP)\n\n", mult_lp_trm))
  
  cat(sprintf("ISE:  %.4f\n", mult_lp_ise))
  cat(sprintf("  → Aumento de 1%% en ISE afecta inflación en %.2f pp (LP)\n\n", mult_lp_ise))
  
} else {
  cat("⚠️  Denominador muy cercano a 0: Posible raíz unitaria en el modelo\n\n")
}

# ==============================================================================
# PASO 8: TEST DE COINTEGRACIÓN (TEST DE LÍMITES - BOUNDS TEST)
# ==============================================================================

cat("PASO 8: TEST DE LÍMITES (BOUNDS TEST PARA COINTEGRACIÓN)\n")
cat(strrep("=", 80), "\n\n")

# El test de límites requiere estimar mediante una relación de error correctivo
# Aquí realizamos un test F simplificado

# Modelo restricto: Solo primeras diferencias
modelo_restricto <- dynlm(d(inflacion_anual) ~ 
                          d(L(inflacion_anual, 1)) +
                          d(dtf_nivel) + d(L(dtf_nivel, 1)) +
                          d(delta12_log_trm) + d(L(delta12_log_trm, 1)) +
                          d(L(ise_dae_log, 0:3)),
                        data = datos_ts)

# Test F
ssr_r <- sum(residuals(modelo_restricto)^2)
ssr_u <- sum(residuals(modelo_ardl)^2)
n <- nrow(model.frame(modelo_ardl))
k <- ncol(model.matrix(modelo_ardl))

F_stat <- ((ssr_r - ssr_u) / k) / (ssr_u / (n - k - 1))
p_value_f <- 1 - pf(F_stat, k, n - k - 1)

cat("TEST F PARA COINTEGRACIÓN (Modelo ARDL vs. Diferencias):\n")
cat(sprintf("  F-estadístico: %.4f\n", F_stat))
cat(sprintf("  p-valor:       %.4f\n", p_value_f))
if (p_value_f < 0.05) {
  cat("  Resultado: EVIDENCIA DE COINTEGRACIÓN ✓\n")
} else {
  cat("  Resultado: NO hay evidencia de cointegración\n")
}
cat("\n")

# ==============================================================================
# PASO 9: MECANISMO DE CORRECCIÓN DE ERROR (ECM)
# ==============================================================================

cat("PASO 9: MECANISMO DE CORRECCIÓN DE ERROR\n")
cat(strrep("=", 80), "\n\n")

# Relación de largo plazo (si hay cointegración)
if (p_value_f < 0.05) {
  # ECT = residuos rezagados un período
  residuos_ardl <- residuals(modelo_ardl)
  ect <- c(NA, residuos_ardl[-length(residuos_ardl)])
  
  # Modelo ECM
  datos_ecm <- cbind(subdata[6:nrow(subdata), ], ect = ect[6:length(ect)])
  datos_ecm_ts <- ts(datos_ecm %>% dplyr::select(inflacion_anual, dtf_nivel, delta12_log_trm, ise_dae_log, ect),
                     start = c(2006, 6), frequency = 12)
  
  modelo_ecm <- dynlm(d(inflacion_anual) ~ 
                      d(L(inflacion_anual, 1)) +
                      d(dtf_nivel) + d(L(dtf_nivel, 1)) +
                      d(delta12_log_trm) + d(L(delta12_log_trm, 1)) +
                      d(L(ise_dae_log, 0:3)) +
                      ect,
                    data = datos_ecm_ts)
  
  coef_ecm <- coef(modelo_ecm)
  speed_adj <- coef_ecm[length(coef_ecm)]  # Coeficiente del ECT
  
  cat("VELOCIDAD DE AJUSTE (Coeficiente ECT):\n")
  cat(sprintf("  Speed of Adjustment: %.6f\n", speed_adj))
  cat(sprintf("  Interpretación: %.2f%% de desviaciones respecto al equilibrio\n", abs(speed_adj) * 100))
  cat("               se corrigen cada mes\n")
  cat(sprintf("  Tiempo de ajuste: %.2f meses para 63%% de ajuste\n\n", -1/log(1 + speed_adj)))
  
} else {
  cat("No hay evidencia de cointegración en el modelo\n")
  cat("El mecanismo de corrección de error no se estima\n\n")
}

# ==============================================================================
# PASO 10: DIAGNÓSTICOS DEL MODELO
# ==============================================================================

cat("PASO 10: DIAGNÓSTICOS DEL MODELO\n")
cat(strrep("=", 80), "\n\n")

residuos <- residuals(modelo_ardl)

# Test de Breusch-Godfrey (Autocorrelación)
cat("TEST DE BREUSCH-GODFREY (Autocorrelación):\n")
bg_test <- bgtest(modelo_ardl, order = 4)
cat(sprintf("  Estadístico: %.4f | p-valor: %.4f\n", bg_test$statistic, bg_test$p.value))
if (bg_test$p.value > 0.05) {
  cat("  ✓ No hay autocorrelación (H0 no rechazada)\n\n")
} else {
  cat("  ✗ Hay evidencia de autocorrelación\n\n")
}

# Test de Breusch-Pagan (Heteroscedasticidad)
cat("TEST DE BREUSCH-PAGAN (Heteroscedasticidad):\n")
bp_test <- bptest(modelo_ardl)
cat(sprintf("  Estadístico: %.4f | p-valor: %.4f\n", bp_test$statistic, bp_test$p.value))
if (bp_test$p.value > 0.05) {
  cat("  ✓ Homocedasticidad (H0 no rechazada)\n\n")
} else {
  cat("  ✗ Hay evidencia de heteroscedasticidad\n\n")
}

# Test de Normalidad (Shapiro-Wilk)
cat("TEST DE SHAPIRO-WILK (Normalidad de residuos):\n")
sw_test <- shapiro.test(residuos)
cat(sprintf("  Estadístico: %.4f | p-valor: %.4f\n", sw_test$statistic, sw_test$p.value))
if (sw_test$p.value > 0.05) {
  cat("  ✓ Residuos normales (H0 no rechazada)\n\n")
} else {
  cat("  ✗ Residuos no normales\n\n")
}

# ==============================================================================
# PASO 11: COMPARACIÓN ARDL(2,2,2,4) vs ADL(1,1,1,1)
# ==============================================================================

cat("PASO 11: COMPARACIÓN DE MODELOS\n")
cat(strrep("=", 80), "\n\n")

# Cargar modelo ADL anterior
modelo_adl <- readRDS("outputs/ADL/modelo_ADL.rds")

cat("COMPARACIÓN DE AJUSTE:\n")
cat(sprintf("%-20s | %-15s | %-15s\n", "Métrica", "ARDL(2,2,2,4)", "ADL(1,1,1,1)"))
cat(strrep("-", 60), "\n")
cat(sprintf("%-20s | %14.4f | %14.4f\n", "R²", R2, summary(modelo_adl)$r.squared))
cat(sprintf("%-20s | %14.4f | %14.4f\n", "R² Ajustado", R2_adj, summary(modelo_adl)$adj.r.squared))
cat(sprintf("%-20s | %14.4f | %14.4f\n", "AIC", AIC_ardl, AIC(modelo_adl)))
cat(sprintf("%-20s | %14.4f | %14.4f\n", "BIC", BIC_ardl, BIC(modelo_adl)))

# Test de modelos anidados
cat("\n\nCRITERIO DE SELECCIÓN:\n")
if (AIC_ardl < AIC(modelo_adl)) {
  cat("⭐ ARDL(2,2,2,4) tiene MENOR AIC → Modelo preferido\n")
} else {
  cat("⭐ ADL(1,1,1,1) tiene MENOR AIC → Modelo preferido\n")
}
cat("\n")

# ==============================================================================
# PASO 12: PROYECCIÓN FEBRERO 2026
# ==============================================================================

cat("PASO 12: PROYECCIÓN DE INFLACIÓN FEBRERO 2026\n")
cat(strrep("=", 80), "\n\n")

# Últimas observaciones
ultima_obs_inf <- tail(subdata$inflacion_anual, 2)
ultima_obs_dtf <- tail(subdata$dtf_nivel, 2)
ultima_obs_trm <- tail(subdata$delta12_log_trm, 2)
ultima_obs_ise <- tail(subdata$ise_dae_log, 4)

# Proyección para Diciembre 2025
inf_dic2025 <- coef_ardl[1] + 
               lambda_1 * ultima_obs_inf[2] + lambda_2 * ultima_obs_inf[1] +
               beta_dtf_0 * ultima_obs_dtf[2] + beta_dtf_1 * ultima_obs_dtf[1] +
               beta_trm_0 * ultima_obs_trm[2] + beta_trm_1 * ultima_obs_trm[1] +
               beta_ise_0 * ultima_obs_ise[4] + beta_ise_1 * ultima_obs_ise[3] + 
               beta_ise_2 * ultima_obs_ise[2] + beta_ise_3 * ultima_obs_ise[1]

# Proyección para Enero 2026
inf_ene2026 <- coef_ardl[1] + 
               lambda_1 * inf_dic2025 + lambda_2 * ultima_obs_inf[2] +
               beta_dtf_0 * ultima_obs_dtf[2] + beta_dtf_1 * ultima_obs_dtf[2] +
               beta_trm_0 * ultima_obs_trm[2] + beta_trm_1 * ultima_obs_trm[2] +
               beta_ise_0 * ultima_obs_ise[4] + beta_ise_1 * ultima_obs_ise[4] + 
               beta_ise_2 * ultima_obs_ise[3] + beta_ise_3 * ultima_obs_ise[2]

# Proyección para Febrero 2026
inf_feb2026 <- coef_ardl[1] + 
               lambda_1 * inf_ene2026 + lambda_2 * inf_dic2025 +
               beta_dtf_0 * ultima_obs_dtf[2] + beta_dtf_1 * ultima_obs_dtf[2] +
               beta_trm_0 * ultima_obs_trm[2] + beta_trm_1 * ultima_obs_trm[2] +
               beta_ise_0 * ultima_obs_ise[4] + beta_ise_1 * ultima_obs_ise[4] + 
               beta_ise_2 * ultima_obs_ise[3] + beta_ise_3 * ultima_obs_ise[2]

# Proyección para Marzo 2026
inf_mar2026 <- coef_ardl[1] + 
               lambda_1 * inf_feb2026 + lambda_2 * inf_ene2026 +
               beta_dtf_0 * ultima_obs_dtf[2] + beta_dtf_1 * ultima_obs_dtf[2] +
               beta_trm_0 * ultima_obs_trm[2] + beta_trm_1 * ultima_obs_trm[2] +
               beta_ise_0 * ultima_obs_ise[4] + beta_ise_1 * ultima_obs_ise[4] + 
               beta_ise_2 * ultima_obs_ise[3] + beta_ise_3 * ultima_obs_ise[2]

cat("RESULTADO DE LA PROYECCIÓN:\n")
cat(strrep("-", 80), "\n")
cat(sprintf("Inflación Noviembre 2025:      %.4f%%\n", tail(subdata$inflacion_anual, 1)))
cat(sprintf("Inflación Proyectada Dic 2025: %.4f%%\n", inf_dic2025))
cat(sprintf("Inflación Proyectada Ene 2026: %.4f%%\n", inf_ene2026))
cat(sprintf("Inflación Proyectada Feb 2026: %.4f%%\n", inf_feb2026))
cat(sprintf("Inflación Proyectada Mar 2026: %.4f%%\n", inf_mar2026))

cambio_total <- inf_mar2026 - tail(subdata$inflacion_anual, 1)
cambio_pb <- cambio_total * 100

cat(sprintf("\nCambio total (Nov 2025 → Mar 2026): %.4f pp (%.2f pb)\n", cambio_total, cambio_pb))
if (cambio_pb < 0) {
  cat(sprintf("→ Se proyecta DISMINUCIÓN de la inflación en %.2f pb\n", abs(cambio_pb)))
} else {
  cat(sprintf("→ Se proyecta AUMENTO de la inflación en %.2f pb\n", cambio_pb))
}
cat("\n")

# ==============================================================================
# PASO 13: GENERAR GRÁFICAS
# ==============================================================================

cat("PASO 13: GENERANDO GRÁFICAS\n")
cat(strrep("=", 80), "\n\n")

dir.create("outputs/ARDL", showWarnings = FALSE)

# GRÁFICA 1: Diagnósticos del modelo
pdf("outputs/ARDL/01_diagnosticos_ARDL.pdf", width = 14, height = 10)
par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 2))

# Residuos vs Fitted
fitted_vals <- fitted(modelo_ardl)
plot(fitted_vals, residuos, main = "Residuos vs Valores Ajustados", 
     xlab = "Valores Ajustados", ylab = "Residuos",
     col = "darkblue", pch = 19, cex = 0.7)
abline(h = 0, col = "red", lty = 2, lwd = 2)
grid(col = "lightgray", lty = 3)

# Q-Q Plot
qqnorm(residuos, main = "Q-Q Plot", col = "darkblue", pch = 19, cex = 0.7)
qqline(residuos, col = "red", lwd = 2)
grid(col = "lightgray", lty = 3)

# Scale-Location
plot(fitted_vals, sqrt(abs(residuos)), main = "Scale-Location",
     xlab = "Valores Ajustados", ylab = expression(sqrt("|Residuos|")),
     col = "darkblue", pch = 19, cex = 0.7)
grid(col = "lightgray", lty = 3)

# Residuos en el tiempo
plot(residuos, type = "l", main = "Serie de Residuos", 
     xlab = "Tiempo", ylab = "Residuos",
     col = "darkblue", lwd = 1.5)
abline(h = 0, col = "red", lty = 2)
grid(col = "lightgray", lty = 3)

dev.off()
cat("✓ Gráfica guardada: outputs/ARDL/01_diagnosticos_ARDL.pdf\n")

# GRÁFICA 2: Real vs Predicho
pdf("outputs/ARDL/02_predicciones_ARDL.pdf", width = 14, height = 7)
par(mfrow = c(1, 1), mar = c(5, 5, 4, 2))

# Las predicciones del modelo ARDL comienzan desde la observación 6 (después de los rezagos)
n_obs <- nrow(model.frame(modelo_ardl))
fechas_plot <- subdata$fecha[(nrow(subdata) - n_obs + 1):nrow(subdata)]
real <- subdata$inflacion_anual[(nrow(subdata) - n_obs + 1):nrow(subdata)]
predicho <- fitted(modelo_ardl)

ylim_min <- min(real, predicho, na.rm = TRUE) - 0.5
ylim_max <- max(real, predicho, na.rm = TRUE) + 0.5

plot(fechas_plot, real, type = "l", lwd = 2.5, col = "darkblue",
     main = "Inflación Real vs Predicha - ARDL(2,2,2,4)",
     xlab = "Año", ylab = "Inflación Anual (%)",
     ylim = c(ylim_min, ylim_max),
     cex.main = 1.2, cex.lab = 1.1)

lines(fechas_plot, predicho, lwd = 2.5, col = "red", lty = 2)

legend("topright", legend = c("Real", "Predicho (ARDL)"),
       col = c("darkblue", "red"), lwd = c(2.5, 2.5), lty = c(1, 2),
       bty = "n", cex = 1.1)

grid(col = "lightgray", lty = 3)
dev.off()
cat("✓ Gráfica guardada: outputs/ARDL/02_predicciones_ARDL.pdf\n")

# GRÁFICA 3: Comparación Real vs ARDL (últimos 48 meses)
pdf("outputs/ARDL/03_comparacion_modelos_ARDL.pdf", width = 15, height = 8)
par(mfrow = c(1, 1), mar = c(5, 5, 4, 2))

# Datos para la gráfica - mismas fechas que las predicciones
n_obs <- nrow(model.frame(modelo_ardl))
fechas_plot <- subdata$fecha[(nrow(subdata) - n_obs + 1):nrow(subdata)]
real <- subdata$inflacion_anual[(nrow(subdata) - n_obs + 1):nrow(subdata)]
predicho <- fitted(modelo_ardl)

# Últimos 48 meses (4 años)
n_plot <- 48
idx_inicio <- max(1, length(real) - n_plot + 1)

# Plot
plot(fechas_plot[idx_inicio:length(fechas_plot)], 
     real[idx_inicio:length(real)], 
     type = "l", lwd = 3, col = "darkblue",
     main = "Inflación Real vs Predicha ARDL(2,2,2,4) - Últimos 48 meses",
     xlab = "Año", ylab = "Inflación Anual (%)",
     cex.main = 1.3, cex.lab = 1.1)

lines(fechas_plot[idx_inicio:length(fechas_plot)], 
      predicho[idx_inicio:length(predicho)], 
      lwd = 2.5, col = "red", lty = 2)

legend("bottomright", 
       legend = c("Real", "Predicho (ARDL)"),
       col = c("darkblue", "red"), 
       lwd = c(3, 2.5), lty = c(1, 2),
       bty = "n", cex = 1.1)

grid(col = "lightgray", lty = 3)
dev.off()
cat("✓ Gráfica guardada: outputs/ARDL/03_comparacion_modelos_ARDL.pdf\n")

# GRÁFICA 4: Proyección Febrero 2026
pdf("outputs/ARDL/04_proyeccion_feb2026_ARDL.pdf", width = 15, height = 8)

par(mfrow = c(1, 1), mar = c(5, 5, 4, 2))

# Serie completa histórica
fechas_completas <- subdata$fecha
inf_completa <- subdata$inflacion_anual

# Última observación
ultima_fecha <- tail(fechas_completas, 1)
ultima_inf <- tail(inf_completa, 1)

# Series de fechas y valores proyectados
fechas_proyectadas <- seq(from = as.Date("2025-12-01"), 
                          to = as.Date("2026-03-01"), 
                          by = "month")
inf_proyectadas <- c(inf_dic2025, inf_ene2026, inf_feb2026, inf_mar2026)

# Crear serie completa
fechas_todo <- c(fechas_completas, fechas_proyectadas)
inf_todo <- c(inf_completa, inf_proyectadas)

# Determinar rangos
xlim_min <- min(fechas_completas)
xlim_max <- max(fechas_proyectadas) + 200
ylim_min <- 1
ylim_max <- 15

# Plot principal
plot(fechas_completas, inf_completa, type = "l", lwd = 2.5, col = "darkblue",
     main = "Proyección de Inflación hasta Marzo 2026 - ARDL(2,2,2,4)\n(Histórico 2006-2025 + Pronóstico 4 meses)",
     xlab = "Año", ylab = "Inflación Anual (%)",
     xlim = c(xlim_min, xlim_max),
     ylim = c(ylim_min, ylim_max),
     cex.main = 1.2, cex.lab = 1.1)

# Área de rango meta (2-4%) - Sombreado en verde
rect(xlim_min, 2, xlim_max, 4, 
     col = rgb(0, 0.7, 0, 0.12), border = NA)

# Sombrear los últimos 12 meses
ultimos_meses <- 12
idx_desde <- max(1, nrow(subdata) - ultimos_meses + 1)
rect(subdata$fecha[idx_desde], ylim_min - 1, ultima_fecha, ylim_max + 1, 
     col = rgb(0.7, 0.7, 0.7, 0.05), border = NA)

# Líneas de proyección - ROJO OSCURO MÁS VISIBLE
lines(fechas_proyectadas, inf_proyectadas, lwd = 4, lty = 2, col = "red")

# Puntos de proyección
points(fechas_proyectadas[1], inf_proyectadas[1], pch = 19, cex = 3.5, col = "red")
points(fechas_proyectadas[2], inf_proyectadas[2], pch = 19, cex = 3.5, col = "red")
points(fechas_proyectadas[3], inf_proyectadas[3], pch = 19, cex = 4, col = "red")
points(fechas_proyectadas[4], inf_proyectadas[4], pch = 19, cex = 4.5, col = "darkred")

# Anotaciones de proyección
text(fechas_proyectadas[1], inf_proyectadas[1] - 0.4,
     sprintf("Dic 2025\n%.2f%%", inf_proyectadas[1]),
     col = "darkred", font = 2, cex = 0.95, adj = c(0.5, 1))

text(fechas_proyectadas[2], inf_proyectadas[2] - 0.4,
     sprintf("Ene 2026\n%.2f%%", inf_proyectadas[2]),
     col = "darkred", font = 2, cex = 0.95, adj = c(0.5, 1))

text(fechas_proyectadas[3], inf_proyectadas[3] - 0.4,
     sprintf("Feb 2026\n%.2f%%", inf_proyectadas[3]),
     col = "darkred", font = 2, cex = 0.95, adj = c(0.5, 1))

text(fechas_proyectadas[4], inf_proyectadas[4] + 0.45,
     sprintf("MAR 2026\n%.2f%%", inf_proyectadas[4]),
     col = "darkred", font = 3, cex = 1.2, adj = c(0.5, 0),
     bg = rgb(1, 1, 1, 0.8))

# Líneas del rango meta
abline(h = 2, col = "darkgreen", lty = 2, lwd = 2.5)
abline(h = 4, col = "darkgreen", lty = 2, lwd = 2.5)

# Etiquetas del rango meta
text(xlim_min + 300, 2.1, "Meta inferior (2%)", col = "darkgreen", font = 2, cex = 0.95, adj = c(0, 0))
text(xlim_min + 300, 3.85, "Meta superior (4%)", col = "darkgreen", font = 2, cex = 0.95, adj = c(0, 1))
text(xlim_max - 300, 3, "RANGO\nMETA", 
     col = "darkgreen", font = 3, cex = 1.1, adj = c(1, 0.5),
     bg = rgb(1, 1, 1, 0.6))

# Anotación de última observación
text(ultima_fecha, ultima_inf - 0.35, 
     sprintf("Nov 2025\n(Último dato)\n%.2f%%", ultima_inf),
     col = "darkblue", font = 2, cex = 0.9, adj = c(0.5, 1))

# Leyenda
legend("topright",
       legend = c("Histórico 2006-2025 (azul)", 
                  "Pronóstico 4 meses (rojo punteado)",
                  "Últimos 12 meses (zona gris)"),
       col = c("darkblue", "red", "gray"), 
       lwd = c(2.5, 4, 4), pch = c(NA, 19, NA), lty = c(1, 2, NA),
       bty = "n", cex = 1.0, x.intersp = 0.5)

grid(nx = NULL, ny = NULL, col = "lightgray", lty = 3, lwd = 0.8)
dev.off()

cat("✓ Gráfica guardada: outputs/ARDL/04_proyeccion_feb2026_ARDL.pdf\n")

# ==============================================================================
# PASO 14: GUARDAR RESULTADOS
# ==============================================================================

cat("\n\nPASO 14: GUARDANDO RESULTADOS\n")
cat(strrep("=", 80), "\n\n")

saveRDS(modelo_ardl, "outputs/ARDL/modelo_ARDL.rds")
saveRDS(subdata, "outputs/ARDL/subdata_ARDL.rds")

cat("Archivos guardados:\n")
cat("  • outputs/ARDL/modelo_ARDL.rds\n")
cat("  • outputs/ARDL/subdata_ARDL.rds\n")
cat("  • outputs/ARDL/01_diagnosticos_ARDL.pdf\n")
cat("  • outputs/ARDL/02_predicciones_ARDL.pdf\n")
cat("  • outputs/ARDL/03_comparacion_modelos_ARDL.pdf\n")
cat("  • outputs/ARDL/04_proyeccion_feb2026_ARDL.pdf\n\n")

cat(strrep("=", 80), "\n")
cat("✅ ANÁLISIS ARDL(2,2,2,4) COMPLETADO\n")
cat(strrep("=", 80), "\n\n")
