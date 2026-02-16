############################################################
# 03_descriptivas.R
# Análisis Exploratorio de Datos (EDA)
############################################################
# Cargar paquetes
source("scripts/01_packages.R")

# ============================================================================
# CARGAR DATOS LIMPIOS
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("ANÁLISIS EXPLORATORIO DE DATOS (EDA) - Desde 2005\n")
cat(strrep("=", 76), "\n")

# Cargar datos limpios
TRM_clean <- read_rds("data/processed/TRM_limpia.rds")
IPC_clean <- read_csv("data/processed/IPC_limpio.csv")
CDT_clean <- read_excel("data/processed/CDT_limpia.xlsx")

# Filtrar datos desde 2005
TRM_clean <- TRM_clean %>%
  filter(year(Fecha) >= 2005)

IPC_clean <- IPC_clean %>%
  filter(year(fecha) >= 2005)

# Para CDT, intentar convertir la fecha de forma flexible
CDT_clean <- CDT_clean %>%
  mutate(Fecha_numeric = as.numeric(Fecha)) %>%
  mutate(Fecha_date = if_else(!is.na(Fecha_numeric), 
                              as.Date(Fecha_numeric, origin = "1899-12-30"),
                              as.Date(NA))) %>%
  filter(year(Fecha_date) >= 2005)

cat("\n   [1] Datos cargados exitosamente (desde 2005)\n")

# ============================================================================
# ESTADÍSTICAS DESCRIPTIVAS
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("ESTADÍSTICAS DESCRIPTIVAS\n")
cat(strrep("=", 76), "\n")

# TRM
cat("\n   TRM (Tasa Representativa del Mercado):\n")
print(summary(TRM_clean$TRM_fin_mes))

# IPC
cat("\n   IPC (Índice de Precios al Consumidor):\n")
print(summary(IPC_clean$ipc))

# CDT
cat("\n   CDT (Certificados de Depósito a Término):\n")
print(summary(CDT_clean))

# ============================================================================
# CARGAR INDICADORES (necesarios para los gráficos)
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("CARGANDO INDICADORES ECONÓMICOS\n")
cat(strrep("=", 76), "\n")

# Cargar archivo ISE con la hoja de indicadores
ISE_file <- "data/processed/anex-ISE-9actividades-nov2025-limpia.xlsx"

# Leer la hoja de indicadores
indicadores <- read_excel(ISE_file, sheet = "indicadores") %>%
  mutate(fecha = as.Date(fecha))

cat("\n   ✓ Indicadores cargados exitosamente\n")

# Filtrar desde 2005
indicadores_filtered <- indicadores %>%
  filter(year(fecha) >= 2005)

cat("   Dimensiones:", nrow(indicadores_filtered), "filas x", ncol(indicadores_filtered), "columnas\n")

# ============================================================================
# HISTOGRAMAS
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("HISTOGRAMAS\n")
cat(strrep("=", 76), "\n")

# Crear ventana gráfica con múltiples paneles
pdf("outputs/EDA/01_histogramas.pdf", width = 12, height = 8)
par(mfrow = c(2, 2))

hist(na.omit(CDT_clean[[2]]), 
     main = "Distribución DTF Promedio Mensual", 
     xlab = "DTF Promedio (%)", 
     ylab = "Frecuencia",
     col = "steelblue",
     border = "black")

hist(IPC_clean$ipc_log_cambio, 
     main = "Distribución IPC Cambio Log (%)", 
     xlab = "IPC Cambio Log (%)", 
     ylab = "Frecuencia",
     col = "darkgreen",
     border = "black")

hist(TRM_clean$TRM_promedio, 
     main = "Distribución TRM (Promedio)", 
     xlab = "TRM Promedio", 
     ylab = "Frecuencia",
     col = "coral",
     border = "black")

hist(indicadores_filtered$ISE_dae_log, 
     main = "Distribución ISE DAE (Log %)", 
     xlab = "ISE DAE (Log %)", 
     ylab = "Frecuencia",
     col = "purple",
     border = "black")

par(mfrow = c(1, 1))
dev.off()

