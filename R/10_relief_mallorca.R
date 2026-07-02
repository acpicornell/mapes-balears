#!/usr/bin/env Rscript
# ============================================================================
# Shaded relief map of MALLORCA with NGIB toponyms
# Milos Agathon style, 2D version (headless-safe: no OpenGL/GPU needed).
# Output: out/mallorca_relieve.png
# ============================================================================
suppressPackageStartupMessages({
  library(sf); library(terra); library(elevatr)
  library(giscoR); library(ggplot2); library(dplyr); library(MetBrewer)
})
dir.create("out", showWarnings = FALSE)

# --- 1. Administrative boundary of the Illes Balears (NUTS2 = ES53) ---------
bal <- gisco_get_nuts(nuts_level = 2, resolution = "01", country = "ES") |>
  filter(NUTS_ID == "ES53") |>
  st_transform(25831)

# Crop to Mallorca (largest island) using an approximate bbox in EPSG:25831
mallorca_bbox <- st_bbox(c(xmin = 440000, ymin = 4340000,
                           xmax = 545000, ymax = 4420000), crs = 25831)
mallorca <- st_crop(bal, mallorca_bbox)

# --- 2. Digital elevation model (elevatr -> AWS Terrain tiles) --------------
dem <- get_elev_raster(locations = st_as_sf(st_as_sfc(mallorca_bbox)),
                       z = 10, clip = "bbox") |>
  rast()
dem <- crop(dem, vect(mallorca)) |> mask(vect(mallorca))
dem[dem < 0] <- 0   # sea to 0

# --- 3. Hillshade (shaded relief) ------------------------------------------
slope  <- terrain(dem, "slope",  unit = "radians")
aspect <- terrain(dem, "aspect", unit = "radians")
hs     <- shade(slope, aspect, angle = 40, direction = 315)

# to a data.frame for ggplot
hs_df  <- as.data.frame(hs, xy = TRUE); names(hs_df)[3] <- "hs"
dem_df <- as.data.frame(dem, xy = TRUE); names(dem_df)[3] <- "elev"

# --- 4. NGIB peaks (TIPUS_LOCAL for landforms: puig/serra) ------------------
llocs <- st_read("data/processed/ngib_llocs.gpkg", quiet = TRUE)
cims <- llocs |>
  filter(grepl("Puig|Serra|Talaia|Puigmajor|Massanella",
               GRAFIA, ignore.case = TRUE)) |>
  st_transform(25831)
cims_xy <- cims |> st_coordinates() |> as.data.frame() |> bind_cols(GRAFIA = cims$GRAFIA)

# --- 5. Milos-style plot ----------------------------------------------------
# Hypsometric tints: green lowlands -> brown/white peaks.
pal <- colorRampPalette(c("#3b7d54", "#8fae5d", "#e8d99a",
                          "#c99a5b", "#8c5a3b", "#f5f0e6"))(64)

p <- ggplot() +
  geom_raster(data = dem_df, aes(x, y, fill = elev)) +
  geom_raster(data = hs_df, aes(x, y, alpha = hs), fill = "grey10") +
  scale_fill_gradientn(colours = pal, name = "Altitud (m)",
                       trans = "sqrt") +
  scale_alpha(range = c(0, 0.45), guide = "none") +
  coord_sf(crs = 25831, expand = FALSE) +
  labs(title = "MALLORCA", subtitle = "Relieve y topónimos · NGIB / IDEIB",
       caption = "Datos: NGIB (ICGIB) · MDE: AWS Terrain vía elevatr") +
  theme_void(base_size = 13) +
  theme(legend.position = c(0.9, 0.25),
        plot.title = element_text(face = "bold", size = 30, hjust = 0.02),
        plot.background = element_rect(fill = "#f4efe6", colour = NA))

ggsave("out/mallorca_relieve.png", p, width = 11, height = 8.5, dpi = 300, bg = "#f4efe6")
cat("OK -> out/mallorca_relieve.png\n")
