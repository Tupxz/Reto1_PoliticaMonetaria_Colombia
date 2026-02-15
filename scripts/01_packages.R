############################################################
# 01_packages.R
# Instalación y carga de paquetes necesarios
############################################################

# Lista de paquetes requeridos
packages <- c(
  "tidyverse",
  "lubridate",
  "vars",
  "tseries",
  "readxl"
)

# Identifica cuáles paquetes no están instalados
not_installed <- packages[!(packages %in% rownames(installed.packages()))]

# Instala solo los que faltan
if(length(not_installed)) {
  install.packages(not_installed)
}

# Carga todos los paquetes
invisible(lapply(packages, library, character.only = TRUE))