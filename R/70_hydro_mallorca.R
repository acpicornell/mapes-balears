#!/usr/bin/env Rscript
# ============================================================================
# MALLORCA — water & land-cover map: the torrent network and the island's
# wetlands/reservoirs over a natural land-cover tint and a crisp relief.
# Mallorca has no permanent rivers, only seasonal "torrents"; many of them end
# at coastal wetlands (s'Albufera, es Salobrar de Campos) rather than a river.
# Land cover (vegetation + water bodies): ESA WorldCover 2021 (scripts/09).
# Relief: elevatr (AWS Terrain), shaded with rayshader for a crisp texture.
# Torrents: COMPLETE network derived from the DEM by D8 flow routing (R/71),
# so every channel is connected and drains to the sea (unlike the OSM patchwork).
# Output: out/mallorca_hydro.png
# ============================================================================
options(rgl.useNULL = TRUE)
suppressPackageStartupMessages({
  library(sf); library(terra); library(rayshader); library(elevatr); library(giscoR)
  library(dplyr); library(ggplot2)
})
dir.create("out", showWarnings = FALSE)
draft <- nchar(Sys.getenv("DRAFT")) > 0
zdem  <- if (draft) 8 else 11

# --- 1. Mallorca outline (UTM 31N) ------------------------------------------
# ymax reaches 4,428,000 so the tip of Cap de Formentor (~4,423,100 N) is kept.
bbox <- st_bbox(c(xmin = 437000, ymin = 4338000, xmax = 547000, ymax = 4428000),
                crs = 25831)
gadm_bale <- geodata::gadm("ESP", level = 1, path = "data/external/gadm")
gadm_bale <- gadm_bale[grepl("Balear", gadm_bale$NAME_1, ignore.case = TRUE), ]
mallorca  <- crop(project(gadm_bale, "EPSG:25831"),
                  ext(437000, 547000, 4338000, 4428000))
mall_sf   <- st_as_sf(mallorca) |> st_union()

# --- 2. DEM + crisp grayscale hillshade (ray-traced shadows + AO) ------------
# The tactile texture comes from ray_shade (cast shadows) + ambient_shade (AO),
# the same recipe as the population maps; a plain terra hillshade looks flat.
dem <- get_elev_raster(st_as_sf(st_as_sfc(bbox)), z = zdem, clip = "bbox") |> rast()
dem <- crop(dem, mallorca); dem[dem < 0] <- 0; dem[is.na(dem)] <- 0
dem <- mask(dem, mallorca)
demmat <- raster_to_matrix(dem)
zsc <- 8
ray <- ray_shade(demmat, zscale = zsc, sunaltitude = 42, sunangle = 315, multicore = TRUE)
amb <- ambient_shade(demmat, zscale = zsc, multicore = TRUE)
# flat-white base -> the array is a pure grayscale shade we can tint later
shd <- height_shade(demmat,
                    texture = grDevices::colorRampPalette(c("#ffffff", "#ffffff"))(256)) |>
  add_shadow(ray, max_darken = 0.55) |>
  add_shadow(amb, max_darken = 0.62)
shr <- rast(shd)[[1]]; ext(shr) <- ext(dem); crs(shr) <- crs(dem)

# --- 3. Land cover: vegetation + water bodies (ESA WorldCover 2021) ----------
lc_pal <- c("10" = "#33623f",  # tree cover      -> forest green
            "20" = "#9a8f4e",  # shrubland       -> olive (garriga)
            "30" = "#c0c47e",  # grassland
            "40" = "#e7d7a4",  # cropland        -> wheat (the Pla)
            "50" = "#b0705f",  # built-up        -> muted brick
            "60" = "#d8cbb0",  # bare / sparse
            "80" = "#2f7d9a",  # permanent water -> reservoirs, lagoons
            "90" = "#5fa38f")  # herbaceous wetland -> s'Albufera, es Salobrar
wc <- rast("data/external/mallorca_worldcover.tif")
wc <- project(wc, shr, method = "near") |> mask(mallorca)

