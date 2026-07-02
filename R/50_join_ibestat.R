#!/usr/bin/env Rscript
# ============================================================================
# Cruce NGIB × IBESTAT a nivel municipal:
#   possessions por municipio  ×  población empadronada (IBESTAT)  ×  superficie
# Produce:
#   out/possessions_por_municipio.png   (coropleta: possessions / 100 km²)
#   out/possessions_vs_poblacion.png    (dispersión población vs nº possessions)
#   data/processed/municipis_indicadors.csv
# ============================================================================
suppressPackageStartupMessages({
  library(sf); library(giscoR); library(ggplot2); library(dplyr)
  library(jsonlite); library(MetBrewer); library(scales)
})
dir.create("out", showWarnings = FALSE)

# --- 1. Población municipal (IBESTAT, JSON eDatos) --------------------------
j <- fromJSON("data/raw/ibestat/pob_municipi.json", simplifyVector = FALSE)
dims <- j$data$dimensions$dimension
terr <- vapply(dims[[1]]$representations$representation, \(x) x$code, "")   # 67 INE
sexo <- vapply(dims[[3]]$representations$representation, \(x) x$code, "")   # _T,M,F
meas <- vapply(dims[[4]]$representations$representation, \(x) x$code, "")   # 3 medidas
# observations: valores separados por " | ", orden row-major TERR×TIME(1)×SEXO×MED
vals <- as.numeric(strsplit(j$data$observations, "\\s*\\|\\s*")[[1]])
nS <- length(sexo); nM <- length(meas)                                     # 3, 3
iT <- which(sexo == "_T"); iP <- which(meas == "POBLACION_PADRON")         # 1, 2
# población total = por cada municipio, bloque de nS*nM; posición (iT-1)*nM + iP
pos <- (seq_along(terr) - 1) * (nS * nM) + (iT - 1) * nM + iP
pob <- data.frame(ine = terr, poblacio = vals[pos])
cat("IBESTAT: ", nrow(pob), " municipios, población total = ",
    format(sum(pob$poblacio), big.mark = "."), "\n", sep = "")

# --- 2. Límites municipales (GISCO LAU) + superficie ------------------------
lau <- gisco_get_lau(year = "2021", country = "ES") |>
  st_transform(25831)
# El código INE está en GISCO_ID tipo "ES_07001" o en LAU_ID
lau$ine <- sub(".*_", "", lau$GISCO_ID)
bal <- lau |> filter(ine %in% pob$ine) |>
  mutate(area_km2 = as.numeric(st_area(geometry)) / 1e6)
cat("GISCO LAU: ", nrow(bal), " municipios de Baleares\n", sep = "")

# --- 3. Possessions por municipio (conteo espacial) ------------------------
poss <- st_read("data/processed/ngib_possessions.gpkg", quiet = TRUE) |>
  st_transform(25831)
bal$n_poss <- lengths(st_intersects(bal, poss))

# --- 4. Indicadores ---------------------------------------------------------
m <- bal |>
  left_join(pob, by = "ine") |>
  mutate(poss_km2   = n_poss / area_km2 * 100,       # possessions por 100 km²
         poss_1000h = n_poss / poblacio * 1000)      # possessions por 1000 hab

write.csv(st_drop_geometry(m), "data/processed/municipis_indicadors.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

# --- 5a. Coropleta: possessions por 100 km² ---------------------------------
p1 <- ggplot(m) +
  geom_sf(aes(fill = poss_km2), colour = "white", linewidth = 0.15) +
  scale_fill_gradientn(colours = met.brewer("Tam"), name = "Possessions\nper 100 km²") +
  labs(title = "LA MALLORCA DE LES POSSESSIONS",
       subtitle = "Densitat de finques i possessions (NGIB) per municipi",
       caption = "Dades: NGIB (ICGIB) · límits GISCO · població IBESTAT") +
  theme_void(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 24, colour = "#3a2a1e"),
        plot.background = element_rect(fill = "#f4efe6", colour = NA),
        legend.position = c(0.92, 0.28))
ggsave("out/possessions_por_municipio.png", p1, width = 11, height = 8.5,
       dpi = 300, bg = "#f4efe6")

# --- 5b. Dispersión población vs possessions --------------------------------
d <- st_drop_geometry(m) |> filter(poblacio > 0)
p2 <- ggplot(d, aes(poblacio, n_poss)) +
  geom_point(aes(size = area_km2), colour = "#b5322e", alpha = 0.6) +
  ggrepel::geom_text_repel(data = subset(d, n_poss > 500 | poblacio > 50000),
                           aes(label = LAU_NAME), size = 3, max.overlaps = 20) +
  scale_x_log10(labels = label_number(big.mark = ".")) +
  scale_size_area(max_size = 12, name = "km²") +
  labs(title = "Possessions vs. població",
       x = "Població empadronada (log)", y = "Nombre de possessions",
       caption = "NGIB × IBESTAT") +
  theme_minimal(base_size = 13)
ggsave("out/possessions_vs_poblacion.png", p2, width = 10, height = 7.5, dpi = 300, bg = "white")

cat("OK -> coropleta, dispersión y municipis_indicadors.csv\n")
print(head(st_drop_geometry(m) |> arrange(desc(poss_km2)) |>
             select(LAU_NAME, n_poss, area_km2, poblacio, poss_km2), 8))
