#!/usr/bin/env Rscript
# ============================================================================
# Mapa de DENSIDAD de topónimos del NGIB sobre las Illes Balears (hexbin).
# ¿Dónde hay más "lugares con nombre"? Estilo Milos Agathon (2D, headless-safe).
# Salida: out/baleares_densidad_toponimos.png
# ============================================================================
suppressPackageStartupMessages({
  library(sf); library(ggplot2); library(dplyr); library(giscoR); library(MetBrewer)
})
dir.create("out", showWarnings = FALSE)

bal <- gisco_get_nuts(nuts_level = 2, resolution = "01", country = "ES") |>
  filter(NUTS_ID == "ES53") |> st_transform(25831)

llocs <- st_read("data/processed/ngib_llocs.gpkg", quiet = TRUE) |> st_transform(25831)
xy <- st_coordinates(llocs) |> as.data.frame()

p <- ggplot() +
  geom_sf(data = bal, fill = "grey12", colour = NA) +
  stat_bin_hex(data = xy, aes(X, Y), bins = 90) +
  scale_fill_gradientn(colours = met.brewer("Hiroshige", direction = -1),
                       trans = "log10", name = "Topónimos\n(escala log)") +
  coord_sf(crs = 25831, expand = FALSE) +
  labs(title = "LA DENSIDAD DE LOS NOMBRES",
       subtitle = sprintf("%s topónimos del Nomenclàtor Geogràfic de les Illes Balears",
                          format(nrow(llocs), big.mark = ".")),
       caption = "Datos: NGIB (ICGIB) · ideib.caib.es") +
  theme_void(base_size = 13) +
  theme(legend.position = c(0.92, 0.3),
        plot.title = element_text(face = "bold", size = 26, hjust = 0.02, colour = "#1b3a4b"),
        plot.background = element_rect(fill = "#faf7f2", colour = NA))

ggsave("out/baleares_densidad_toponimos.png", p, width = 12, height = 8, dpi = 300, bg = "#faf7f2")
cat("OK -> out/baleares_densidad_toponimos.png\n")
