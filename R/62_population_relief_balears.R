#!/usr/bin/env Rscript
# ============================================================================
# ILLES BALEARS — population over relief, as a triptych (Milos Popovic technique)
#   · one 3D terrain RELIEF per island group (DEM) tinted petrol blue + hillshade
#   · POPULATION painted ON TOP as little yellow dots (overlay), NOT as spikes
#   · Mallorca · Menorca · Eivissa+Formentera, each rendered on its own and then
#     composed into a single figure at TRUE RELATIVE SCALE (same px per metre),
#     laid out to echo the real NE–SW arrangement of the archipelago.
# Relief: elevatr (AWS Terrain). Population: GHS-POP 2020 R2023A (3 arcsec ~90 m),
# whole-archipelago mosaic from scripts/07_download_ghsl.sh.
# Output: out/balears_population_relief.png
# ============================================================================
options(rgl.useNULL = TRUE)
suppressPackageStartupMessages({
  library(sf); library(terra); library(rayshader); library(dplyr)
  library(elevatr); library(giscoR); library(magick)
})
dir.create("out", showWarnings = FALSE)
draft <- nchar(Sys.getenv("DRAFT")) > 0             # DRAFT=1 -> quick preview (light DEM)
zdem  <- if (draft) 9 else 11                       # identical framing; only detail changes
smp   <- if (draft) 24 else 256                     # pathtracing samples
ppm   <- if (draft) 0.0060 else 0.0240              # px per metre (shared -> true relative scale)

# --- Shared style -----------------------------------------------------------
bluepal <- grDevices::colorRampPalette(
  c("#0f2b40", "#164a68", "#22597a", "#2c6f95"))(256)
zsc   <- 12                                         # vertical exaggeration of the DEM
serif <- "DejaVu Serif"
paper <- "#f4f2ec"; ink <- "#14202c"

# DETAILED coastline: GADM level 1 (Illes Balears), reprojected to UTM 31N.
# Each island group is isolated by cropping this multipolygon to a bbox that
# contains only that group (the channels between groups are wide enough).
gadm_bale <- geodata::gadm("ESP", level = 1, path = "data/external/gadm")
gadm_bale <- gadm_bale[grepl("Balear", gadm_bale$NAME_1, ignore.case = TRUE), ]
bale <- project(gadm_bale, "EPSG:25831")

# Whole-archipelago population (people/cell, EPSG:4326)
pop4326 <- rast("data/external/ghsl_balears.tif")
hab_bal <- round(global(pop4326, "sum", na.rm = TRUE)[[1]])
cat("GHS-POP ~90 m · Illes Balears ·", format(hab_bal, big.mark = "."), "inhab (2020)\n")

# Island groups, defined by a lon/lat bbox (WGS84) that contains only that group.
islands <- list(
  list(key = "mallorca", name = "Mallorca",             lon = c(2.28, 3.50), lat = c(39.24, 39.99)),
  list(key = "menorca",  name = "Menorca",              lon = c(3.73, 4.34), lat = c(39.78, 40.10)),
  list(key = "pitiuses", name = "Eivissa i Formentera", lon = c(1.14, 1.66), lat = c(38.63, 39.13))
)

# --- Render one island group -> transparent PNG (island only) ----------------
render_island <- function(isl) {
  cat("\n== ", isl$name, " ==\n", sep = "")
  # bbox WGS84 -> UTM 31N extent
  bb   <- st_bbox(c(xmin = isl$lon[1], ymin = isl$lat[1],
                    xmax = isl$lon[2], ymax = isl$lat[2]), crs = 4326)
  e    <- st_as_sfc(bb) |> st_transform(25831) |> st_bbox()
  ext_utm <- ext(e["xmin"], e["xmax"], e["ymin"], e["ymax"])
  coast   <- crop(bale, ext_utm)                    # this group's coastline only

  # DEM, cropped/masked to the island (sea -> NA -> transparent)
  dem <- get_elev_raster(st_as_sf(st_as_sfc(st_bbox(e))), z = zdem, clip = "bbox") |> rast()
  dem <- crop(dem, coast)
  dem[dem < 0] <- 0                                 # coastal flats to sea level
  dem[is.na(dem)] <- 0                              # fill inland water bodies
  dem <- mask(dem, coast)
  demmat <- raster_to_matrix(dem)
  cat("  DEM:", paste(dim(demmat), collapse = " x "), "px · max alt.",
      round(max(values(dem), na.rm = TRUE)), "m\n")

  # Petrol blue relief + hillshade
  shadow <- ray_shade(demmat, zscale = zsc, sunaltitude = 40, sunangle = 315, multicore = TRUE)
  amb    <- ambient_shade(demmat, zscale = zsc, multicore = TRUE)
  base <- height_shade(demmat, texture = bluepal) |>
    add_shadow(shadow, max_darken = 0.52) |>
    add_shadow(amb, max_darken = 0.20)

  # Population overlay in YELLOW, aligned by geography via terra (north up).
  # height_shade() transposes the matrix, so we rebuild the overlay with terra
  # at the SAME dims as `base` to guarantee alignment.
  H <- dim(base)[1]; W <- dim(base)[2]
  pr  <- rast(nrows = H, ncols = W, extent = ext(dem), crs = crs(dem))
  pop <- project(pop4326, pr, method = "bilinear") |> mask(coast)
  hab <- round(global(pop, "sum", na.rm = TRUE)[[1]])
  am  <- as.matrix(pop, wide = TRUE); am[is.na(am)] <- 0
  q   <- as.numeric(quantile(am[am > 0], 0.995))    # saturate at the high percentile
  a   <- pmin(am / q, 1)^0.55                       # secondary towns visible, not just the capital
  a[am < 0.4] <- 0                                  # no people -> transparent
  ov <- array(0, dim = c(H, W, 4))
  ov[, , 1] <- 1.00; ov[, , 2] <- 0.90; ov[, , 3] <- 0.00   # yellow #ffe600
  ov[, , 4] <- a
  texture <- add_overlay(base, ov, alphalayer = 0.95)

  # Canvas size proportional to the real extent (shared ppm -> true relative scale).
  wm <- as.numeric(ext(dem)[2] - ext(dem)[1])
  hm <- as.numeric(ext(dem)[4] - ext(dem)[3])
  wd <- max(200, round(wm * ppm)); ht <- max(200, round(hm * ppm))

  # windowsize MUST share the render aspect (wd:ht); otherwise the 3D camera is
  # framed for a different aspect and the island gets stretched/compressed (this
  # squashed the tall Eivissa+Formentera frame). rgl.useNULL makes the size free.
  texture |>
    plot_3d(heightmap = demmat, solid = TRUE, soliddepth = -120, shadowdepth = -140,
            zscale = zsc, shadow = FALSE, windowsize = c(wd, ht),
            phi = 78, zoom = 0.82, theta = 0, background = "#ffffff")
  fn <- sprintf("out/_render_%s.png", isl$key)
  render_highquality(
    filename = fn, preview = FALSE,
    light = TRUE, lightdirection = c(315, 135), lightaltitude = c(55, 80),
    lightintensity = c(420, 300), lightcolor = c("#ffffff", "#ffffff"),
    transparent_background = TRUE, ground_size = 0.1,
    interactive = FALSE, width = wd, height = ht, samples = smp
  )
  rgl::close3d()
  cat("  render OK ·", format(hab, big.mark = "."), "inhab\n")
  list(key = isl$key, name = isl$name, file = fn, hab = hab)
}

