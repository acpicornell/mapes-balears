#!/usr/bin/env Rscript
# ============================================================================
# ELS LLOGARETS DE LES ILLES BALEARS — the 160 smaller population nuclei
# (TIPUS_LOCAL 3011) from the NGIB, labelled over the islands. Editorial style.
# Output: out/llogarets.png
# ============================================================================
suppressPackageStartupMessages({
  library(sf); library(giscoR); library(ggplot2); library(dplyr); library(ggrepel)
})
dir.create("out", showWarnings = FALSE)

bal <- gisco_get_nuts(nuts_level = 2, resolution = "01", country = "ES") |>
  filter(NUTS_ID == "ES53") |> st_transform(25831)

llo <- st_read("data/processed/ngib_llogarets.gpkg", quiet = TRUE) |> st_transform(25831)
xy <- bind_cols(st_coordinates(llo) |> as.data.frame(),
                GRAFIA = llo$GRAFIA, MUNICIPI = llo$MUNICIPI)
cat(nrow(xy), "llogarets\n")

p <- ggplot() +
  geom_sf(data = bal, fill = "#20303a", colour = "#3d5563", linewidth = 0.3) +
  geom_point(data = xy, aes(X, Y), colour = "#e9c46a", size = 1.6, alpha = 0.95) +
  geom_text_repel(data = xy, aes(X, Y, label = GRAFIA),
                  size = 2.3, colour = "#f4ede0", segment.colour = "#5f7791",
                  segment.size = 0.2, max.overlaps = 40, min.segment.length = 0,
                  family = "sans") +
  coord_sf(crs = 25831, expand = FALSE) +
  labs(title = "ELS LLOGARETS DE LES ILLES BALEARS",
       subtitle = sprintf("%s nuclis de població menors (llogarets) · NGIB", nrow(xy)),
       caption = "Dades: NGIB (ICGIB) · ideib.caib.es") +
  theme_void(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 26, hjust = 0.02, colour = "#e9c46a"),
        plot.subtitle = element_text(size = 12, hjust = 0.02, colour = "#9fb3c8"),
        plot.caption = element_text(colour = "#5f7791"),
        plot.background = element_rect(fill = "#0e1826", colour = NA),
        plot.margin = margin(16, 16, 12, 16))

ggsave("out/llogarets.png", p, width = 13, height = 9, dpi = 300, bg = "#0e1826")
cat("OK -> out/llogarets.png\n")
