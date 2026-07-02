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
  library(giscoR); library(magick)
})
dir.create("out", showWarnings = FALSE)

# --- 1. Kontur -> recorte Mallorca, en UTM 31N (25831): norte arriba ---------
kon <- st_read("data/external/kontur_ES.gpkg", quiet = TRUE)          # EPSG:3857
mall_wgs <- st_bbox(c(xmin = 2.30, ymin = 39.24, xmax = 3.50, ymax = 39.98),
                    crs = 4326) |> st_as_sfc()
bb3857 <- st_transform(mall_wgs, st_crs(kon)) |> st_bbox()
kon <- st_crop(kon, bb3857) |> st_transform(25831)
area_km2 <- as.numeric(st_area(kon[1, ])) / 1e6         # área del hexágono
cat(nrow(kon), "hexágonos ·", format(round(sum(kon$population)), big.mark = "."),
    "hab · hexàgon =", round(area_km2, 3), "km²\n")

# --- 2. Contorno de Mallorca (para rellenar la base y no dejarla mordisqueada)
mall <- gisco_get_nuts(nuts_level = 2, resolution = "01", country = "ES") |>
  filter(NUTS_ID == "ES53") |> st_transform(25831) |>
  st_crop(st_bbox(kon))

# --- 3. Rasterizar población (celda 200 m) ----------------------------------
bb <- st_bbox(kon)
tmpl <- rast(xmin = bb["xmin"], xmax = bb["xmax"], ymin = bb["ymin"],
             ymax = bb["ymax"], resolution = 200, crs = "EPSG:25831")
r_pop  <- rasterize(vect(kon),  tmpl, field = "population", fun = "max", background = NA)
r_land <- rasterize(vect(mall), tmpl, field = 1, background = NA)     # 1 = terra ferma
# base continua: dins de la costa i sense hexàgon -> 0 (silueta completa)
r_pop[is.na(r_pop) & !is.na(r_land)] <- 0
mat <- raster_to_matrix(r_pop)

# --- 4. Paleta cálida (clar = poca població, fosc = molta) — fidel a Milos ---
# tono base más oscuro (oro/tostado) para que la costa contraste con el fondo clar
pal <- c("#e6bf55", "#d99a34", "#c4632a", "#9c3f1e", "#6a2814", "#2e1006")
texture <- grDevices::colorRampPalette(pal)(256)

# --- 5. Escena 3D + pathtracing (marc apaïsat, norte arriba: theta = 0) ------
dims <- dim(mat)                                   # [files(N-S), columnes(E-O)]
# solid = TRUE -> la isla es un bloque con grosor que proyecta su silueta sencera
# (com la massa terrestre del mapa d'Alemanya), no només les ombres dels spikes.
mat |>
  height_shade(texture = texture) |>
  plot_3d(heightmap = mat, solid = TRUE, soliddepth = -600, shadowdepth = -650,
          zscale = 20, shadow = TRUE, shadow_darkness = 0.5,
          windowsize = c(1400, 1050),
          phi = 68, zoom = 0.66, theta = 0, background = "#e7e4dd")

# Luz principal (NO) + relleno suave. Con la isla sólida, proyecta una ombra
# compacta de tota la silueta sobre el pla de terra.
render_highquality(
  filename = "out/_render.png", preview = FALSE,
  light = TRUE,
  lightdirection = c(315, 120), lightaltitude = c(48, 75),
  lightintensity = c(680, 320), lightcolor = c("#fff3dd", "#ffffff"),
  interactive = FALSE, width = 1600, height = 1200, samples = 320
)
cat("render OK, componiendo títulos y leyenda...\n")

# --- 6. Título + leyenda de color (magick) ----------------------------------
maxdens <- round(max(kon$population, na.rm = TRUE) / area_km2)   # hab/km² màx
hab <- format(round(sum(kon$population)), big.mark = ".")
ff <- "DejaVu Sans"

# barra de gradiente 256px (esquerra = poc, dreta = molt)
bar <- image_read(as.raster(matrix(texture, nrow = 1))) |>
  image_resize("460x26!")

img <- image_read("out/_render.png") |>
  image_annotate("MALLORCA", size = 96, gravity = "northwest",
                 location = "+66+40", color = "#241505", font = ff, weight = 700) |>
  image_annotate("Densitat de població · spikes de 400 m (Kontur 2023)", size = 34,
                 gravity = "northwest", location = "+70+158", color = "#7a4a1e", font = ff) |>
  image_annotate(sprintf("%s habitants", hab), size = 30,
                 gravity = "northwest", location = "+70+206", color = "#9a6a2e", font = ff)

# incrustar la barra y sus etiquetas
img <- image_composite(img, bar, offset = "+70+270")
img <- img |>
  image_annotate("habitants / km²", size = 26, gravity = "northwest",
                 location = "+70+242", color = "#5a3a15", font = ff) |>
  image_annotate("0", size = 24, gravity = "northwest",
                 location = "+66+300", color = "#5a3a15", font = ff) |>
  image_annotate(format(maxdens, big.mark = "."), size = 24, gravity = "northwest",
                 location = "+486+300", color = "#5a3a15", font = ff) |>
  image_annotate("Dades: Kontur Population 2023 (derivat de cens/padró · GHSL) · estil Milos Agathon",
                 size = 22, gravity = "south", location = "+0+26", color = "#8a7a55", font = ff)

image_write(img, "out/mallorca_population_3d.png")
cat("OK -> out/mallorca_population_3d.png (màx", maxdens, "hab/km²)\n")