cat("   ✓ Histogramas guardados en: outputs/EDA/01_histogramas.pdf\n")

# ============================================================================
# DENSITY PLOTS
# ============================================================================

cat("\n   Generando Density Plots...\n")

pdf("outputs/EDA/02_density_plots.pdf", width = 12, height = 8)
par(mfrow = c(2, 2))

plot(density(na.omit(CDT_clean[[2]])),
     main = "Density Plot DTF Promedio Mensual",
     xlab = "DTF Promedio (%)",
     ylab = "Densidad",
     col = "steelblue",
     lwd = 2)
polygon(density(na.omit(CDT_clean[[2]])), col = rgb(70, 130, 180, 100, maxColorValue = 255))

plot(density(na.omit(IPC_clean$ipc_log_cambio)),
     main = "Density Plot IPC Cambio Log (%)",
     xlab = "IPC Cambio Log (%)",
     ylab = "Densidad",
     col = "darkgreen",
     lwd = 2)
polygon(density(na.omit(IPC_clean$ipc_log_cambio)), col = rgb(0, 100, 0, 100, maxColorValue = 255))

plot(density(TRM_clean$TRM_promedio),
     main = "Density Plot TRM (Promedio)",
     xlab = "TRM Promedio",
     ylab = "Densidad",
     col = "coral",
     lwd = 2)
polygon(density(TRM_clean$TRM_promedio), col = rgb(255, 127, 80, 100, maxColorValue = 255))

plot(density(na.omit(indicadores_filtered$ISE_dae_log)),
     main = "Density Plot ISE DAE (Log %)",
     xlab = "ISE DAE (Log %)",
     ylab = "Densidad",
     col = "purple",
     lwd = 2)
polygon(density(na.omit(indicadores_filtered$ISE_dae_log)), col = rgb(128, 0, 128, 100, maxColorValue = 255))

par(mfrow = c(1, 1))
dev.off()

cat("   ✓ Density Plots guardados en: outputs/EDA/02_density_plots.pdf\n")

# ============================================================================
# BOXPLOTS - Usando las 4 variables principales
# ============================================================================

cat("\n   Generando Boxplots...\n")

pdf("outputs/EDA/03_boxplots.pdf", width = 14, height = 8)
par(mfrow = c(2, 2))

boxplot(na.omit(CDT_clean[[2]]),
        main = "Boxplot DTF Promedio Mensual",
        ylab = "DTF (%)",
        col = "steelblue")

boxplot(na.omit(IPC_clean$ipc_log_cambio),
        main = "Boxplot IPC Cambio Log (%)",
        ylab = "IPC Cambio Log (%)",
        col = "darkgreen")

boxplot(TRM_clean$TRM_promedio,
        main = "Boxplot TRM (Promedio)",
        ylab = "TRM Promedio",
        col = "coral")

boxplot(na.omit(indicadores_filtered$ISE_dae_log),
        main = "Boxplot ISE DAE (Log %)",
        ylab = "ISE DAE (Log %)",
        col = "purple")

par(mfrow = c(1, 1))
dev.off()

cat("   ✓ Boxplots guardados en: outputs/EDA/03_boxplots.pdf\n")

# ============================================================================
# SCATTER PLOTS - SERIES DE TIEMPO - 4 Variables principales
# ============================================================================

cat("\n   Generando Scatter Plots (Series de Tiempo)...\n")

pdf("outputs/EDA/04_scatter_plots.pdf", width = 14, height = 8)
par(mfrow = c(2, 2))

# DTF en el tiempo
plot(CDT_clean$Fecha_date, CDT_clean[[2]],
     type = "p",
     main = "DTF Promedio Mensual en el Tiempo",
     xlab = "Fecha",
     ylab = "DTF (%)",
     col = "steelblue",
     pch = 19,
     cex = 0.6)
lines(CDT_clean$Fecha_date, CDT_clean[[2]], col = "steelblue")

