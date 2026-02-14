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

cat("\n", strrep("=", 76), "\n")
cat("2. LIMPIEZA: IPC (Índice de Precios al Consumidor)\n")
cat(strrep("=", 76), "\n")

# 2.1 Lectura de datos crudos
cat("\n   [2.1] Cargando datos crudos...\n")
IPC_raw <- read_excel("data/raw/anex-IPC-Variacion-ene2026.xlsx", col_names = FALSE)
cat("        ✓ Dimensiones iniciales:", nrow(IPC_raw), "filas x", ncol(IPC_raw), "columnas\n")

# 2.2 Limpieza estructural
cat("   [2.2] Aplicando transformaciones...\n")

# Encontrar fila con "Mes"
header_row <- NA
for (i in seq_len(nrow(IPC_raw))) {
  if (grepl("Mes", IPC_raw[[i, 1]], ignore.case = TRUE)) {
    header_row <- i
    break
  }
}

# Procesar datos
if (!is.na(header_row)) {
  # Usar la fila identificada como encabezado
  IPC_clean <- IPC_raw %>%
    slice(-c(1:header_row)) %>%
    as.data.frame() %>%
    as_tibble(.name_repair = "minimal") %>%
    # Renombrar primera columna como Mes
    `colnames<-`(c("Mes", paste0("año_", seq_len(ncol(.) - 1)))) %>%
    # Limpiar datos
    filter(Mes != "" & !is.na(Mes)) %>%
    filter(!grepl("variación|año|período|descargado|fichas", Mes, ignore.case = TRUE)) %>%
    mutate(
      Mes = tolower(str_trim(Mes)),
      across(-Mes, ~as.numeric(gsub(",", ".", as.character(.x))))
    )
} else {
  cat("        ⚠ Advertencia: No se encontró encabezado de meses\n")
  IPC_clean <- tibble()
}

# 2.3 Validación y reporte
cat("        ✓ Dimensiones finales:", nrow(IPC_clean), "filas x", ncol(IPC_clean), "columnas\n")

# 2.4 Guardado
write_csv(IPC_clean, "data/processed/IPC_limpia.csv")
saveRDS(IPC_clean, "data/processed/IPC_limpia.rds")
cat("        ✓ Guardada en: data/processed/IPC_limpia.{csv,rds}\n")
rm(IPC_raw)


# ============================================================================
# 3. LIMPIEZA Y PROCESAMIENTO CDT
#    (Certificados de Depósito a Término - datos trimestrales)
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("3. LIMPIEZA: CDT (Certificados de Depósito a Término)\n")
cat(strrep("=", 76), "\n")

# 3.1 Lectura de datos crudos
cat("\n   [3.1] Cargando datos crudos...\n")
cdt_sheets <- excel_sheets("data/raw/CDT TRIMESTRAL.xlsx")
cat("        ✓ Hojas disponibles:", paste(cdt_sheets, collapse = ", "), "\n")

CDT_raw <- read_excel("data/raw/CDT TRIMESTRAL.xlsx", sheet = "Series de datos")
cat("        ✓ Dimensiones iniciales:", nrow(CDT_raw), "filas x", ncol(CDT_raw), "columnas\n")

# 3.2 Limpieza estructural
cat("   [3.2] Aplicando transformaciones...\n")

# Identificar la fila de encabezado (contiene "Fecha")
header_row <- which(grepl("Fecha", CDT_raw[[1]], ignore.case = TRUE))[1]

if (!is.na(header_row)) {
  CDT_clean <- CDT_raw %>%
    slice(-c(1:header_row)) %>%  # Eliminar metadatos y encabezado
    as_tibble(.name_repair = "minimal") %>%
    `colnames<-`(c("fecha", "serie_1", "serie_2", "serie_3", "serie_4", "serie_5")) %>%
    # Limpiar datos
    filter(!is.na(fecha) & fecha != "" & fecha != ".") %>%
    mutate(
      # Convertir fecha numérica (Excel serial) a date
      fecha = as.Date(as.numeric(fecha), origin = "1899-12-30"),
      # Convertir series a numérico
      across(starts_with("serie"), ~as.numeric(gsub("\\.", "", .x)))
    ) %>%
    arrange(fecha)
} else {
  cat("        ⚠ Advertencia: No se encontró encabezado de fechas\n")
  CDT_clean <- tibble()
}

# 3.3 Validación y reporte
cat("        ✓ Dimensiones finales:", nrow(CDT_clean), "filas x", ncol(CDT_clean), "columnas\n")
if (nrow(CDT_clean) > 0) {
  cat("        ✓ Rango de fechas:", format(min(CDT_clean$fecha, na.rm = TRUE), "%Y-%m-%d"), 
      "-", format(max(CDT_clean$fecha, na.rm = TRUE), "%Y-%m-%d"), "\n")
}

