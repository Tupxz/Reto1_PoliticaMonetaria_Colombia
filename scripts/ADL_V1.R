source("scripts/01_packages.R")

#Datos para ADL
IPC_clean <- read_csv("data/processed/IPC_limpio.csv") %>%
  filter(year(fecha) >= 2006) %>%
  mutate(fecha = floor_date(fecha, "month")) %>%
  arrange(fecha)

TRM_clean <- read_rds("data/processed/TRM_limpia.rds") %>%
  filter(year(Fecha) >= 2006) %>%
  mutate(fecha = floor_date(Fecha, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, delta12_log_trm = TRM_log)

CDT_clean <- read_excel("data/processed/CDT_limpia.xlsx") %>%
  mutate(fecha_raw = as.Date(as.numeric(Fecha), origin = "1899-12-30")) %>%
  filter(!is.na(fecha_raw) & year(fecha_raw) >= 2006) %>%
  mutate(fecha = floor_date(fecha_raw, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, dtf_nivel = 2)

indicadores <- read_excel("data/processed/anex-ISE-9actividades-nov2025-limpia.xlsx",
                          sheet = "indicadores") %>%
  filter(year(fecha) >= 2006) %>%
  mutate(fecha = floor_date(fecha, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, ise_dae_log = ISE_dae_log, ise_dae_T_log = ISE_dae_T_log)

#Unificar las bases de datos por fecha y calcular Δ12 log TRM

datos <- IPC_clean %>%
  dplyr::select(fecha, inflacion_anual = ipc_log_cambio) %>%
  left_join(TRM_clean, by = "fecha") %>%
  left_join(CDT_clean, by = "fecha") %>%
  left_join(indicadores, by = "fecha") %>%
  dplyr::select(fecha, inflacion_anual, dtf_nivel, delta12_log_trm, ise_dae_log, ise_dae_T_log) %>%
  arrange(fecha) 

# ==============================================================================
# CREAR SUBDATA PARA PRUEBAS DEL MODELO
# ==============================================================================
# Subdata desde 2006-01 hasta 2025-01 para pruebas del modelo

subdata <- datos %>%
  filter(fecha >= as.Date("2006-01-01") & fecha <= as.Date("2025-01-31"))

# Determinamos si son o no estacionarias utilizando el test DF
plot.ts(subdata[, c("inflacion_anual", "dtf_nivel", "delta12_log_trm", "ise_dae_log", "ise_dae_T_log")])

############################################
# DF
############################################

############################################
# Inflación anual como logΔ12 IPC
############################################

DF.inflacion <- ur.df(subdata$inflacion_anual, type = "trend", selectlags = "AIC")
summary(DF.inflacion)
DF.inflacion_D<- ur.df(subdata$inflacion_anual, type = "drift", selectlags = "AIC")
summary(DF.inflacion_D)
# Apesar de no tener intercepto significativo se deja ya que en macro aplicada la inflación no se elimina el intercepto
summary(
  ur.df(subdata$inflacion_anual,
        type = "drift",
        selectlags = "AIC")
)

# es I(1)
#Tiene persistencia fuerte - Los shocks no se disipan inmediatamente -Hay memoria en la dinámica inflacionaria
#Eso es bastante coherente con economías como Colombia.
subdata$inflacion_diff <- c(NA, diff(subdata$inflacion_anual))
############################################
# DTF
############################################
DF.dtf <- ur.df(subdata$dtf_nivel, type = "trend", selectlags = "AIC")
summary(DF.dtf)
DF.dtf_D <- ur.df(subdata$dtf_nivel, type = "drift", selectlags = "AIC")
summary(DF.dtf_D)
# no bajo a none porque la DFT no osila entre el 0, siempre es positiva
summary(
  ur.df(diff(subdata$dtf_nivel),
        type="drift",
        selectlags="AIC")
)
#
subdata$dtf_diff <- c(NA, diff(subdata$dtf_nivel))

############################################
# TRM
############################################
DF.trm <- ur.df(subdata$delta12_log_trm, type = "trend", selectlags = "AIC")
summary(DF.trm)

ur.df(subdata$delta12_log_trm,
      type="drift",
      selectlags="AIC")

# es I(0) sin tendencia pero con drift, lo que es consistente con la idea de que la TRM tiene una tendencia creciente a lo largo del tiempo.

############################################
# ISE
############################################

DF.ise <- ur.df(subdata$ise_dae_log, type = "trend", selectlags = "AIC")
summary(DF.ise)
summary(
  ur.df(subdata$ise_dae_log,
        type="drift",
        selectlags="AIC")

)
# es I(1) con drift, lo que sugiere que el ISE tiene una tendencia creciente a lo largo del tiempo, pero no muestra evidencia de una tendencia determinista significativa.

##################################################
# ISE sector terciario
##################################################
DF.ise_T <- ur.df(subdata$ise_dae_T_log, type = "trend", selectlags = "AIC")
summary(DF.ise_T)
summary(
  ur.df(subdata$ise_dae_T_log,
        type="drift",
        selectlags="AIC")
)
# no se diferencia más, es I(0) con drift, lo que sugiere que el ISE del sector terciario tiene una tendencia creciente a lo largo del tiempo, pero no muestra evidencia de una tendencia determinista significativa.

######################
# correlogramas
#####################

# ISE
par(mfrow=c(1,2))
acf(subdata$ise_dae_log, main="ACF ISE")
pacf(subdata$ise_dae_log, main="PACF ISE")
# AR(1) o AR(2)
subdata$lag1_ISE <- dplyr::lag(subdata$ise_dae_log, 1)

ar1 <- lm(ise_dae_log ~ lag1_ISE, data = subdata)
summary(ar1)

acf(resid(ar1))
# un shock de 1 punto porcentual en hoy provoca uno de 0.84 puntos en el proximo mes
acf(resid(ar1))
Box.test(resid(ar1), type="Ljung-Box")
# segun esto es  AR(1) muy fuerte
autoarima_ise <- auto.arima(na.omit(subdata$ise_dae_log))
summary(autoarima_ise)
checkresiduals(autoarima_ise)
Box.test(resid(autoarima_ise), type="Ljung-Box")
# ARIMA(1,0,0) sin autocorrelación en los residuos,
#ISE sector terciario
par(mfrow=c(1,2))
acf(subdata$ise_dae_T_log, main="ACF ISE sector terciario")
pacf(subdata$ise_dae_T_log, main="PACF ISE sector terciario")
# AR(1) o
subdata$lag1_ISE <- dplyr::lag(subdata$ise_dae_log, 1)

ar1 <- lm(ise_dae_T_log ~ lag1_ISE, data = subdata)
summary(ar1)

acf(resid(ar1))
autoarima_ise_T <- auto.arima(na.omit(subdata$ise_dae_T_log))
summary(autoarima_ise_T)
checkresiduals(autoarima_ise_T)
Box.test(resid(autoarima_ise_T), type="Ljung-Box")

#AR(1,0,1)

# TRM
par(mfrow=c(1,2))
acf(subdata$delta12_log_trm, main="ACF Δ12 log TRM ")
pacf(subdata$delta12_log_trm, main="PACF Δ12 log TRM")
# AR(2) o AR(3)
subdata$lag1_trm <- dplyr::lag(subdata$delta12_log_trm, 2)
subdata$lag2_trm <- dplyr::lag(subdata$delta12_log_trm, 3)
ar2 <- lm(delta12_log_trm ~ lag1_trm + lag2_trm, data = subdata)
summary(ar2)
acf(resid(ar2))
Box.test(resid(ar2), type="Ljung-Box")
#AR(2) o AR(3) sin aurocorrelación en los residuos, es decir, ruido blanco
autoarima_trm <- auto.arima(na.omit(subdata$delta12_log_trm))
summary(autoarima_trm)
checkresiduals(autoarima_trm)
Box.test(resid(autoarima_trm), type="Ljung-Box")
# ARIMA(0,1,1)

# DTF
subdata$d_DTF <- c(NA, diff(subdata$dtf_nivel))

par(mfrow=c(1,2))
acf(na.omit(subdata$d_DTF), main="ACF ΔDTF")
pacf(na.omit(subdata$d_DTF), main="PACF ΔDTF")
# ARMA(1,1) o AR(2,1)
subdata$lag1_dDTF <- dplyr::lag(subdata$d_DTF, 1)

ar1_dDTF <- lm(d_DTF ~ lag1_dDTF, data=subdata)
summary(ar1_dDTF)
acf(resid(ar1_dDTF))
Box.test(resid(ar1_dDTF), type="Ljung-Box")
autoarima_dDTF <- auto.arima(na.omit(subdata$d_DTF))
summary(autoarima_dDTF)

checkresiduals(autoarima_dDTF)
Box.test(resid(autoarima_dDTF), type="Ljung-Box")
#ARIMA(1,1,1) sin autocorrelación en los residuos, es decir, ruido blanco
# Inflación
subdata$d_INF <- c(NA, diff(subdata$inflacion_diff))
d_INF_clean <- na.omit(subdata$d_INF)
par(mfrow=c(1,2))
acf(d_INF_clean, main="ACF Δ Inflación anual")
pacf(d_INF_clean, main="PACF Δ Inflación anual")
# MA(2)
subdata$lag1_dINF <- dplyr::lag(subdata$d_INF, 1)

ar1_dINF <- lm(d_INF ~ lag1_dINF, data=subdata)
summary(ar1_dINF)
autoarima_dINF <- auto.arima(d_INF_clean)
summary(autoarima_dINF)

# MA(2)
acf(resid(ar1_dINF))
Box.test(resid(ar1_dINF), type="Ljung-Box")

checkresiduals(auto.arima(d_INF_clean))
Box.test(resid(auto.arima(d_INF_clean)), type="Ljung-Box")
# los residuos del modelo ARIMA para la inflación no muestran autocorrelación, lo que sugiere que el modelo captura adecuadamente la dinámica de la inflación anual. Esto es importante para asegurar que las inferencias y predicciones basadas en este modelo sean confiables.

# DTF
subdata$d_DTF <- c(NA, diff(subdata$dtf_nivel))
d_DTF_clean <- na.omit(subdata$d_DTF)
par(mfrow=c(1,2))
acf(d_DTF_clean, main="ACF ΔDTF")
pacf(d_DTF_clean, main="PACF ΔDTF")
# ARMA(1,1,1) o AR(2)
modelo_DTF <- auto.arima(d_DTF_clean)
modelo_DTF
# AR(1,1,1)
checkresiduals(modelo_DTF)
Box.test(resid(modelo_DTF), type="Ljung-Box")
# los residuos del modelo ARIMA para la DTF no muestran autocorrelación, lo que sugiere que el modelo captura adecuadamente la dinámica de la DTF. Esto es importante


# hay que diferenciar otra vez trm?
adf.test(subdata$delta12_log_trm)
# R/: no

source("scripts/01_packages.R")

#Datos para ADL
IPC_clean <- read_csv("data/processed/IPC_limpio.csv") %>%
  filter(year(fecha) >= 2006) %>%
  mutate(fecha = floor_date(fecha, "month")) %>%
  arrange(fecha)

TRM_clean <- read_rds("data/processed/TRM_limpia.rds") %>%
  filter(year(Fecha) >= 2006) %>%
  mutate(fecha = floor_date(Fecha, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, delta12_log_trm = TRM_log)

CDT_clean <- read_excel("data/processed/CDT_limpia.xlsx") %>%
  mutate(fecha_raw = as.Date(as.numeric(Fecha), origin = "1899-12-30")) %>%
  filter(!is.na(fecha_raw) & year(fecha_raw) >= 2006) %>%
  mutate(fecha = floor_date(fecha_raw, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, dtf_nivel = 2)

indicadores <- read_excel("data/processed/anex-ISE-9actividades-nov2025-limpia.xlsx",
                          sheet = "indicadores") %>%
  filter(year(fecha) >= 2006) %>%
  mutate(fecha = floor_date(fecha, "month")) %>%
  arrange(fecha) %>%
  dplyr::select(fecha, ise_dae_log = ISE_dae_log, ise_dae_T_log = ISE_dae_T_log)

#Unificar las bases de datos por fecha y calcular Δ12 log TRM

datos <- IPC_clean %>%
  dplyr::select(fecha, inflacion_anual = ipc_log_cambio) %>%
  left_join(TRM_clean, by = "fecha") %>%
  left_join(CDT_clean, by = "fecha") %>%
  left_join(indicadores, by = "fecha") %>%
  dplyr::select(fecha, inflacion_anual, dtf_nivel, delta12_log_trm, ise_dae_log, ise_dae_T_log) %>%
  arrange(fecha) 

# ==============================================================================
# CREAR SUBDATA PARA PRUEBAS DEL MODELO
# ==============================================================================
# Subdata desde 2006-01 hasta 2025-01 para pruebas del modelo

subdata <- datos %>%
  filter(fecha >= as.Date("2006-01-01") & fecha <= as.Date("2025-01-31"))

# Determinamos si son o no estacionarias utilizando el test DF
plot.ts(subdata[, c("inflacion_anual", "dtf_nivel", "delta12_log_trm", "ise_dae_log", "ise_dae_T_log")])

############################################
# DF
############################################

############################################
# Inflación anual como logΔ12 IPC
############################################

DF.inflacion <- ur.df(subdata$inflacion_anual, type = "trend", selectlags = "AIC")
summary(DF.inflacion)
DF.inflacion_D<- ur.df(subdata$inflacion_anual, type = "drift", selectlags = "AIC")
summary(DF.inflacion_D)
# Apesar de no tener intercepto significativo se deja ya que en macro aplicada la inflación no se elimina el intercepto
summary(
  ur.df(subdata$inflacion_anual,
        type = "drift",
        selectlags = "AIC")
)

# es I(1)
#Tiene persistencia fuerte - Los shocks no se disipan inmediatamente -Hay memoria en la dinámica inflacionaria
#Eso es bastante coherente con economías como Colombia.
subdata$inflacion_diff <- c(NA, diff(subdata$inflacion_anual))
############################################
# DTF
############################################
DF.dtf <- ur.df(subdata$dtf_nivel, type = "trend", selectlags = "AIC")
summary(DF.dtf)
DF.dtf_D <- ur.df(subdata$dtf_nivel, type = "drift", selectlags = "AIC")
summary(DF.dtf_D)
# no bajo a none porque la DFT no osila entre el 0, siempre es positiva
summary(
  ur.df(diff(subdata$dtf_nivel),
        type="drift",
        selectlags="AIC")
)
#
subdata$dtf_diff <- c(NA, diff(subdata$dtf_nivel))

############################################
# TRM
############################################
DF.trm <- ur.df(subdata$delta12_log_trm, type = "trend", selectlags = "AIC")
summary(DF.trm)

ur.df(subdata$delta12_log_trm,
      type="drift",
      selectlags="AIC")

# es I(0) sin tendencia pero con drift, lo que es consistente con la idea de que la TRM tiene una tendencia creciente a lo largo del tiempo.

############################################
# ISE
############################################

DF.ise <- ur.df(subdata$ise_dae_log, type = "trend", selectlags = "AIC")
summary(DF.ise)
summary(
  ur.df(subdata$ise_dae_log,
        type="drift",
        selectlags="AIC")
  
)
# es I(1) con drift, lo que sugiere que el ISE tiene una tendencia creciente a lo largo del tiempo, pero no muestra evidencia de una tendencia determinista significativa.

##################################################
# ISE sector terciario
##################################################
DF.ise_T <- ur.df(subdata$ise_dae_T_log, type = "trend", selectlags = "AIC")
summary(DF.ise_T)
summary(
  ur.df(subdata$ise_dae_T_log,
        type="drift",
        selectlags="AIC")
)
# no se diferencia más, es I(0) con drift, lo que sugiere que el ISE del sector terciario tiene una tendencia creciente a lo largo del tiempo, pero no muestra evidencia de una tendencia determinista significativa.

######################
# correlogramas
#####################

# ISE
par(mfrow=c(1,2))
acf(subdata$ise_dae_log, main="ACF ISE")
pacf(subdata$ise_dae_log, main="PACF ISE")
# AR(1) o AR(2)
subdata$lag1_ISE <- dplyr::lag(subdata$ise_dae_log, 1)

ar1 <- lm(ise_dae_log ~ lag1_ISE, data = subdata)
summary(ar1)

acf(resid(ar1))
# un shock de 1 punto porcentual en hoy provoca uno de 0.84 puntos en el proximo mes
acf(resid(ar1))
Box.test(resid(ar1), type="Ljung-Box")
# segun esto es  AR(1) muy fuerte
autoarima_ise <- auto.arima(na.omit(subdata$ise_dae_log))
summary(autoarima_ise)
checkresiduals(autoarima_ise)
Box.test(resid(autoarima_ise), type="Ljung-Box")
# ARIMA(1,0,0) sin autocorrelación en los residuos,
#ISE sector terciario
par(mfrow=c(1,2))
acf(subdata$ise_dae_T_log, main="ACF ISE sector terciario")
pacf(subdata$ise_dae_T_log, main="PACF ISE sector terciario")
# AR(1) o
subdata$lag1_ISE <- dplyr::lag(subdata$ise_dae_log, 1)

ar1 <- lm(ise_dae_T_log ~ lag1_ISE, data = subdata)
summary(ar1)

acf(resid(ar1))
autoarima_ise_T <- auto.arima(na.omit(subdata$ise_dae_T_log))
summary(autoarima_ise_T)
checkresiduals(autoarima_ise_T)
Box.test(resid(autoarima_ise_T), type="Ljung-Box")

#AR(1,0,1)

# TRM
par(mfrow=c(1,2))
acf(subdata$delta12_log_trm, main="ACF Δ12 log TRM ")
pacf(subdata$delta12_log_trm, main="PACF Δ12 log TRM")
# AR(2) o AR(3)
subdata$lag1_trm <- dplyr::lag(subdata$delta12_log_trm, 2)
subdata$lag2_trm <- dplyr::lag(subdata$delta12_log_trm, 3)
ar2 <- lm(delta12_log_trm ~ lag1_trm + lag2_trm, data = subdata)
summary(ar2)
acf(resid(ar2))
Box.test(resid(ar2), type="Ljung-Box")
#AR(2) o AR(3) sin aurocorrelación en los residuos, es decir, ruido blanco
autoarima_trm <- auto.arima(na.omit(subdata$delta12_log_trm))
summary(autoarima_trm)
checkresiduals(autoarima_trm)
Box.test(resid(autoarima_trm), type="Ljung-Box")
# ARIMA(0,1,1)

# DTF
subdata$d_DTF <- c(NA, diff(subdata$dtf_nivel))

par(mfrow=c(1,2))
acf(na.omit(subdata$d_DTF), main="ACF ΔDTF")
pacf(na.omit(subdata$d_DTF), main="PACF ΔDTF")
# ARMA(1,1) o AR(2,1)
subdata$lag1_dDTF <- dplyr::lag(subdata$d_DTF, 1)

ar1_dDTF <- lm(d_DTF ~ lag1_dDTF, data=subdata)
summary(ar1_dDTF)
acf(resid(ar1_dDTF))
Box.test(resid(ar1_dDTF), type="Ljung-Box")
autoarima_dDTF <- auto.arima(na.omit(subdata$d_DTF))
summary(autoarima_dDTF)

checkresiduals(autoarima_dDTF)
Box.test(resid(autoarima_dDTF), type="Ljung-Box")
#ARIMA(1,1,1) sin autocorrelación en los residuos, es decir, ruido blanco
# Inflación
subdata$d_INF <- c(NA, diff(subdata$inflacion_diff))
d_INF_clean <- na.omit(subdata$d_INF)
par(mfrow=c(1,2))
acf(d_INF_clean, main="ACF Δ Inflación anual")
pacf(d_INF_clean, main="PACF Δ Inflación anual")
# MA(2)
subdata$lag1_dINF <- dplyr::lag(subdata$d_INF, 1)

ar1_dINF <- lm(d_INF ~ lag1_dINF, data=subdata)
summary(ar1_dINF)
autoarima_dINF <- auto.arima(d_INF_clean)
summary(autoarima_dINF)

# MA(2)
acf(resid(ar1_dINF))
Box.test(resid(ar1_dINF), type="Ljung-Box")

checkresiduals(auto.arima(d_INF_clean))
Box.test(resid(auto.arima(d_INF_clean)), type="Ljung-Box")
# los residuos del modelo ARIMA para la inflación no muestran autocorrelación, lo que sugiere que el modelo captura adecuadamente la dinámica de la inflación anual. Esto es importante para asegurar que las inferencias y predicciones basadas en este modelo sean confiables.

# DTF
subdata$d_DTF <- c(NA, diff(subdata$dtf_nivel))
d_DTF_clean <- na.omit(subdata$d_DTF)
par(mfrow=c(1,2))
acf(d_DTF_clean, main="ACF ΔDTF")
pacf(d_DTF_clean, main="PACF ΔDTF")
# ARMA(1,1,1) o AR(2)
modelo_DTF <- auto.arima(d_DTF_clean)
modelo_DTF
# AR(1,1,1)
checkresiduals(modelo_DTF)
Box.test(resid(modelo_DTF), type="Ljung-Box")
# los residuos del modelo ARIMA para la DTF no muestran autocorrelación, lo que sugiere que el modelo captura adecuadamente la dinámica de la DTF. Esto es importante


# hay que diferenciar otra vez trm?
adf.test(subdata$delta12_log_trm)
# R/: no



# Modelo ADL para inflación
# Incluir rezagos de la variable dependiente y de las explicativas

# ==============================================================================
# MODELOS DE REZAGOS DISTRIBUIDOS - SIGUIENDO GUJARATI
# ==============================================================================

library(dLagM)
library(lmtest)
library(dynlm)
library(tidyverse)

# ==============================================================================
# 1. PREPARAR DATOS
# ==============================================================================

datos_dlm <- subdata %>%
  dplyr::select(fecha, 
                inflacion_anual,   # Variable dependiente
                delta12_log_trm,   # I(0)
                dtf_nivel,         # I(1)
                ise_dae_log) %>%   # I(1)
  na.omit()

# ==============================================================================
# 2. MODELO DE REZAGO DISTRIBUIDO SIMPLE (DLM)
# ==============================================================================

# Modelo DLM con q rezagos (probar q=1, q=2, etc.)
dlm_trm <- dlm(formula = inflacion_anual ~ delta12_log_trm, 
               data = data.frame(datos_dlm), 
               q = 2)  # 2 rezagos de TRM
summary(dlm_trm)

# ==============================================================================
# 3. MODELO DE KOYCK
# ==============================================================================

# El modelo de Koyck asume decaimiento geométrico de los rezagos
koyck_trm <- koyckDlm(x = datos_dlm$delta12_log_trm, 
                      y = datos_dlm$inflacion_anual)
summary(koyck_trm, diagnostic = TRUE)

# Equivalente usando lm (para verificar)
koyck_lm <- lm(inflacion_anual ~ lag(inflacion_anual) + delta12_log_trm,
               data = datos_dlm)
summary(koyck_lm)

# --- DIAGNÓSTICO: Test h de Durbin ---
# H0: No autocorrelación
# Se rechaza si |h| > 1.96 o si p-valor < 0.05
h_durbin <- durbinH(koyck_lm, "lag(inflacion_anual)")
cat("\n=== TEST h DE DURBIN ===\n")
cat("h-statistic:", h_durbin, "\n")
cat("p-valor:", 2*pnorm(-abs(h_durbin)), "\n")
if(abs(h_durbin) > 1.96) {
  cat("✗ HAY autocorrelación (|h| > 1.96)\n\n")
} else {
  cat("✓ No hay evidencia de autocorrelación\n\n")
}

# --- MEDIANA DE LOS REZAGOS (Koyck) ---
# Fórmula: mediana = -log(2) / log(lambda)
# donde lambda es el coeficiente del rezago de Y
lambda <- coef(koyck_lm)["lag(inflacion_anual)"]
mediana_rezagos <- -log(2) / log(lambda)

cat("=== MEDIANA DE LOS REZAGOS (Koyck) ===\n")
cat("Lambda (coef. rezago):", lambda, "\n")
cat("Mediana de rezagos:", mediana_rezagos, "meses\n")
cat("Interpretación: 50% del efecto total se alcanza en", 
    round(mediana_rezagos, 2), "meses\n\n")

# --- MEDIA DE LOS REZAGOS (Koyck) ---
# Fórmula: media = lambda / (1 - lambda)
media_rezagos <- lambda / (1 - lambda)

cat("=== MEDIA DE LOS REZAGOS (Koyck) ===\n")
cat("Media de rezagos:", media_rezagos, "meses\n")
cat("Interpretación: Se requiere en promedio", round(media_rezagos, 2), 
    "meses para que el efecto se sienta completamente\n\n")
# "El modelo de Koyck sugiere una mediana de rezagos de 51.6 meses, lo que refleja la alta persistencia inflacionaria en Colombia (λ = 0.987). Sin embargo, este modelo impone restricciones fuertes al asumir decaimiento geométrico. Por ello, utilizamos un modelo ARDL más flexible que permite estimar libremente la estructura de rezagos."

# ==============================================================================
# 4. MODELO ADL(p,q) - AUTOREGRESSIVE DISTRIBUTED LAG
# ==============================================================================

# ADL(1,1): 1 rezago de Y, 1 rezago de X
adl_11 <- ardlDlm(formula = inflacion_anual ~ delta12_log_trm + dtf_nivel + ise_dae_log, 
                  data = data.frame(datos_dlm), 
                  p = 1,  # rezagos de Y
                  q = 1)  # rezagos de X
summary(adl_11)

# ADL(1,2): 1 rezago de Y, 2 rezagos de X
adl_12 <- ardlDlm(formula = inflacion_anual ~ delta12_log_trm + dtf_nivel + ise_dae_log, 
                  data = data.frame(datos_dlm), 
                  p = 1, 
                  q = 2)
summary(adl_12)

# ADL(2,2): 2 rezagos de Y, 2 rezagos de X
adl_22 <- ardlDlm(formula = inflacion_anual ~ delta12_log_trm + dtf_nivel + ise_dae_log, 
                  data = data.frame(datos_dlm), 
                  p = 2, 
                  q = 2)
summary(adl_22)
# el mejor es ADL(2,2) según AIC y BIC, aunque el ADL(1,2) también es competitivo. El ADL(2,2) captura mejor la dinámica de la inflación al incluir más rezagos de la variable dependiente e independiente, lo que sugiere que los efectos de las variables explicativas se distribuyen a lo largo del tiempo y que la inflación tiene una fuerte persistencia.

# ==============================================================================
# 5. SELECCIÓN AUTOMÁTICA DEL ORDEN ÓPTIMO
# ==============================================================================
modelo_ardl <- ardl(inflacion_anual ~ delta12_log_trm + dtf_nivel + ise_dae_T_log,
                    data = datos_ardl,
                    order = c(2, 2, 2, 4))  # El mejor según auto_ardl

summary(modelo_ardl)

# ==============================================================================
# 6. PREDICCIÓN CON EL MODELO ARDL
# ==============================================================================


# ==============================================================================
# 7. GRÁFICO DE PREDICCIÓN
# ==============================================================================

