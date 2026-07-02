#!/usr/bin/env Rscript
# ============================================================================
# MALLORCA — 3D "spikes" map of population density, Milos Agathon style
# (the Egypt/Germany one). Data: Kontur Population 2023 (H3 400 m hexagons).
# Technique: rasterize population -> height_shade -> plot_3d -> render_highquality.
# Headless: options(rgl.useNULL=TRUE) + rayrender (CPU pathtracing, no GPU).
# Output: out/mallorca_population_3d.png
# ============================================================================
options(rgl.useNULL = TRUE)
suppressPackageStartupMessages({
  library(sf); library(terra); library(rayshader); library(dplyr)
  library(giscoR); library(magick)
})
dir.create("out", showWarnings = FALSE)

# --- 1. Kontur -> crop to Mallorca, in UTM 31N (25831): north up -------------
kon <- st_read("data/external/kontur_ES.gpkg", quiet = TRUE)          # EPSG:3857
mall_wgs <- st_bbox(c(xmin = 2.30, ymin = 39.24, xmax = 3.50, ymax = 39.98),
                    crs = 4326) |> st_as_sfc()
bb3857 <- st_transform(mall_wgs, st_crs(kon)) |> st_bbox()
kon <- st_crop(kon, bb3857) |> st_transform(25831)
area_km2 <- as.numeric(st_area(kon[1, ])) / 1e6         # hexagon area
cat(nrow(kon), "hexagons ·", format(round(sum(kon$population)), big.mark = "."),
    "inhab · hexagon =", round(area_km2, 3), "km²\n")

# --- 2. Mallorca outline (to fill the base and not leave it chewed up) -------
mall <- gisco_get_nuts(nuts_level = 2, resolution = "01", country = "ES") |>
  filter(NUTS_ID == "ES53") |> st_transform(25831) |>
  st_crop(st_bbox(kon))

# --- 3. Rasterize population (200 m cell) ------------------------------------
bb <- st_bbox(kon)
tmpl <- rast(xmin = bb["xmin"], xmax = bb["xmax"], ymin = bb["ymin"],
             ymax = bb["ymax"], resolution = 200, crs = "EPSG:25831")
r_pop  <- rasterize(vect(kon),  tmpl, field = "population", fun = "max", background = NA)
r_land <- rasterize(vect(mall), tmpl, field = 1, background = NA)     # 1 = dry land
# continuous base: inside the coast and without a hexagon -> 0 (full silhouette)
r_pop[is.na(r_pop) & !is.na(r_land)] <- 0
mat <- raster_to_matrix(r_pop)

# --- 4. Warm palette (light = low population, dark = high) — faithful to Milos
# darker base tone (gold/toasted) so the coast contrasts with the light background
pal <- c("#e6bf55", "#d99a34", "#c4632a", "#9c3f1e", "#6a2814", "#2e1006")
texture <- grDevices::colorRampPalette(pal)(256)

# --- 5. 3D scene + pathtracing (landscape frame, north up: theta = 0) --------
dims <- dim(mat)                                   # [rows(N-S), columns(E-W)]
# solid = TRUE -> the island is a block with thickness that projects its whole
# silhouette (like the landmass in the Germany map), not just the spike shadows.
mat |>
  height_shade(texture = texture) |>
  plot_3d(heightmap = mat, solid = TRUE, soliddepth = -600, shadowdepth = -650,
          zscale = 20, shadow = TRUE, shadow_darkness = 0.22,
          windowsize = c(1400, 1050),
          phi = 68, zoom = 0.66, theta = 0, background = "#e7e4dd")

# Main light (NW) + soft fill. Higher sun -> shorter/fainter spike shadows;
# the island silhouette casts a light shadow, not a dominant one.
render_highquality(
  filename = "out/_render.png", preview = FALSE,
  light = TRUE,
  lightdirection = c(315, 120), lightaltitude = c(62, 82),
  lightintensity = c(500, 300), lightcolor = c("#fff3dd", "#ffffff"),
  interactive = FALSE, width = 1600, height = 1200, samples = 256
)
cat("render OK, composing titles and legend...\n")

# --- 6. Title + color legend (magick) ---------------------------------------
maxdens <- round(max(kon$population, na.rm = TRUE) / area_km2)   # max inhab/km²
hab <- format(round(sum(kon$population)), big.mark = ".")
ff <- "DejaVu Sans"

# gradient bar (left = low, right = high) — ~25% smaller
bar <- image_read(as.raster(matrix(texture, nrow = 1))) |>
  image_resize("345x20!")

# more bottom margin: extend the canvas downward to separate the figure caption
render <- image_read("out/_render.png")
rr <- as.raster(render)
bg <- rr[nrow(rr), 1]                                   # real background color (bottom corner)
ri <- image_info(render)
render <- image_extent(render, sprintf("%dx%d", ri$width, ri$height + 140),
                       gravity = "north", color = bg)

# Top block ~25% smaller (title, text and legend)
img <- render |>
  image_annotate("MALLORCA", size = 72, gravity = "northwest",
                 location = "+66+34", color = "#241505", font = ff, weight = 700) |>
  image_annotate("Densitat de població · spikes de 400 m (Kontur 2023)", size = 26,
                 gravity = "northwest", location = "+70+122", color = "#7a4a1e", font = ff) |>
  image_annotate(sprintf("%s habitants", hab), size = 22,
                 gravity = "northwest", location = "+70+158", color = "#9a6a2e", font = ff)

# embed the bar and its labels
img <- image_composite(img, bar, offset = "+70+212")
img <- img |>
  image_annotate("habitants / km²", size = 20, gravity = "northwest",
                 location = "+70+188", color = "#5a3a15", font = ff) |>
  image_annotate("0", size = 18, gravity = "northwest",
                 location = "+66+236", color = "#5a3a15", font = ff) |>
  image_annotate(format(maxdens, big.mark = "."), size = 18, gravity = "northwest",
                 location = "+382+236", color = "#5a3a15", font = ff) |>
  image_annotate("Dades: Kontur Population 2023 (derivat de cens/padró · GHSL)",
                 size = 22, gravity = "south", location = "+0+34", color = "#8a7a55", font = ff)

image_write(img, "out/mallorca_population_3d.png")
cat("OK -> out/mallorca_population_3d.png (max", maxdens, "inhab/km²)\n")