# IPC Cambio Log en el tiempo
plot(IPC_clean$fecha, IPC_clean$ipc_log_cambio,
     type = "p",
     main = "IPC Cambio Log (%) en el Tiempo",
     xlab = "Fecha",
     ylab = "IPC Cambio Log (%)",
     col = "darkgreen",
     pch = 19,
     cex = 0.6)
lines(IPC_clean$fecha, IPC_clean$ipc_log_cambio, col = "darkgreen")

# TRM promedio en el tiempo
plot(TRM_clean$Fecha, TRM_clean$TRM_promedio,
     type = "p",
     main = "TRM (Promedio) en el Tiempo",
     xlab = "Fecha",
     ylab = "TRM Promedio",
     col = "coral",
     pch = 19,
     cex = 0.6)
lines(TRM_clean$Fecha, TRM_clean$TRM_promedio, col = "coral")

# ISE DAE Log en el tiempo
plot(indicadores_filtered$fecha, indicadores_filtered$ISE_dae_log,
     type = "p",
     main = "ISE DAE (Log %) en el Tiempo",
     xlab = "Fecha",
     ylab = "ISE DAE (Log %)",
     col = "purple",
     pch = 19,
     cex = 0.6)
lines(indicadores_filtered$fecha, indicadores_filtered$ISE_dae_log, col = "purple")

par(mfrow = c(1, 1))
dev.off()

cat("   ✓ Scatter Plots guardados en: outputs/EDA/04_scatter_plots.pdf\n")

# ============================================================================
# DIAGRAMA DE MEDIAS CON INTERVALOS DE CONFIANZA (ggplot2)
# ============================================================================

cat("\n   Generando Diagramas de Medias con IC al 95%...\n")

TRM_clean <- TRM_clean %>%
  mutate(anio = year(Fecha))

IPC_clean <- IPC_clean %>%
  mutate(anio = year(fecha))

CDT_clean <- CDT_clean %>%
  mutate(anio = year(Fecha_date))

indicadores_filtered <- indicadores_filtered %>%
  mutate(anio = year(fecha))

# Función para calcular media e IC al 95% (±1.96 * SE)
calcular_ic <- function(x) {
  media <- mean(x, na.rm = TRUE)
  se <- sd(x, na.rm = TRUE) / sqrt(length(na.omit(x)))
  ic_inferior <- media - 1.96 * se
  ic_superior <- media + 1.96 * se
  
  data.frame(
    media = media,
    ic_inferior = ic_inferior,
    ic_superior = ic_superior
  )
}

# Calcular estadísticas para DTF por año
DTF_stats <- CDT_clean %>%
  group_by(anio) %>%
  do(calcular_ic(.[[2]]))

# Calcular estadísticas para IPC Cambio Log por año
IPC_log_stats <- IPC_clean %>%
  group_by(anio) %>%
  do(calcular_ic(.$ipc_log_cambio))

# Calcular estadísticas para TRM promedio por año
TRM_promedio_stats <- TRM_clean %>%
  group_by(anio) %>%
  do(calcular_ic(.$TRM_promedio))

# Calcular estadísticas para ISE DAE Log por año
ISE_dae_log_stats <- indicadores_filtered %>%
  group_by(anio) %>%
  do(calcular_ic(.$ISE_dae_log))

# Plot DTF Promedio
p1 <- ggplot(DTF_stats, aes(x = factor(anio), y = media)) +
  geom_point(color = "steelblue", size = 3) +
  geom_errorbar(aes(ymin = ic_inferior, ymax = ic_superior), 
                color = "steelblue", width = 0.3, linewidth = 1) +
  geom_line(aes(group = 1), color = "steelblue", linewidth = 1) +
  labs(title = "Media DTF Promedio Mensual por Año",
       subtitle = "Intervalos de confianza al 95% (±1.96*SE)",
       x = "Año",
       y = "DTF (%)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/EDA/05_mean_plot_DTF.pdf", p1, width = 10, height = 6)

