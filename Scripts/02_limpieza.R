# Reto 1 - Haciendo Macroeconomía
# Limpieza inicial de datos

rm(list = ls())

# código acá
library (tidyverse)
library (readxl)
TRM_c<- read_excel("Datos/TRM.xlsx")
#eliminar segunda fila poscision 1
TRM_c<- TRM_c[-1,]
#renombrar columnas
colnames(TRM_c)<- c("Fecha", "TRM fin de mes", "TRM promedio")
#convertir a formato fecha formato day/month/year y que no haya erorr en la fecha por el espacio entre el mes y el año
TRM_c$Fecha<- as.Date(TRM_c$Fecha, format = "%d/%m/%Y")
# eliminar datos que son "-" 
TRM_c<- TRM_c %>% filter(`TRM fin de mes` != "-")

# quitar puntos de miles y cambiar las comas por punto
TRM_c$`TRM fin de mes`<- gsub("\\.", "", TRM_c$`TRM fin de mes`)
TRM_c$`TRM fin de mes`<- gsub(",", ".", TRM_c$`TRM fin de mes`)
TRM_c$`TRM promedio`<- gsub("\\.", "", TRM_c$`TRM promedio`)
TRM_c$`TRM promedio`<- gsub(",", ".", TRM_c$`TRM promedio`)
# convertir a formato numérico
TRM_c$`TRM fin de mes`<- as.numeric(TRM_c$`TRM fin de mes`)
TRM_c$`TRM promedio`<- as.numeric(TRM_c$`TRM promedio`)
# ordenar por fecha
TRM_c<- TRM_c %>% arrange(Fecha)
#graficar TRM fin de mes
ggplot(TRM_c, aes(x = Fecha, y = `TRM fin de mes`)) +
  geom_line() +
  labs(title = "TRM fin de mes", x = "Fecha", y = "TRM fin de mes") +
  theme_minimal()
#Graficar TRM promedio
ggplot(TRM_c, aes(x = Fecha, y = `TRM promedio`)) +
  geom_line() +
  labs(title = "TRM promedio", x = "Fecha", y = "TRM promedio") +
  theme_minimal()

# Graficar ambas TRM en el mismo gráfico
TRM_c_long <- TRM_c %>% 
  pivot_longer(
    cols = c(`TRM fin de mes`, `TRM promedio`),
    names_to = "Tipo_TRM",
    values_to = "Valor_TRM"
  )

ggplot(TRM_c_long, aes(x = Fecha, y = Valor_TRM, color = Tipo_TRM)) +
  geom_line() +
  labs(
    title = "TRM fin de mes y TRM promedio",
    x = "Fecha",
    y = "Valor TRM"
  ) +
  scale_color_manual(
    values = c("blue", "red"),
    labels = c("TRM\nfin de mes", "TRM promedio")
  ) +
  theme_minimal() +
  theme(legend.title = element_blank())
# se ve que casi no hay cambios asi que se puede usar cualquiera de las dos TRM para el análisis, se usará la TRM promedio para el análisis
# guardar el dataset limpio
write_csv(TRM_c, "Datos/TRM_limpia.csv")



                                       
                                       
                                       
                              


