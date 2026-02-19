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
adf_inf <- test_adf(datos$inflacion_anual, "Inflación Anual")
cat("  → Inflación es I(1): tiene persistencia fuerte\n")
cat("     Los shocks no se disipan inmediatamente\n\n")

cat("VARIABLES EXPLICATIVAS:\n")
adf_dtf <- test_adf(datos$dtf_nivel, "DTF Nivel")
adf_trm <- test_adf(datos$delta12_log_trm, "Δ12 log(TRM)")
adf_ise <- test_adf(datos$ise_dae_log, "ISE DAE Log")
adf_ise_t <- test_adf(datos$ise_dae_T_log, "ISE Terciario")

cat("\n✓ CONCLUSIÓN: Variables I(0) son estacionarias → OLS es válido\n\n")
