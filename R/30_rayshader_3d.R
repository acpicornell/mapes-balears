#!/usr/bin/env Rscript
# ============================================================================
# Mapa 3D de relieve de MALLORCA con rayshader — el estilo "marca de la casa"
# de Milos Agathon. Requiere OpenGL/rgl (entorno con display o software render).
# Salida: out/mallorca_3d.png
#
# NOTA: en un servidor headless necesitas xvfb-run:
#   xvfb-run -a Rscript R/30_rayshader_3d.R
# ============================================================================
suppressPackageStartupMessages({
  library(sf); library(terra); library(elevatr); library(giscoR); library(rayshader)
})
dir.create("out", showWarnings = FALSE)

bal <- gisco_get_nuts(nuts_level = 2, resolution = "01", country = "ES") |>
  subset(NUTS_ID == "ES53") |> st_transform(25831)
bbox <- st_bbox(c(xmin = 440000, ymin = 4340000, xmax = 545000, ymax = 4420000), crs = 25831)

dem <- get_elev_raster(st_as_sf(st_as_sfc(bbox)), z = 11, clip = "bbox") |> rast()
dem[dem < 0] <- 0
mat <- raster_to_matrix(dem)

# Paleta de elevación estilo Milos
pal <- colorRampPalette(c("#2a5a3e", "#7fae6f", "#e8dCa0", "#c98a5e", "#f2f2f2"))(256)

mat |>
  height_shade(texture = pal) |>
  add_shadow(ray_shade(mat, zscale = 8, sunaltitude = 40, sunangle = 315), 0.3) |>
  add_shadow(ambient_shade(mat), 0.1) |>
  plot_3d(mat, zscale = 8, solid = FALSE, shadowdepth = 0,
          windowsize = c(1400, 1000), phi = 40, theta = 25, zoom = 0.7,
          background = "#f4efe6")

render_highquality("out/mallorca_3d.png", samples = 300,
                   lightdirection = 315, lightaltitude = 45,
                   width = 1400, height = 1000, interactive = FALSE)
cat("OK -> out/mallorca_3d.png\n")