# Plot IPC Cambio Log
p2 <- ggplot(IPC_log_stats, aes(x = factor(anio), y = media)) +
  geom_point(color = "darkgreen", size = 3) +
  geom_errorbar(aes(ymin = ic_inferior, ymax = ic_superior), 
                color = "darkgreen", width = 0.3, linewidth = 1) +
  geom_line(aes(group = 1), color = "darkgreen", linewidth = 1) +
  labs(title = "Media IPC Cambio Log (%) por Año",
       subtitle = "Intervalos de confianza al 95% (±1.96*SE)",
       x = "Año",
       y = "IPC Cambio Log (%)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/EDA/05_mean_plot_IPC_log.pdf", p2, width = 10, height = 6)

# Plot TRM Promedio
p3 <- ggplot(TRM_promedio_stats, aes(x = factor(anio), y = media)) +
  geom_point(color = "coral", size = 3) +
  geom_errorbar(aes(ymin = ic_inferior, ymax = ic_superior), 
                color = "coral", width = 0.3, linewidth = 1) +
  geom_line(aes(group = 1), color = "coral", linewidth = 1) +
  labs(title = "Media TRM Promedio por Año",
       subtitle = "Intervalos de confianza al 95% (±1.96*SE)",
       x = "Año",
       y = "TRM Promedio") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/EDA/05_mean_plot_TRM_promedio.pdf", p3, width = 10, height = 6)

# Plot ISE DAE Log
p4 <- ggplot(ISE_dae_log_stats, aes(x = factor(anio), y = media)) +
  geom_point(color = "purple", size = 3) +
  geom_errorbar(aes(ymin = ic_inferior, ymax = ic_superior), 
                color = "purple", width = 0.3, linewidth = 1) +
  geom_line(aes(group = 1), color = "purple", linewidth = 1) +
  labs(title = "Media ISE DAE (Log %) por Año",
       subtitle = "Intervalos de confianza al 95% (±1.96*SE)",
       x = "Año",
       y = "ISE DAE (Log %)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/EDA/05_mean_plot_ISE_dae_log.pdf", p4, width = 10, height = 6)

cat("   ✓ Diagramas de Medias guardados en: outputs/EDA/05_mean_plot_*.pdf\n")

# ============================================================================
# ANÁLISIS AGRUPADO
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("ANÁLISIS AGRUPADO POR AÑO\n")
cat(strrep("=", 76), "\n")

# Análisis agrupado TRM
cat("\n   TRM por Año:\n")
TRM_summary <- TRM_clean %>%
  group_by(anio) %>%
  summarise(
    Media = mean(TRM_fin_mes, na.rm = TRUE),
    Mediana = median(TRM_fin_mes, na.rm = TRUE),
    Desv.Est = sd(TRM_fin_mes, na.rm = TRUE),
    Mínimo = min(TRM_fin_mes, na.rm = TRUE),
    Máximo = max(TRM_fin_mes, na.rm = TRUE),
    .groups = 'drop'
  )
print(TRM_summary)

# Análisis agrupado IPC
cat("\n   IPC por Año:\n")
IPC_summary <- IPC_clean %>%
  group_by(anio) %>%
  summarise(
    Media = mean(ipc, na.rm = TRUE),
    Mediana = median(ipc, na.rm = TRUE),
    Desv.Est = sd(ipc, na.rm = TRUE),
    Mínimo = min(ipc, na.rm = TRUE),
    Máximo = max(ipc, na.rm = TRUE),
    .groups = 'drop'
  )
print(IPC_summary)

# ============================================================================
# ANÁLISIS INDICADORES ECONÓMICOS (ISE)
# ============================================================================

cat("\n", strrep("=", 76), "\n")
cat("ANÁLISIS INDICADORES ECONÓMICOS\n")
cat(strrep("=", 76), "\n")

# Cargar archivo ISE con la hoja de indicadores
ISE_file <- "data/processed/anex-ISE-9actividades-nov2025-limpia.xlsx"

# Leer la hoja de indicadores
indicadores <- read_excel(ISE_file, sheet = "indicadores") %>%
  mutate(fecha = as.Date(fecha))

cat("\n   ✓ Indicadores cargados exitosamente\n")

# Filtrar desde 2005
indicadores_filtered <- indicadores %>%
  filter(year(fecha) >= 2005)

