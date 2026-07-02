#!/usr/bin/env Rscript
# ============================================================================
# Subclasifica el TIPUS_LOCAL 3014 ("Finca, possessió, lloc, casa pagesa,
# caseta") por MORFOLOGÍA DEL TOPÓNIMO — la forma en que se estudian las
# possessions mallorquinas — porque el NGIB no las separa por campo.
#
#   Possessió/estate : Son, So n', Son na, Sa n', Rafal, Alqueria, Beni-,
#                      o TIPUS_SUPERLOCAL=5 ("Llocs", el terme menorquí)
#   Casa (Can/Cas)   : Can, Ca'n, Ca na, Ca s', Cas  (cases pageses)
#   Caseta/Barraca   : construccions menors
#   Altre            : la resta (es/sa/ses/s'+topònim, etc.)
#
# Escribe: data/processed/ngib_finques.gpkg (con columna CATEGORIA)
# Mapa:    out/possessions_classif_mallorca.png
# ============================================================================
suppressPackageStartupMessages({
  library(sf); library(giscoR); library(ggplot2); library(dplyr)
})
dir.create("out", showWarnings = FALSE)

g <- st_read("data/processed/ngib_llocs.gpkg", quiet = TRUE) |>
  filter(TIPUS_LOCAL == 3014) |> st_transform(25831)

low <- tolower(g$GRAFIA)
g$CATEGORIA <- case_when(
  grepl("^(son |so n'|son na |sa n')", low) |
    grepl("rafal|alqueri|(^| )beni", low) |
    (!is.na(g$TIPUS_SUPERLOCAL) & g$TIPUS_SUPERLOCAL == 5)      ~ "Possessió",
  grepl("caset|barrac", low)                                    ~ "Caseta/Barraca",
  grepl("^(ca'n |can |ca na |ca s'|cas |ca' )", low)            ~ "Casa (Can/Cas)",
  TRUE                                                          ~ "Altre"
)
print(as.data.frame(table(g$CATEGORIA)))
st_write(g["CATEGORIA"] |> bind_cols(GRAFIA = g$GRAFIA, MUNICIPI = g$MUNICIPI,
                                     ILLA = g$ILLA),
         "data/processed/ngib_finques.gpkg", delete_dsn = TRUE, quiet = TRUE)

# --- Mapa comparativo (small multiples): una faceta por categoría -----------
bbox <- st_bbox(c(xmin = 437000, ymin = 4338000, xmax = 547000, ymax = 4422000), crs = 25831)
mall <- gisco_get_nuts(nuts_level = 2, resolution = "01", country = "ES") |>
  filter(NUTS_ID == "ES53") |> st_transform(25831) |> st_crop(bbox)

gm <- st_filter(g, mall)
xy <- bind_cols(st_coordinates(gm) |> as.data.frame(), CATEGORIA = gm$CATEGORIA)
# etiqueta de faceta con recuento, ordenada
cnt <- xy |> count(CATEGORIA)
ord <- c("Possessió", "Casa (Can/Cas)", "Caseta/Barraca", "Altre")
lab <- setNames(sprintf("%s — %s", ord,
        format(cnt$n[match(ord, cnt$CATEGORIA)], big.mark = ".")), ord)
xy$panel <- factor(lab[xy$CATEGORIA], levels = lab[ord])
pal <- c("#f2b705", "#3a6ea5", "#8a8f98", "#8a8f98"); names(pal) <- lab[ord]
n_poss <- sum(gm$CATEGORIA == "Possessió")

p <- ggplot() +
  geom_sf(data = mall, fill = "#0f1a26", colour = "#2b4257", linewidth = 0.3) +
  geom_point(data = xy, aes(X, Y, colour = panel), size = 0.5, alpha = 0.75, stroke = 0) +
  scale_colour_manual(values = pal, guide = "none") +
  facet_wrap(~panel, ncol = 2) +
  coord_sf(crs = 25831, expand = FALSE) +
  labs(title = "LES FINQUES DE MALLORCA, PER TIPUS",
       subtitle = sprintf("El NGIB agrupa %s edificacions rurals (TIPUS_LOCAL 3014); només ~%s són possessions (Son·Rafal·Alqueria)",
                          format(nrow(gm), big.mark = "."), format(n_poss, big.mark = ".")),
       caption = "Subclassificació per morfologia del topònim · Dades: NGIB (ICGIB)") +
  theme_void(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 26, hjust = 0.01, colour = "#ffe9a8"),
        plot.subtitle = element_text(size = 11, hjust = 0.01, colour = "#9fb3c8"),
        plot.caption = element_text(colour = "#5f7791"),
        strip.text = element_text(colour = "#e9c46a", face = "bold", size = 12,
                                  margin = margin(4, 0, 4, 0)),
        plot.background = element_rect(fill = "#0b131d", colour = NA),
        plot.margin = margin(16, 16, 12, 16))

ggsave("out/possessions_classif_mallorca.png", p, width = 12, height = 9.5, dpi = 300, bg = "#0b131d")
cat("OK -> out/possessions_classif_mallorca.png (", n_poss, "possessions en Mallorca )\n")