res <- lapply(islands, render_island)
names(res) <- vapply(res, function(r) r$key, "")

# --- Compose the triptych (magick) ------------------------------------------
cat("\ncomposing triptych...\n")
pxf <- function(x) round(x * (ppm / 0.0240))        # sizes scale with the render (ppm)

# Trim each render to its content (island + block). All share ppm, so the trimmed
# sprites are already at true relative scale.
sprite <- lapply(res, function(r) image_trim(image_read(r$file)))
dims   <- lapply(sprite, image_info)
wOf <- function(k) dims[[k]]$width; hOf <- function(k) dims[[k]]$height
k_name <- function(k) res[[k]]$name

gap <- pxf(90); mar <- pxf(70)
col1 <- mar
col2 <- mar + max(wOf("mallorca"), wOf("pitiuses")) + gap
row1 <- mar
row2 <- mar + max(hOf("mallorca"), hOf("menorca")) + gap

pos <- list(                                        # top-left corner of each sprite
  mallorca = c(col1, row1),
  menorca  = c(col2, row1),
  pitiuses = c(col1, row2)
)
# Title block as its own trimmed sprite, so the canvas is sized to fit it.
title <- image_blank(pxf(1800), pxf(360), "none") |>
  image_annotate("Població", size = pxf(52), gravity = "northwest", font = serif,
                 color = ink, location = "+0+0") |>
  image_annotate("ILLES BALEARS", size = pxf(96), gravity = "northwest", font = serif,
                 weight = 700, color = ink, location = sprintf("+0+%d", pxf(58))) |>
  image_annotate(sprintf("%s habitants · GHS-POP 2020", format(hab_bal, big.mark = ".")),
                 size = pxf(30), gravity = "northwest", font = serif,
                 color = "#5a6570", location = sprintf("+0+%d", pxf(166))) |>
  image_trim()
tw <- image_info(title)$width

canvasW <- col2 + max(wOf("menorca"), tw + pxf(20)) + mar
canvasH <- row2 + hOf("pitiuses") + mar

canvas <- image_blank(canvasW, canvasH, paper)

# Paste each island with its own soft offset shadow (Milos "Texas" style).
place <- function(cv, k) {
  spr <- sprite[[k]]; x <- pos[[k]][1]; y <- pos[[k]][2]
  d <- dims[[k]]
  msk <- image_channel(spr, "alpha")
  sil <- image_composite(image_blank(d$width, d$height, "black"), msk, operator = "CopyOpacity")
  sh  <- image_blur(sil, 0, pxf(16))
  cv  <- image_composite(cv, sh,  operator = "dissolve", compose_args = "42",
                         offset = sprintf("+%d+%d", x + pxf(22), y + pxf(30)))
  cv  <- image_composite(cv, spr, offset = sprintf("+%d+%d", x, y))
  # small island label, centred under the sprite
  cx  <- x + round(d$width / 2)
  cv |> image_annotate(k_name(k), size = pxf(30), gravity = "northwest", font = serif,
                       color = ink, location = sprintf("+%d+%d",
                       cx - round(nchar(k_name(k)) * pxf(30) * 0.28), y + d$height + pxf(10)))
}

img <- canvas
for (k in c("mallorca", "menorca", "pitiuses")) img <- place(img, k)

# Place the title in the open area below Menorca (right column).
tx <- col2 + pxf(6); ty <- row1 + hOf("menorca") + pxf(120)
img <- image_composite(img, title, offset = sprintf("+%d+%d", tx, ty))

image_write(img, "out/balears_population_relief.png")
cat("OK -> out/balears_population_relief.png ·", format(hab_bal, big.mark = "."), "inhab\n")
