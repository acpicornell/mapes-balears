#!/usr/bin/env Rscript
# ============================================================================
# MALLORCA — population over relief map (Milos Popovic technique):
#   · real 3D terrain RELIEF (DEM) tinted petrol blue + hillshade
#   · POPULATION painted ON TOP as little yellow dots (overlay), NOT as spikes
#   · white background, near-nadir camera, centered serif title
# Recipe from docs/MILOS.md: height_shade(blue) -> add_shadow -> add_overlay(yellow)
#                            -> plot_3d -> render_highquality (CPU pathtracing).
# Relief: elevatr (AWS Terrain). Population: GHS-POP 2020 R2023A (3 arcsec ~90 m).
# Output: out/mallorca_population_relief.png
# ============================================================================
options(rgl.useNULL = TRUE)
suppressPackageStartupMessages({
  library(sf); library(terra); library(rayshader); library(dplyr)
  library(elevatr); library(giscoR); library(magick)
})
dir.create("out", showWarnings = FALSE)
draft <- nchar(Sys.getenv("DRAFT")) > 0             # DRAFT=1 -> quick preview (light DEM)
zdem  <- if (draft) 9 else 11                       # identical framing; only detail changes

# --- 1. Mallorca outline (UTM 31N) ------------------------------------------
bbox <- st_bbox(c(xmin = 437000, ymin = 4338000, xmax = 547000, ymax = 4422000),
                crs = 25831)
# DETAILED Mallorca outline: GADM level 1 (Illes Balears) cropped to the island.
# GISCO 1:1M left a very coarse coast (vertices ~1 km apart); GADM is much finer.
gadm_bale <- geodata::gadm("ESP", level = 1, path = "data/external/gadm")
gadm_bale <- gadm_bale[grepl("Balear", gadm_bale$NAME_1, ignore.case = TRUE), ]
mallorca <- crop(project(gadm_bale, "EPSG:25831"),
                 ext(437000, 547000, 4338000, 4422000))

# --- 2. Terrain DEM, cropped to the island (sea -> NA -> white background) ---
dem <- get_elev_raster(st_as_sf(st_as_sfc(bbox)), z = zdem, clip = "bbox") |> rast()
dem <- crop(dem, mallorca)
dem[dem < 0] <- 0                                   # coastal flats to sea level
dem[is.na(dem)] <- 0                                # fill inland water bodies
dem <- mask(dem, mallorca)                    # outside the island -> NA (background)
demmat <- raster_to_matrix(dem)
cat("DEM:", paste(dim(demmat), collapse = " x "), "px · max alt.",
    round(max(values(dem), na.rm = TRUE)), "m\n")

# --- 3. GHS-POP 2020 population at 3 arcsec (~90 m) — fine, no hexagons ------
pop4326 <- rast("data/external/ghsl_mallorca.tif")   # people/cell, EPSG:4326
hab_tot <- round(global(pop4326, "sum", na.rm = TRUE)[[1]])
cat("GHS-POP ~90 m ·", format(hab_tot, big.mark = "."), "inhab (2020)\n")

# --- 4. Petrol blue relief + shadows (hillshade) ----------------------------
bluepal <- grDevices::colorRampPalette(
  c("#0f2b40", "#164a68", "#22597a", "#2c6f95"))(256)
zsc <- 12                                           # vertical exaggeration of the DEM
shadow <- ray_shade(demmat, zscale = zsc, sunaltitude = 40, sunangle = 315,
                    multicore = TRUE)
amb <- ambient_shade(demmat, zscale = zsc, multicore = TRUE)
base <- height_shade(demmat, texture = bluepal) |>
  add_shadow(shadow, max_darken = 0.52) |>
  add_shadow(amb, max_darken = 0.20)

