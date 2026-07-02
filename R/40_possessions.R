#!/usr/bin/env Rscript
# ============================================================================
# LES POSSESSIONS DE MALLORCA — retrato de las 16.031 fincas/possessions del
# NGIB sobre el relieve sombreado de la isla. Estilo Milos Agathon (2D).
# Salida: out/possessions_mallorca.png
# ============================================================================
suppressPackageStartupMessages({
  library(sf); library(terra); library(elevatr); library(giscoR)
  library(ggplot2); library(dplyr)
})
dir.create("out", showWarnings = FALSE)

# --- Contorno de Mallorca ---------------------------------------------------
bbox <- st_bbox(c(xmin = 437000, ymin = 4338000, xmax = 547000, ymax = 4422000),
                crs = 25831)
bal <- gisco_get_nuts(nuts_level = 2, resolution = "01", country = "ES") |>
  filter(NUTS_ID == "ES53") |> st_transform(25831)
mallorca <- st_crop(bal, bbox)

# --- Relieve sombreado de fondo (sutil) -------------------------------------
dem <- get_elev_raster(st_as_sf(st_as_sfc(bbox)), z = 9, clip = "bbox") |> rast()
dem <- mask(crop(dem, vect(mallorca)), vect(mallorca)); dem[dem < 0] <- 0
hs <- shade(terrain(dem, "slope", unit = "radians"),
            terrain(dem, "aspect", unit = "radians"), angle = 45, direction = 315)
hs_df <- as.data.frame(hs, xy = TRUE); names(hs_df)[3] <- "hs"

# --- Possessions (16.031) ---------------------------------------------------
poss <- st_read("data/processed/ngib_possessions.gpkg", quiet = TRUE) |>
  st_transform(25831) |> st_filter(mallorca)
xy <- st_coordinates(poss) |> as.data.frame()
cat(nrow(xy), "possessions en Mallorca\n")

# --- Plot (estética nocturna, puntos luminosos) -----------------------------
bg <- "#0e1826"
p <- ggplot() +
  # relieve tenue para dar cuerpo a la isla
  geom_raster(data = hs_df, aes(x, y, alpha = hs), fill = "#9fb3c8") +
  scale_alpha(range = c(0, 0.28), guide = "none") +
  geom_sf(data = mallorca, fill = NA, colour = "#33506e", linewidth = 0.4) +
  # doble capa de puntos: halo suave + núcleo brillante
  geom_point(data = xy, aes(X, Y), colour = "#f2b705", size = 1.1,
             alpha = 0.12, stroke = 0) +
  geom_point(data = xy, aes(X, Y), colour = "#ffe9a8", size = 0.35,
             alpha = 0.9, stroke = 0) +
  coord_sf(crs = 25831, expand = FALSE) +
  labs(title = "LES POSSESSIONS DE MALLORCA",
       subtitle = sprintf("%s finques i possessions del Nomenclàtor Geogràfic de les Illes Balears",
                          format(nrow(xy), big.mark = ".")),
       caption = "Dades: NGIB (ICGIB) · MDE: AWS Terrain (elevatr)") +
  theme_void(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 32, hjust = 0.02,
                                  colour = "#ffe9a8"),
        plot.subtitle = element_text(size = 12, hjust = 0.02, colour = "#9fb3c8"),
        plot.caption = element_text(colour = "#5f7791"),
        plot.background = element_rect(fill = bg, colour = NA),
        plot.margin = margin(16, 16, 12, 16))

ggsave("out/possessions_mallorca.png", p, width = 12, height = 9, dpi = 300, bg = bg)
cat("OK -> out/possessions_mallorca.png\n")
