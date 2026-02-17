############################################################
# Script maestro
# Proyecto: R1 - Política Monetaria e Inflación en Colombia
# Econometría II - Universidad EAFIT
# Autores: Santiago Tupaz, Moisés Quintero
############################################################

# Limpieza del entorno --------------------------------------------------
rm(list = ls())

# Cargar paquetes -------------------------------------------------------
source("scripts/01_packages.R")

# Limpieza de datos -----------------------------------------------------
source("scripts/02_limpieza.R")

# Estadísticas descriptivas ---------------------------------------------
source("scripts/03_descriptivas.R")

# Estimación del modelo VAR ---------------------------------------------
source("scripts/ADL.R")

# Predicciones ----------------------------------------------------------
#source("scripts/05_predicciones.R")