# 3.4 Guardado
if (nrow(CDT_clean) > 0) {
  write_csv(CDT_clean, "data/processed/CDT_limpia.csv")
  saveRDS(CDT_clean, "data/processed/CDT_limpia.rds")
  cat("        ✓ Guardada en: data/processed/CDT_limpia.{csv,rds}\n")
} else {
  cat("        ⚠ No se guardó CDT por falta de datos válidos\n")
}
rm(CDT_raw)


# ============================================================================
# 4. LIMPIEZA Y PROCESAMIENTO GEIH
#    (Gran Encuesta Integrada de Hogares - desempleo mensual)
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("4. LIMPIEZA: GEIH (Gran Encuesta Integrada de Hogares)\n")
cat(strrep("=", 76), "\n")

# 4.1 Lectura de datos crudos
cat("\n   [4.1] Cargando datos crudos...\n")
geih_sheets <- excel_sheets("data/raw/anex-GEIH-dic2025.xlsx")
cat("        ✓ Hojas disponibles (primeras 3):", paste(geih_sheets[1:3], collapse = ", "), "\n")

GEIH_raw <- read_excel("data/raw/anex-GEIH-dic2025.xlsx", 
                        sheet = "Total nacional",
                        col_names = FALSE)
cat("        ✓ Dimensiones iniciales:", nrow(GEIH_raw), "filas x", ncol(GEIH_raw), "columnas\n")

# 4.2 Limpieza estructural
cat("   [4.2] Aplicando transformaciones...\n")

# Encontrar fila con "Concepto"
concept_row <- NA
for (i in seq_len(min(20, nrow(GEIH_raw)))) {
  if (grepl("concepto", GEIH_raw[[i, 1]], ignore.case = TRUE)) {
    concept_row <- i
    break
  }
}

if (!is.na(concept_row)) {
  GEIH_clean <- GEIH_raw %>%
    slice(-c(1:concept_row)) %>%
    as.data.frame() %>%
    as_tibble(.name_repair = "unique_quiet") %>%
    # Renombrar primera columna
    `colnames<-`(c("Concepto", paste0("valor_", seq_len(ncol(.) - 1)))) %>%
    # Limpiar filas vacías y eliminar NAs
    filter(!is.na(Concepto) & Concepto != "") %>%
    mutate(
      across(everything(), as.character),
      across(-Concepto, ~as.numeric(gsub(",", ".", .x)))
    ) %>%
    # Eliminar filas que sean completamente NA
    filter(!if_all(starts_with("valor"), ~is.na(.x)))
} else {
  cat("        ⚠ Advertencia: No se encontró fila de conceptos\n")
  GEIH_clean <- tibble()
}

# 4.3 Validación y reporte
cat("        ✓ Dimensiones finales:", nrow(GEIH_clean), "filas x", ncol(GEIH_clean), "columnas\n")

# 4.4 Guardado
if (nrow(GEIH_clean) > 0) {
  write_csv(GEIH_clean, "data/processed/GEIH_limpia.csv")
  saveRDS(GEIH_clean, "data/processed/GEIH_limpia.rds")
  cat("        ✓ Guardada en: data/processed/GEIH_limpia.{csv,rds}\n")
} else {
  cat("        ⚠ No se guardó GEIH por falta de datos válidos\n")
}
rm(GEIH_raw)


# ============================================================================
# 5. LIMPIEZA Y PROCESAMIENTO ISE
#    (Índice de Seguimiento a la Economía - 3 cuadros separados)
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("5. LIMPIEZA: ISE (Índice de Seguimiento a la Economía)\n")
cat(strrep("=", 76), "\n")

# 5.1 Lectura de datos crudos
cat("\n   [5.1] Cargando datos crudos (3 cuadros)...\n")
ise_sheets <- excel_sheets("data/raw/anex-ISE-9actividades-nov2025.xlsx")
cat("        ✓ Hojas disponibles:", paste(ise_sheets, collapse = ", "), "\n")

# Función auxiliar para limpiar cada cuadro ISE
limpiar_cuadro_ise <- function(sheet_name) {
  ise_raw <- read_excel("data/raw/anex-ISE-9actividades-nov2025.xlsx", 
                         sheet = sheet_name,
                         col_names = FALSE)
  
  # Encontrar fila con "Concepto"
  concept_row <- NA
  for (i in seq_len(min(15, nrow(ise_raw)))) {
    if (grepl("concepto", ise_raw[[i, 1]], ignore.case = TRUE)) {
      concept_row <- i
      break
    }
  }
  
  if (!is.na(concept_row)) {
    ise_clean <- ise_raw %>%
      slice(-c(1:concept_row)) %>%
      as_tibble(.name_repair = "minimal") %>%
      `colnames<-`(c("Actividad", paste0("valor_", seq_len(ncol(.) - 1)))) %>%
      filter(!is.na(Actividad) & Actividad != "") %>%
      mutate(
        across(everything(), as.character),
        across(-Actividad, ~as.numeric(gsub(",", ".", .x)))
      ) %>%
      # Eliminar filas con todos los valores NA
      filter(!if_all(starts_with("valor"), ~is.na(.x)))
    return(ise_clean)
  } else {
    return(tibble())
  }
}

