# Milos Agathon (Milos Popovic) style maps applied to Balears

Milos Popovic (GitHub [@milos-agathon](https://github.com/milos-agathon),
web [milospopovic.net](https://milospopovic.net)) publishes cartography
tutorials in **R** using `ggplot2` + `rayshader`/`rayrender`, `sf`, `terra`.
Each repo ships an `R/` directory with the script and sample data — you clone
them and adapt them by changing the country/region and the data sources.

## Reference repos (verified)

| Repo | Technique | Base dataset |
|------|---------|--------------|
| [3d-river-maps](https://github.com/milos-agathon/3d-river-maps) | 3D relief + rivers | DEM + HydroSHEDS/GloRiC |
| [mapping-river-basins-with-r](https://github.com/milos-agathon/mapping-river-basins-with-r) | river basins | HydroSHEDS |
| [map-rivers-with-sf-and-ggplot2-in-R](https://github.com/milos-agathon/map-rivers-with-sf-and-ggplot2-in-R) | 2D rivers by order | Global River Classification (GloRiC) |
| [3d-forest-height-maps](https://github.com/milos-agathon/3d-forest-height-maps) | 3D canopy height | ETH Global Canopy Height 10 m |
| [3d-forest-type-map](https://github.com/milos-agathon/3d-forest-type-map) | 3D forest type | Copernicus Global Land Cover |
| [deforestation-maps](https://github.com/milos-agathon/deforestation-maps) | forest loss | Global Forest Change (GLAD) |
| [3d-urban-area-maps](https://github.com/milos-agathon/3d-urban-area-maps) | 3D urban areas | GHSL (built-up) |
| [dot-density-maps](https://github.com/milos-agathon/dot-density-maps) | 2D/3D dot-density | any count (NGIB place names!) |
| [relative-elevation-model-maps](https://github.com/milos-agathon/relative-elevation-model-maps) | REM (relative elevation) | DEM + river network |
| [3d-forest-map-ggplot2](https://github.com/milos-agathon/3d-forest-map-ggplot2) | 3D ggplot2→rayshader guide | — |

Base population-density tutorial:
[6 easy ways to map population density in R](https://milospopovic.net/6-ways-to-map-population-with-r.r/).

## The rayshader recipe (the common pattern across all his repos)

```r
library(terra); library(rayshader)
dem <- rast("dem.tif")                 # 1. DEM
mat <- raster_to_matrix(dem)           # 2. raster -> matrix
mat |>
  height_shade(texture = pal) |>       # 3. hypsometric texture
  add_overlay(imagen_datos) |>         # 4. (opt.) thematic layer on top
  add_shadow(ray_shade(mat), 0.3) |>   # 5. shadows
  plot_3d(mat, zscale = 8, ...)        # 6. 3D scene (rgl)
render_highquality("out.png", samples = 300, ...)   # 7. final pathtracing
```

## Data sources for BALEARS

| Layer | Source | How in R |
|------|--------|-----------|
| **Place names** | **NGIB (this repo)** | `sf::st_read("data/processed/ngib_llocs.gpkg")` |
| Administrative boundaries | GISCO/Eurostat (NUTS `ES53`), or IGN | `giscoR::gisco_get_nuts()` |
| DEM (elevation) | AWS Terrain (fast), **Copernicus GLO-30**, or **MDT IGN 5 m** (best) | `elevatr::get_elev_raster(z=10..12)` |
| Population (grid) | **GHSL GHS-POP**, Kontur, WorldPop | `geodata` / direct download |
| Rivers / basins | HydroSHEDS, GloRiC | download by region |
| Land cover/forest | ETH Canopy Height, Copernicus GLC | download by tile |

> For maximum quality in Balears, the **IGN 5 m MDT** (or ICGIB's own MTIB
> 1:5000) beats the global DEM. `elevatr` works well for prototyping.

## How it connects with this project's NGIB

The 55,696 place names are ideal for:
1. **Dot-density / density** (already done: `R/20_toponym_density.R`) — where
   the place names concentrate.
2. **Labelling** a rayshader 3D relief with the peaks of the Serra de
   Tramuntana (Puig Major, Massanella, Galatzó…) by filtering on `GRAFIA`/`TIPUS_LOCAL`.
3. **Thematic maps by INSPIRE category** (hydrography, landforms,
   constructions) coloured by `TIPUS_INSPIRE`.
4. **Density of hydronyms** (torrents, fonts) cross-referenced with the
   HydroSHEDS network.

### Population spike map (the Egypt/Germany one)

`R/60_population_spikes.R` reproduces Milos's iconic 3D map
([making-crisp-spike-maps-with-r](https://github.com/milos-agathon/making-crisp-spike-maps-with-r)):
- Data: **Kontur Population 2023** (400 m H3 hexagons; derived from
  census/padró + GHSL). Download: `scripts/06_download_kontur.sh` (~22 MB for Spain).
- Rasterize population → `height_shade(texture)` → `plot_3d()` → `render_highquality()`.
- Milos's palette: `#0b1354 · #283680 · #6853a9 · #c863b3`.
- **Headless without GPU**: `options(rgl.useNULL = TRUE)` + `rayrender` (CPU pathtracing).
  The flake adds `rayrender`, `dejavu_fonts` and `fontconfig` (titles with `magick`).

> IBESTAT is **not** suitable for this map: its finest geography is
> municipality / entitat singular de població (not a grid), so it would produce
> blocks, not spikes. Kontur/GHSL are the route to the "Egypt" effect. A
> 100%-IBESTAT alternative: one spike per municipality (chunky), if you prefer a
> purely local source.

Scripts in this repo:
- `R/10_relief_mallorca.R` — 2D hypsometric relief + NGIB peaks (headless).
- `R/20_toponym_density.R` — hexbin density of place names (headless).
- `R/30_rayshader_3d.R` — 3D rayshader relief (needs OpenGL/`xvfb-run`).
