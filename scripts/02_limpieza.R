############################################################
# 02_cleaning.R
# Limpieza y preprocesamiento de datos
############################################################
# Cargar paquetes
source("scripts/01_packages.R")


# ============================================================================
# 1. LIMPIEZA Y PROCESAMIENTO TRM
#    (Tasa Representativa del Mercado - datos diarios)
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("1. LIMPIEZA: TRM (Tasa Representativa del Mercado)\n")
cat(strrep("=", 76), "\n")

# 1.1 Lectura de datos crudos
cat("\n   [1.1] Cargando datos crudos...\n")
TRM_raw <- read_excel("data/raw/TRM.xlsx")
cat("        ✓ Dimensiones iniciales:", nrow(TRM_raw), "filas x", ncol(TRM_raw), "columnas\n")

# 1.2 Limpieza estructural
cat("   [1.2] Aplicando transformaciones...\n")
TRM_clean <- TRM_raw %>%
  slice(-1) %>%  # Eliminar fila de metadatos
  rename(
    Fecha = names(.)[1],
    TRM_fin_mes = names(.)[2],
    TRM_promedio = names(.)[3]
  ) %>%
  mutate(
    Fecha = as.Date(Fecha, format = "%d/%m/%Y"),
    TRM_fin_mes = as.numeric(gsub(",", ".", gsub("\\.", "", TRM_fin_mes))),
    TRM_promedio = as.numeric(gsub(",", ".", gsub("\\.", "", TRM_promedio)))
  ) %>%
  drop_na(TRM_fin_mes) %>%
  arrange(Fecha) %>%
  mutate(
    # Calcular cambio logarítmico mes vs mes del año anterior (12 meses)
    TRM_promedio_lag_12 = lag(TRM_promedio, 12),  # TRM promedio del mismo mes hace 12 meses
    TRM_log = log(TRM_promedio / TRM_promedio_lag_12) * 100  # Cambio en log, expresado en %
  )

# 1.3 Validación y reporte
cat("         Dimensiones finales:", nrow(TRM_clean), "filas x", ncol(TRM_clean), "columnas\n")
cat("         Rango de fechas:", format(min(TRM_clean$Fecha), "%Y-%m-%d"), 
    "-", format(max(TRM_clean$Fecha), "%Y-%m-%d"), "\n")

# 1.4 Guardado
write_csv(TRM_clean, "data/processed/TRM_limpia.csv")
saveRDS(TRM_clean, "data/processed/TRM_limpia.rds")
cat("        ✓ Guardada en: data/processed/TRM_limpia.{csv,rds}\n")
rm(TRM_raw)


# ============================================================================
# 2. LIMPIEZA Y PROCESAMIENTO IPC
#    (Índice de Precios al Consumidor - variación mensual)
# ============================================================================
# 2. LIMPIEZA Y PROCESAMIENTO IPC
#    (Índice de Precios al Consumidor - variación mensual)
# ============================================================================
ipc <- read_excel("data/raw/anex-IPC-Indices-ene2026.xlsx", sheet = "IPC")
ipc_long <- ipc %>%
  pivot_longer(
    cols = -Mes,
    names_to = "anio",
    values_to = "ipc"
  ) %>%
  mutate(
    mes_num = case_when(
      Mes == "Enero" ~ 1,
      Mes == "Febrero" ~ 2,
      Mes == "Marzo" ~ 3,
      Mes == "Abril" ~ 4,
      Mes == "Mayo" ~ 5,
      Mes == "Junio" ~ 6,
      Mes == "Julio" ~ 7,
      Mes == "Agosto" ~ 8,
      Mes == "Septiembre" ~ 9,
      Mes == "Octubre" ~ 10,
      Mes == "Noviembre" ~ 11,
      Mes == "Diciembre" ~ 12
    ),
    fecha = as.Date(paste(anio, mes_num, "1", sep = "-"), format = "%Y-%m-%d")
  ) %>%
  drop_na() %>%
  arrange(fecha) %>%
  dplyr::select(fecha, ipc) %>%
  # Calcular cambio logarítmico mes vs mes del año anterior
  mutate(
    ipc_lag_12 = lag(ipc, 12),  # IPC del mismo mes hace 12 meses (año anterior)
    ipc_log_cambio = log(ipc / ipc_lag_12) * 100  # Cambio en log, expresado en %
  )

# 2.1 Guardado del IPC limpio
write_csv(ipc_long, "data/processed/IPC_limpio.csv")
openxlsx::write.xlsx(ipc_long, "data/processed/IPC_limpio.xlsx")
cat("        ✓ Guardado IPC en: data/processed/IPC_limpio.{csv,xlsx}\n")
