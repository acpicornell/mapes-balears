# Mapas estilo Milos Agathon (Milos Popovic) aplicados a Baleares

Milos Popovic (GitHub [@milos-agathon](https://github.com/milos-agathon),
web [milospopovic.net](https://milospopovic.net)) publica tutoriales de
cartografía en **R** con `ggplot2` + `rayshader`/`rayrender`, `sf`, `terra`.
Cada repo trae `R/` con el script y datos de ejemplo — se clonan y se adaptan
cambiando el país/región y las fuentes de datos.

## Repos de referencia (verificados)

| Repo | Técnica | Dataset base |
|------|---------|--------------|
| [3d-river-maps](https://github.com/milos-agathon/3d-river-maps) | relieve 3D + ríos | DEM + HydroSHEDS/GloRiC |
| [mapping-river-basins-with-r](https://github.com/milos-agathon/mapping-river-basins-with-r) | cuencas fluviales | HydroSHEDS |
| [map-rivers-with-sf-and-ggplot2-in-R](https://github.com/milos-agathon/map-rivers-with-sf-and-ggplot2-in-R) | ríos 2D por orden | Global River Classification (GloRiC) |
| [3d-forest-height-maps](https://github.com/milos-agathon/3d-forest-height-maps) | altura de dosel 3D | ETH Global Canopy Height 10 m |
| [3d-forest-type-map](https://github.com/milos-agathon/3d-forest-type-map) | tipo de bosque 3D | Copernicus Global Land Cover |
| [deforestation-maps](https://github.com/milos-agathon/deforestation-maps) | pérdida forestal | Global Forest Change (GLAD) |
| [3d-urban-area-maps](https://github.com/milos-agathon/3d-urban-area-maps) | zonas urbanas 3D | GHSL (built-up) |
| [dot-density-maps](https://github.com/milos-agathon/dot-density-maps) | dot-density 2D/3D | cualquier conteo (¡topónimos NGIB!) |
| [relative-elevation-model-maps](https://github.com/milos-agathon/relative-elevation-model-maps) | REM (elevación relativa) | DEM + red fluvial |
| [3d-forest-map-ggplot2](https://github.com/milos-agathon/3d-forest-map-ggplot2) | guía 3D ggplot2→rayshader | — |

Tutorial base de densidad de población:
[6 easy ways to map population density in R](https://milospopovic.net/6-ways-to-map-population-with-r.r/).

## La receta rayshader (patrón común de todos sus repos)

```r
library(terra); library(rayshader)
dem <- rast("dem.tif")                 # 1. DEM
mat <- raster_to_matrix(dem)           # 2. raster -> matriz
mat |>
  height_shade(texture = pal) |>       # 3. textura hipsométrica
  add_overlay(imagen_datos) |>         # 4. (opc.) capa temática encima
  add_shadow(ray_shade(mat), 0.3) |>   # 5. sombras
  plot_3d(mat, zscale = 8, ...)        # 6. escena 3D (rgl)
render_highquality("out.png", samples = 300, ...)   # 7. pathtracing final
```

## Fuentes de datos para BALEARES

| Capa | Fuente | Cómo en R |
|------|--------|-----------|
| **Topónimos** | **NGIB (este repo)** | `sf::st_read("data/processed/ngib_llocs.gpkg")` |
| Límites administrativos | GISCO/Eurostat (NUTS `ES53`), o IGN | `giscoR::gisco_get_nuts()` |
| DEM (elevación) | AWS Terrain (rápido), **Copernicus GLO-30**, o **MDT IGN 5 m** (mejor) | `elevatr::get_elev_raster(z=10..12)` |
| Población (grid) | **GHSL GHS-POP**, Kontur, WorldPop | `geodata` / descarga directa |
| Ríos / cuencas | HydroSHEDS, GloRiC | descarga por región |
| Cobertura/bosque | ETH Canopy Height, Copernicus GLC | descarga por tile |

> Para máxima calidad en Baleares, el **MDT del IGN a 5 m** (o el MTIB 1:5000 del
> propio ICGIB) supera al DEM global. `elevatr` va bien para prototipar.

## Cómo se conecta con el NGIB de este proyecto

Los 55.696 topónimos son ideales para:
1. **Dot-density / densidad** (ya hecho: `R/20_toponym_density.R`) — dónde se
   concentran los nombres de lugar.
2. **Etiquetado** de un relieve 3D rayshader con las cimas de la Serra de
   Tramuntana (Puig Major, Massanella, Galatzó…) filtrando por `GRAFIA`/`TIPUS_LOCAL`.
3. **Mapas temáticos por categoría INSPIRE** (hidrografía, accidentes
   geográficos, construcciones) coloreando por `TIPUS_INSPIRE`.
4. **Densidad de hidrónimos** (torrents, fonts) cruzando con la red HydroSHEDS.

### Mapa de spikes de población (el de Egipto/Alemania)

`R/60_population_spikes.R` replica el mapa 3D icónico de Milos
([making-crisp-spike-maps-with-r](https://github.com/milos-agathon/making-crisp-spike-maps-with-r)):
- Datos: **Kontur Population 2023** (hexágonos H3 de 400 m; derivado de censo/padró
  + GHSL). Descarga: `scripts/06_download_kontur.sh` (~22 MB para España).
- Rasterizar población → `height_shade(texture)` → `plot_3d()` → `render_highquality()`.
- Paleta de Milos: `#0b1354 · #283680 · #6853a9 · #c863b3`.
- **Headless sin GPU**: `options(rgl.useNULL = TRUE)` + `rayrender` (pathtracing CPU).
  El flake añade `rayrender`, `dejavu_fonts` y `fontconfig` (títulos con `magick`).

> IBESTAT **no** sirve para este mapa: su geografía más fina es municipio /
> entitat singular de població (no una malla), así que daría bloques, no spikes.
> Kontur/GHSL son la vía para el efecto "Egipto". Alternativa 100%-IBESTAT:
> una aguja por municipio (chunky), si se prefiere fuente puramente local.

Scripts de este repo:
- `R/10_relief_mallorca.R` — relieve 2D hipsométrico + cimas NGIB (headless).
- `R/20_toponym_density.R` — densidad hexbin de topónimos (headless).
- `R/30_rayshader_3d.R` — relieve 3D rayshader (necesita OpenGL/`xvfb-run`).
