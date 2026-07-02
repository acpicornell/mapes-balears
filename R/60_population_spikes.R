#!/usr/bin/env Rscript
# ============================================================================
# MALLORCA — mapa 3D de "spikes" de densidad de población, estilo Milos Agathon
# (el de Egipto/Alemania). Datos: Kontur Population 2023 (hexágonos H3 400 m).
# Técnica: rasterizar población -> height_shade -> plot_3d -> render_highquality.
# Headless: options(rgl.useNULL=TRUE) + rayrender (pathtracing CPU, sin GPU).
# Salida: out/mallorca_population_3d.png
# ============================================================================
options(rgl.useNULL = TRUE)
suppressPackageStartupMessages({
  library(sf); library(terra); library(rayshader); library(dplyr)
})
dir.create("out", showWarnings = FALSE)

# --- 1. Kontur -> recorte Mallorca, proyección equal-area (ETRS89-LAEA 3035) -
kon <- st_read("data/external/kontur_ES.gpkg", quiet = TRUE)          # EPSG:3857
mall_wgs <- st_bbox(c(xmin = 2.28, ymin = 39.24, xmax = 3.52, ymax = 39.99),
                    crs = 4326) |> st_as_sfc()
bb3857 <- st_transform(mall_wgs, st_crs(kon)) |> st_bbox()
kon <- st_crop(kon, bb3857) |> st_transform(3035)
cat(nrow(kon), "hexágonos en Mallorca · población total:",
    format(round(sum(kon$population)), big.mark = "."), "\n")

# --- 2. Rasterizar (celda ~200 m: más fina que el hexágono -> spikes nítidos)-
bb <- st_bbox(kon)
tmpl <- rast(xmin = bb["xmin"], xmax = bb["xmax"], ymin = bb["ymin"],
             ymax = bb["ymax"], resolution = 200, crs = "EPSG:3035")
# background = NA -> las celdas sin hexágono (mar) quedan vacías, no una losa
r <- rasterize(vect(kon), tmpl, field = "population", fun = "max", background = NA)
mat <- raster_to_matrix(r)

# --- 3. Paleta de Milos (morado profundo -> magenta) ------------------------
pal <- rev(c("#0b1354", "#283680", "#6853a9", "#c863b3"))
texture <- grDevices::colorRampPalette(pal)(256)

# --- 4. Escena 3D + pathtracing --------------------------------------------
mat |>
  height_shade(texture = texture) |>
  plot_3d(heightmap = mat, solid = FALSE, soliddepth = 0, zscale = 25,
          shadowdepth = 0, shadow_darkness = 0.95, windowsize = c(900, 900),
          phi = 60, zoom = 0.62, theta = -25, background = "white")

render_highquality(
  filename = "out/mallorca_population_3d.png", preview = FALSE,
  light = TRUE, lightdirection = 225, lightaltitude = 60, lightintensity = 480,
  interactive = FALSE, width = 1400, height = 1400, samples = 220
)
cat("render OK, añadiendo títulos...\n")

# --- 5. Titulado editorial (magick) ----------------------------------------
suppressPackageStartupMessages(library(magick))
hab <- format(round(sum(kon$population)), big.mark = ".")
img <- image_read("out/mallorca_population_3d.png")
img |>
  image_annotate("MALLORCA", size = 96, gravity = "northwest",
                 location = "+70+50", color = "#2b1a4a",
                 font = "DejaVu Sans", weight = 700) |>
  image_annotate("Densitat de població — spikes de 400 m", size = 40,
                 gravity = "northwest", location = "+74+165", color = "#6853a9") |>
  image_annotate(sprintf("%s habitants", hab), size = 34,
                 gravity = "northwest", location = "+74+220", color = "#8a7bb0") |>
  image_annotate("Dades: Kontur Population 2023 (derivat de cens/padró · GHSL) · estil Milos Agathon",
                 size = 26, gravity = "south", location = "+0+40", color = "#9a8fb5") |>
  image_write("out/mallorca_population_3d.png")
cat("OK -> out/mallorca_population_3d.png\n")