cat("   Dimensiones:", nrow(indicadores_filtered), "filas x", ncol(indicadores_filtered), "columnas\n")

# Estadísticas descriptivas de los indicadores
cat("\n", strrep("=", 76), "\n")
cat("ESTADÍSTICAS DESCRIPTIVAS - INDICADORES\n")
cat(strrep("=", 76), "\n")

for (col in names(indicadores_filtered)[2:ncol(indicadores_filtered)]) {
  cat("\n   ", col, ":\n")
  print(summary(indicadores_filtered[[col]]))
}

# ============================================================================
# GRÁFICOS DE SERIES DE TIEMPO - INDICADORES ECONÓMICOS
# ============================================================================

cat("\n   Generando gráficos de series de tiempo...\n")

# ISE Demanda Ocupada (Nivel)
p_ise_do <- ggplot(indicadores_filtered, aes(x = fecha)) +
  geom_line(aes(y = ISE_do, color = "ISE_do"), size = 1) +
  geom_line(aes(y = ISE_do_T, color = "ISE_do_T (Terciario)"), size = 1) +
  scale_color_manual(values = c("ISE_do" = "red", "ISE_do_T (Terciario)" = "darkblue")) +
  labs(title = "ISE - Demanda Ocupada (Nivel)",
       x = "Fecha",
       y = "Índice") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave("outputs/EDA/07_ISE_DO_nivel.pdf", p_ise_do, width = 12, height = 6)
cat("      ✓ Gráfico: outputs/EDA/07_ISE_DO_nivel.pdf\n")

# ISE Demanda Ocupada (Log - %)
p_ise_do_log <- ggplot(indicadores_filtered, aes(x = fecha)) +
  geom_line(aes(y = ISE_do_log, color = "ISE_do_log (%)"), size = 1) +
  geom_line(aes(y = ISE_do_T_log, color = "ISE_do_T_log (%) (Terciario)"), size = 1) +
  scale_color_manual(values = c("ISE_do_log (%)" = "red", "ISE_do_T_log (%) (Terciario)" = "darkblue")) +
  geom_hline(yintercept = 0, color = "gray", linetype = "dotted") +
  labs(title = "ISE - Demanda Ocupada (Cambio Log %)",
       x = "Fecha",
       y = "Cambio (%)") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave("outputs/EDA/07_ISE_DO_log.pdf", p_ise_do_log, width = 12, height = 6)
cat("      ✓ Gráfico: outputs/EDA/07_ISE_DO_log.pdf\n")

# ISE Demanda Agregada (Nivel)
p_ise_dae <- ggplot(indicadores_filtered, aes(x = fecha)) +
  geom_line(aes(y = ISE_dae, color = "ISE_dae"), size = 1) +
  geom_line(aes(y = ISE_dae_T, color = "ISE_dae_T (Terciario)"), size = 1) +
  scale_color_manual(values = c("ISE_dae" = "red", "ISE_dae_T (Terciario)" = "darkblue")) +
  labs(title = "ISE - Demanda Agregada (Nivel)",
       x = "Fecha",
       y = "Índice") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave("outputs/EDA/07_ISE_DAE_nivel.pdf", p_ise_dae, width = 12, height = 6)
cat("      ✓ Gráfico: outputs/EDA/07_ISE_DAE_nivel.pdf\n")

# ISE Demanda Agregada (Log - %)
p_ise_dae_log <- ggplot(indicadores_filtered, aes(x = fecha)) +
  geom_line(aes(y = ISE_dae_log, color = "ISE_dae_log (%)"), size = 1) +
  geom_line(aes(y = ISE_dae_T_log, color = "ISE_dae_T_log (%) (Terciario)"), size = 1) +
  scale_color_manual(values = c("ISE_dae_log (%)" = "red", "ISE_dae_T_log (%) (Terciario)" = "darkblue")) +
  geom_hline(yintercept = 0, color = "gray", linetype = "dotted") +
  labs(title = "ISE - Demanda Agregada (Cambio Log %)",
       x = "Fecha",
       y = "Cambio (%)") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave("outputs/EDA/07_ISE_DAE_log.pdf", p_ise_dae_log, width = 12, height = 6)
