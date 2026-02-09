############################################################
# 02_cleaning.R
# Limpieza y preprocesamiento de datos
############################################################
# Cargar paquetes
source("scripts/01_packages.R")

# Lectura de datos
TRM_raw <- read_excel("Datos/TRM.xlsx")

# Eliminar fila 2 que parece metadato
TRM_clean <- TRM_raw[-1, ]

# Renombrar columnas sin espacios
colnames(TRM_clean) <- c("Fecha", "TRM_fin_mes", "TRM_promedio")

# Convertir fecha
TRM_clean$Fecha <- as.Date(TRM_clean$Fecha, format = "%d/%m/%Y")

# Eliminar filas con TRM faltante o "-"
TRM_clean <- TRM_clean %>% filter(TRM_fin_mes != "-") 

# Convertir columnas a numérico correctamente (manteniendo decimales)
TRM_clean <- TRM_clean %>%
  mutate(
    TRM_fin_mes = as.numeric(gsub(",", ".", gsub("\\.", "", TRM_fin_mes))),
    TRM_promedio = as.numeric(gsub(",", ".", gsub("\\.", "", TRM_promedio)))
  )

# Ordenar por fecha
TRM_clean <- TRM_clean %>% arrange(Fecha)


# Guardar dataset limpio
write_csv(TRM_clean, "Datos/TRM_limpia.csv")
saveRDS(TRM_clean, "Datos/TRM.rds")


############################################################
# Nota:
# Visualizaciones deben ir en un script aparte (03_plots.R)
############################################################