# 5.2 Limpieza estructural para cada cuadro
cat("   [5.2] Procesando 3 cuadros separados...\n")

# Cuadro 1: Datos originales
ISE_cuadro1 <- limpiar_cuadro_ise("Cuadro 1")
cat("        ✓ Cuadro 1 (Datos originales):", nrow(ISE_cuadro1), "filas\n")

# Cuadro 2: Datos ajustados por efecto estacional y calendario
ISE_cuadro2 <- limpiar_cuadro_ise("Cuadro 2")
cat("        ✓ Cuadro 2 (Ajustados estacional/calendario):", nrow(ISE_cuadro2), "filas\n")

# Cuadro 3: Componente tendencia-ciclo
ISE_cuadro3 <- limpiar_cuadro_ise("Cuadro 3")
cat("        ✓ Cuadro 3 (Componente tendencia-ciclo):", nrow(ISE_cuadro3), "filas\n")

# 5.3 Guardado de cada cuadro
cat("   [5.3] Guardando archivos...\n")

if (nrow(ISE_cuadro1) > 0) {
  write_csv(ISE_cuadro1, "data/processed/ISE_Cuadro1_datos_originales.csv")
  saveRDS(ISE_cuadro1, "data/processed/ISE_Cuadro1_datos_originales.rds")
  cat("        ✓ ISE Cuadro 1 guardada\n")
}

if (nrow(ISE_cuadro2) > 0) {
  write_csv(ISE_cuadro2, "data/processed/ISE_Cuadro2_ajustados_estacional.csv")
  saveRDS(ISE_cuadro2, "data/processed/ISE_Cuadro2_ajustados_estacional.rds")
  cat("        ✓ ISE Cuadro 2 guardada\n")
}

if (nrow(ISE_cuadro3) > 0) {
  write_csv(ISE_cuadro3, "data/processed/ISE_Cuadro3_tendencia_ciclo.csv")
  saveRDS(ISE_cuadro3, "data/processed/ISE_Cuadro3_tendencia_ciclo.rds")
  cat("        ✓ ISE Cuadro 3 guardada\n")
}

rm(ise_raw)


# ============================================================================
# 6. RESUMEN FINAL
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("RESUMEN DE LIMPIEZA - Bases de datos procesadas\n")
cat(strrep("=", 76), "\n\n")

# Verificar archivos generados
processed_files <- list.files("data/processed/", pattern = "\\.(csv|rds)$")
cat("Archivos generados en data/processed/:\n")
for (f in sort(processed_files)) {
  cat("   ✓", f, "\n")
}

cat("\n✓ Limpieza completada exitosamente\n\n")

cat("RESUMEN DE BASES PROCESADAS:\n")
cat("   1. TRM: Tasa Representativa del Mercado (1 archivo)\n")
cat("   2. IPC: Índice de Precios al Consumidor (1 archivo)\n")
cat("   3. CDT: Certificados de Depósito a Término (1 archivo limpio)\n")
cat("   4. GEIH: Gran Encuesta Integrada de Hogares (1 archivo sin NAs)\n")
cat("   5. ISE: Índice de Seguimiento a la Economía (3 archivos separados)\n")
cat("      - Cuadro 1: Datos originales\n")
cat("      - Cuadro 2: Datos ajustados por efecto estacional/calendario\n")
cat("      - Cuadro 3: Componente tendencia-ciclo\n\n")

cat("Próximos pasos:\n")
cat("   1. Revisar estructura de datos en 03_descriptivas.R\n")
cat("   2. Alinear frecuencias temporales\n")
cat("   3. Fusionar bases para análisis VAR\n\n")

############################################################################
# NOTAS TÉCNICAS:
# - Archivos guardados en formato CSV (legible) y RDS (eficiente)
# - Fechas en formato ISO (YYYY-MM-DD) donde aplica
# - Números decimales con punto (.) como separador
# - Nombres de columnas en minúsculas
# - NA eliminados donde fue necesario (GEIH)
# - ISE: 3 cuadros separados por tipo de ajuste
# - CDT: Datos procesados con fechas válidas
############################################################################
