# NGIB — Nomenclàtor Geogràfic de les Illes Balears

**Reproducible** project to (1) extract the full NGIB toponym database
published by IDEIB/ICGIB and (2) generate high-quality maps in the style of
[Milos Agathon](https://github.com/milos-agathon) for the Balearic Islands.

## What the NGIB is

Public ArcGIS REST service of the Govern de les Illes Balears with the official
toponymy (extended INSPIRE model). Source: Mapa Topogràfic 1:5000 + toponymy
nomenclators. **55,696 point toponyms**.

- Endpoint: `https://ideib.caib.es/geoserveis/rest/services/public/NGIB/MapServer`
- Layer 0 `Lloc_anomenat` (points) · native CRS **EPSG:25831** (ETRS89 / UTM 31N)
- `maxRecordCount = 1000`, `supportsPagination = true`
- Main field `GRAFIA` (preferred spelling of the name); INSPIRE/local/
  superlocal types (codes → `Valor_*` tables), `MUNICIPI`, `NUCLI`, `ILLA`, `FONT`...

## Requirements

Everything is handled with **Nix + flakes** (nothing installed globally):

```bash
nix develop          # data shell: curl, jq, gdal (ogr2ogr), make
nix develop .#r      # R shell: sf, terra, rayshader, elevatr, giscoR, MetBrewer...
```

## Quick start

```bash
nix develop
make explore     # inspect the API (metadata, schema, count)
make all         # download toponyms + code tables

nix develop .#r
make density     # out/baleares_densidad_toponimos.png
make relief      # out/mallorca_relieve.png
# 3D (needs OpenGL / xvfb): xvfb-run -a Rscript R/30_rayshader_3d.R
```

## Structure

```
flake.nix                 reproducible environment (2 devShells)
Makefile                  shortcuts
scripts/
  lib.sh                  shared config (endpoint, CRS, fetch with retries)
  01_explore_api.sh       metadata + schema + count
  02_download_ngib.sh     paginated download -> data/processed/ngib_llocs.{gpkg,geojson,csv}
  03_download_lookups.sh  code tables -> data/raw/lookups/*.csv
  04_ibestat_population.sh  IBESTAT municipal population (eDatos) + catalog
  05_ngib_subsets.sh        possessions/llogarets/nuclis -> GeoPackages
  06_download_kontur.sh     Kontur 400m population -> data/external/kontur_ES.gpkg
  07_download_ghsl.sh       GHS-POP 3 arcsec ~90m population -> data/external/ghsl_{mallorca,balears}.tif
R/
  00_packages.R           package check
  10_relief_mallorca.R    2D hillshade relief + peaks (headless-safe)
  20_toponym_density.R    toponym density (hexbin)
  30_rayshader_3d.R       3D rayshader relief (Milos style, needs OpenGL)
  40_possessions.R        night portrait of the 16,031 rural buildings
  42_finques_classif.R    subclassifies 3014 into possessió/casa/caseta (small multiples)
  41_llogarets.R          the 160 llogarets, labeled
  50_join_ibestat.R       NGIB × IBESTAT: choropleth + scatter by municipality
  60_population_spikes.R   3D population spike map (Kontur, warm)
  61_population_relief.R   blue 3D relief of Mallorca + GHS-POP population as yellow points
data/
  raw/pages/              raw GeoJSON pages
  raw/lookups/            code tables (Valor_*, Font...)
  processed/              final GeoPackage/GeoJSON/CSV
out/                      PNG maps
```

## Manual extraction (equivalent, without scripts)

```bash
# Count
curl -s "$B/0/query?where=1=1&returnCountOnly=true&f=json"      # 55696
# One page (offset 0)
curl -s "$B/0/query" --data-urlencode "where=1=1" \
  --data-urlencode "outFields=*" --data-urlencode "outSR=25831" \
  --data-urlencode "resultOffset=0" --data-urlencode "resultRecordCount=1000" \
  --data-urlencode "f=geojson" -G -o p0.geojson
```

`ogr2ogr` also works directly against the endpoint's ESRIJSON driver.

## Monographic studies

NGIB × IBESTAT cross-analysis at the municipal level (see `docs/ESTUDIS.md`):
- **Les possessions** (`TIPUS_LOCAL 3014`) — ⚠️ the code groups 16,031
  *rural buildings* (finca/possessió/casa/caseta); once subclassified by
  toponym morphology, the possessions *stricto sensu* (Son/Rafal/Alqueria)
  are ~**3,068** (2,011 in Mallorca). See `R/42_finques_classif.R`. The Pla de
  Mallorca concentrates the highest density of rural building.
- **Els llogarets** (`TIPUS_LOCAL 3011`, 160 minor nuclei) — labeled map.

Data sources and schemas: `docs/API.md` (NGIB), `docs/IBESTAT.md` (IBESTAT
eDatos), `docs/MILOS.md` (cartographic techniques).

## Data license

The NGIB data belongs to the **ICGIB / Govern de les Illes Balears** (IDEIB).
Reuse is subject to IDEIB's conditions (attribution). Suggested citation:
*"Font: Nomenclàtor Geogràfic de les Illes Balears (NGIB), ICGIB — ideib.caib.es"*.
Check the terms in force at https://ideib.caib.es before redistributing.