# --- 5. Population overlay in YELLOW, aligned by geography (terra) -----------
# NOTE: height_shade() transposes the matrix; building the overlay by hand from
# raster_to_matrix() leaves it rotated 90°. We generate it with terra (north up)
# at the SAME dimensions as `base` -> alignment guaranteed.
H <- dim(base)[1]; W <- dim(base)[2]
pr <- rast(nrows = H, ncols = W, extent = ext(dem), crs = crs(dem))
pop <- project(pop4326, pr, method = "bilinear") |> mask(mallorca)
am <- as.matrix(pop, wide = TRUE)                   # row1=north, col1=west (aligned to `base`)
am[is.na(am)] <- 0
q <- as.numeric(quantile(am[am > 0], 0.995))        # saturate at the high percentile (not a single cell)
a <- pmin(am / q, 1)^0.55                           # secondary towns visible, not just Palma
a[am < 0.4] <- 0                                    # no people -> transparent
ov <- array(0, dim = c(H, W, 4))
ov[, , 1] <- 1.00; ov[, , 2] <- 0.90; ov[, , 3] <- 0.00   # yellow #ffe600
ov[, , 4] <- a
texture <- add_overlay(base, ov, alphalayer = 0.95)

# --- 6. 3D scene (near-nadir) + pathtracing, white background ---------------
smp <- if (draft) 24 else 256
wd  <- if (draft) 900 else 3200                     # high resolution (holds up to zoom)
ht  <- if (draft) 675 else 2400

texture |>
  plot_3d(heightmap = demmat, solid = TRUE, soliddepth = -120, shadowdepth = -140,
          zscale = zsc, shadow = FALSE,               # we add the shadow in post
          windowsize = c(1600, 1200),
          phi = 78, zoom = 0.78, theta = 0, background = "#ffffff")

# Island with TRANSPARENT background and no ground (minimal ground_size): this way
# in magick we assemble a paper background + a faint offset shadow (Milos Texas style).
render_highquality(
  filename = "out/_render_relief.png", preview = FALSE,
  light = TRUE, lightdirection = c(315, 135), lightaltitude = c(55, 80),
  lightintensity = c(420, 300), lightcolor = c("#ffffff", "#ffffff"),
  transparent_background = TRUE, ground_size = 0.1,
  interactive = FALSE, width = wd, height = ht, samples = smp
)
cat("render OK, composing titles and legend...\n")

# --- 7. Paper background + soft offset shadow + bottom-left title (magick) ---
serif <- "DejaVu Serif"
paper <- "#f4f2ec"; ink <- "#14202c"
s <- wd / 1600                                      # scale relative to the base design (1600 px)
px <- function(x) round(x * s)

island <- image_read("out/_render_relief.png")      # RGBA: only the island (transparent background)
info <- image_info(island); W <- info$width; H <- info$height

# Faint shadow (Texas style): silhouette (alpha) -> black -> blurred -> offset.
mask   <- image_channel(island, "alpha")
sil    <- image_composite(image_blank(W, H, "black"), mask, operator = "CopyOpacity")
shadow <- image_blur(sil, 0, px(16))

canvas <- image_blank(W, H, paper)
canvas <- image_composite(canvas, shadow, operator = "dissolve", compose_args = "45",
                          offset = sprintf("+%d+%d", px(24), px(34)))
img <- image_composite(canvas, island, offset = "+0+0")

# Bottom-left title: "Població" (thin) + "MALLORCA" (bold). No figure caption.
img <- img |>
  image_annotate("Població", size = px(46), gravity = "southwest",
                 location = sprintf("+%d+%d", px(42), px(150)), color = ink, font = serif) |>
  image_annotate("MALLORCA", size = px(104), gravity = "southwest",
                 location = sprintf("+%d+%d", px(40), px(50)), color = ink,
                 font = serif, weight = 700)

image_write(img, "out/mallorca_population_relief.png")
cat("OK -> out/mallorca_population_relief.png ·", format(hab_tot, big.mark = "."), "inhab\n")
