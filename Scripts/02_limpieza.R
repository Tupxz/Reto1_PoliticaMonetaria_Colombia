############################################################
# 02_cleaning.R
# Limpieza y preprocesamiento de datos
############################################################
# Cargar paquetes
source("scripts/01_packages.R")

# Crear directorio de salida si no existe
if (!dir.exists("data/processed")) {
  dir.create("data/processed", recursive = TRUE)
}


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
  arrange(Fecha)

# 1.3 Validación y reporte
cat("        ✓ Dimensiones finales:", nrow(TRM_clean), "filas x", ncol(TRM_clean), "columnas\n")
cat("        ✓ Rango de fechas:", format(min(TRM_clean$Fecha), "%Y-%m-%d"), 
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
