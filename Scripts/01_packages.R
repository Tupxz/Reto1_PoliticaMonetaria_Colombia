############################################################
# Carga de paquetes
############################################################

packages <- c(
  "tidyverse",
  "lubridate",
  "vars",
  "tseries"
)

installed <- packages %in% rownames(installed.packages())

if (any(!installed)) {
  install.packages(packages[!installed])
}

lapply(packages, library, character.only = TRUE)