st  <- c(wc, shr); names(st) <- c("cls", "sh")
df  <- as.data.frame(st, xy = TRUE, na.rm = TRUE)
df  <- df[df$cls %in% as.integer(names(lc_pal)), ]
brgb <- grDevices::col2rgb(lc_pal[as.character(df$cls)]) / 255
flat <- df$cls %in% c(80, 90)                          # keep water/wetland flat
sh   <- ifelse(flat, pmax(df$sh, 0.92), df$sh)
mult <- 0.55 + 0.5 * sh                                # shadow ~0.7, lit ~1.05
df$hex <- grDevices::rgb(pmin(brgb[1, ] * mult, 1),
                         pmin(brgb[2, ] * mult, 1),
                         pmin(brgb[3, ] * mult, 1))
cat("land cover:", nrow(df), "cells · DEM", paste(dim(dem)[1:2], collapse = "x"), "\n")

# --- 4. Torrent network (complete, DEM-derived; width by Strahler order) -----
torr <- st_read("data/external/mallorca_torrents_dem.gpkg", "torrents", quiet = TRUE)
torr <- st_intersection(torr, mall_sf)
wtab <- c(0.05, 0.09, 0.15, 0.23, 0.34, 0.48, 0.62)    # fine headwaters -> slim trunks
torr$w <- wtab[pmin(torr$order, length(wtab))]
cat("torrents (DEM):", nrow(torr), "reaches · Strahler max", max(torr$order), "\n")

# --- 5. Compact legend (placed over the SW sea, Badia de Palma) --------------
leg <- data.frame(
  lab = c("Bosc", "Matollar", "Conreu / prats", "Urbà", "Aigua", "Zona humida"),
  col = c("#33623f", "#9a8f4e", "#e7d7a4", "#b0705f", "#2f7d9a", "#5fa38f"))
lx <- 441000; sw <- 4600; ty <- 4364000; dy <- 4300
leg$yy <- ty - (seq_len(nrow(leg)) - 1) * dy

# --- 6. Plot ----------------------------------------------------------------
paper <- "#eef2f2"; ink <- "#20303a"; water <- "#0b3a54"

p <- ggplot() +
  geom_raster(data = df, aes(x, y, fill = hex), show.legend = FALSE) +
  geom_sf(data = mall_sf, fill = NA, colour = "#54636b", linewidth = 0.3) +
  # torrents with a faint light casing so they read over the dark forest too
  geom_sf(data = torr, aes(linewidth = w + 0.22), colour = "#e7eef0", alpha = 0.4,
          lineend = "round", show.legend = FALSE) +
  geom_sf(data = torr, aes(linewidth = w), colour = water,
          lineend = "round", show.legend = FALSE) +
  scale_linewidth_identity() +
  geom_rect(data = leg, aes(xmin = lx, xmax = lx + sw, ymin = yy - 1600,
                            ymax = yy + 1600, fill = col)) +
  geom_text(data = leg, aes(x = lx + sw + 2200, y = yy, label = lab),
            hjust = 0, colour = ink, family = "serif", size = 4.1) +
  scale_fill_identity() +
  coord_sf(expand = FALSE, datum = NA) +
  labs(title = "MALLORCA",
       subtitle = "Aigua i coberta del sòl · torrents, zones humides i vegetació",
       caption = "Coberta: ESA WorldCover 2021 · Torrents: xarxa derivada del MDT (D8) · Relleu: elevatr") +
  theme_void(base_family = "serif") +
  theme(
    plot.background  = element_rect(fill = paper, colour = NA),
    panel.background = element_rect(fill = paper, colour = NA),
    plot.title    = element_text(colour = ink, size = 46, face = "bold", hjust = 0.02,
                                 margin = margin(t = 14, b = 2)),
    plot.subtitle = element_text(colour = "#3d5a52", size = 19, hjust = 0.02,
                                 margin = margin(b = 8)),
    plot.caption  = element_text(colour = "#7d8a86", size = 12, hjust = 0.98,
                                 margin = margin(t = 6, b = 10)),
    plot.margin   = margin(6, 16, 6, 16)
  )

ggsave("out/mallorca_hydro.png", p, width = 11, height = 9.4, dpi = if (draft) 110 else 300,
       bg = paper)
cat("OK -> out/mallorca_hydro.png\n")
