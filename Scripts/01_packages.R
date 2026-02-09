############################################################
# 01_packages.R
# Instalación y carga de paquetes necesarios
############################################################

# Vector de paquetes requeridos
packages <- c(
  "tidyverse",  # Manipulación y visualización de datos
  "lubridate",  # Manejo de fechas y tiempos
  "vars",       # Modelos VAR
  "tseries",    # Series de tiempo
  "readxl"      # Lectura de archivos Excel
)

# Instala los paquetes que no estén instalados
installed <- packages %in% rownames(installed.packages())
if (any(!installed)) {
  install.packages(packages[!installed])
}

# Carga todos los paquetes
invisible(lapply(packages, library, character.only = TRUE))