cat("      ✓ Gráfico: outputs/EDA/07_ISE_DAE_log.pdf\n")

# ISE Ciclo Tendencia (Nivel)
p_ise_ct <- ggplot(indicadores_filtered, aes(x = fecha)) +
  geom_line(aes(y = ISE_ct, color = "ISE_ct"), size = 1) +
  geom_line(aes(y = ISE_ct_T, color = "ISE_ct_T (Terciario)"), size = 1) +
  scale_color_manual(values = c("ISE_ct" = "red", "ISE_ct_T (Terciario)" = "darkblue")) +
  labs(title = "ISE - Ciclo Tendencia (Nivel)",
       x = "Fecha",
       y = "Índice") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave("outputs/EDA/07_ISE_CT_nivel.pdf", p_ise_ct, width = 12, height = 6)
cat("      ✓ Gráfico: outputs/EDA/07_ISE_CT_nivel.pdf\n")

# ISE Ciclo Tendencia (Log - %)
p_ise_ct_log <- ggplot(indicadores_filtered, aes(x = fecha)) +
  geom_line(aes(y = ISE_ct_log, color = "ISE_ct_log (%)"), size = 1) +
  geom_line(aes(y = ISE_ct_T_log, color = "ISE_ct_T_log (%) (Terciario)"), size = 1) +
  scale_color_manual(values = c("ISE_ct_log (%)" = "red", "ISE_ct_T_log (%) (Terciario)" = "darkblue")) +
  geom_hline(yintercept = 0, color = "gray", linetype = "dotted") +
  labs(title = "ISE - Ciclo Tendencia (Cambio Log %)",
       x = "Fecha",
       y = "Cambio (%)") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave("outputs/EDA/07_ISE_CT_log.pdf", p_ise_ct_log, width = 12, height = 6)
cat("      ✓ Gráfico: outputs/EDA/07_ISE_CT_log.pdf\n")

# Gráfico comparativo de niveles
p_comparativo_nivel <- ggplot(indicadores_filtered, aes(x = fecha)) +
  geom_line(aes(y = ISE_do, color = "DO"), size = 1) +
  geom_line(aes(y = ISE_dae, color = "DAE"), size = 1) +
  geom_line(aes(y = ISE_ct, color = "Ciclo Tendencia"), size = 1) +
  scale_color_manual(values = c("DO" = "red", "DAE" = "orange", "Ciclo Tendencia" = "purple")) +
  labs(title = "Comparativo - ISE Nivel",
       x = "Fecha",
       y = "Índice") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave("outputs/EDA/07_ISE_comparativo_nivel.pdf", p_comparativo_nivel, width = 12, height = 6)
cat("      ✓ Gráfico: outputs/EDA/07_ISE_comparativo_nivel.pdf\n")

# Gráfico comparativo de cambios log
p_comparativo_log <- ggplot(indicadores_filtered, aes(x = fecha)) +
  geom_line(aes(y = ISE_do_log, color = "DO (%)"), size = 1) +
  geom_line(aes(y = ISE_dae_log, color = "DAE (%)"), size = 1) +
  geom_line(aes(y = ISE_ct_log, color = "Ciclo Tendencia (%)"), size = 1) +
  scale_color_manual(values = c("DO (%)" = "red", "DAE (%)" = "orange", "Ciclo Tendencia (%)" = "purple")) +
  geom_hline(yintercept = 0, color = "gray", linetype = "dotted") +
  labs(title = "Comparativo - ISE Cambio Log (%)",
       x = "Fecha",
       y = "Cambio (%)") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

ggsave("outputs/EDA/07_ISE_comparativo_log.pdf", p_comparativo_log, width = 12, height = 6)
cat("      ✓ Gráfico: outputs/EDA/07_ISE_comparativo_log.pdf\n")

cat("\n", strrep("=", 76), "\n")
cat("✓ ANÁLISIS EXPLORATORIO COMPLETADO\n")
cat(strrep("=", 76), "\n\n")