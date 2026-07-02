# NGIB — Nomenclàtor Geogràfic de les Illes Balears

Proyecto **reproducible** para (1) extraer toda la base de topónimos del NGIB
publicada por IDEIB/ICGIB y (2) generar mapas de alta calidad estilo
[Milos Agathon](https://github.com/milos-agathon) para las Islas Baleares.

## Qué es el NGIB

Servicio ArcGIS REST público del Govern de les Illes Balears con la toponimia
oficial (modelo INSPIRE ampliado). Fuente: Mapa Topogràfic 1:5000 + nomenclátors
de toponimia. **55.696 topónimos** puntuales.

- Endpoint: `https://ideib.caib.es/geoserveis/rest/services/public/NGIB/MapServer`
- Capa 0 `Lloc_anomenat` (puntos) · CRS nativo **EPSG:25831** (ETRS89 / UTM 31N)
- `maxRecordCount = 1000`, `supportsPagination = true`
- Campo principal `GRAFIA` (grafía preferente del nombre); tipos INSPIRE/local/
  superlocal (códigos → tablas `Valor_*`), `MUNICIPI`, `NUCLI`, `ILLA`, `FONT`...

## Requisitos

Todo se resuelve con **Nix + flakes** (no instalas nada global):

```bash
nix develop          # shell de datos: curl, jq, gdal (ogr2ogr), make
nix develop .#r      # shell de R: sf, terra, rayshader, elevatr, giscoR, MetBrewer...
```

## Uso rápido

```bash
nix develop
make explore     # inspecciona la API (metadatos, esquema, conteo)
make all         # descarga topónimos + tablas de códigos

nix develop .#r
make density     # out/baleares_densidad_toponimos.png
make relief      # out/mallorca_relieve.png
# 3D (necesita OpenGL / xvfb): xvfb-run -a Rscript R/30_rayshader_3d.R
```

## Estructura

```
flake.nix                 entorno reproducible (2 devShells)
Makefile                  atajos
scripts/
  lib.sh                  config común (endpoint, CRS, fetch con reintentos)
  01_explore_api.sh       metadatos + esquema + conteo
  02_download_ngib.sh     descarga paginada -> data/processed/ngib_llocs.{gpkg,geojson,csv}
  03_download_lookups.sh  tablas de códigos -> data/raw/lookups/*.csv
  04_ibestat_population.sh  población municipal IBESTAT (eDatos) + catálogo
  05_ngib_subsets.sh        possessions/llogarets/nuclis -> GeoPackages
R/
  00_packages.R           check de paquetes
  10_relief_mallorca.R    relieve sombreado 2D + cimas (headless-safe)
  20_toponym_density.R    densidad de topónimos (hexbin)
  30_rayshader_3d.R       relieve 3D rayshader (estilo Milos, necesita OpenGL)
  40_possessions.R        retrato nocturno de las 16.031 possessions
  41_llogarets.R          los 160 llogarets etiquetados
  50_join_ibestat.R       NGIB × IBESTAT: coropleta + scatter por municipio
data/
  raw/pages/              páginas GeoJSON crudas
  raw/lookups/            tablas de códigos (Valor_*, Font...)
  processed/              GeoPackage/GeoJSON/CSV finales
out/                      mapas PNG
```

## Extracción manual (equivalente, sin scripts)

```bash
# Conteo
curl -s "$B/0/query?where=1=1&returnCountOnly=true&f=json"      # 55696
# Una página (offset 0)
curl -s "$B/0/query" --data-urlencode "where=1=1" \
  --data-urlencode "outFields=*" --data-urlencode "outSR=25831" \
  --data-urlencode "resultOffset=0" --data-urlencode "resultRecordCount=1000" \
  --data-urlencode "f=geojson" -G -o p0.geojson
```

También sirve `ogr2ogr` directo sobre el driver ESRIJSON del endpoint.

## Estudios monográficos

Cruce NGIB × IBESTAT a nivel municipal (ver `docs/ESTUDIS.md`):
- **Les possessions** (`TIPUS_LOCAL 3014`, 16.031 fincas/possessions) — retrato
  nocturno + coropleta de densidad. El Pla de Mallorca concentra la mayor
  densidad (Costitx 905/100 km², Montuïri, Sineu, Algaida).
- **Els llogarets** (`TIPUS_LOCAL 3011`, 160 núcleos menores) — mapa etiquetado.

Fuentes de datos y esquemas: `docs/API.md` (NGIB), `docs/IBESTAT.md` (IBESTAT
eDatos), `docs/MILOS.md` (técnicas cartográficas).

## Licencia de los datos

Los datos del NGIB son del **ICGIB / Govern de les Illes Balears** (IDEIB).
Reutilización sujeta a las condiciones de IDEIB (atribución). Cita sugerida:
*"Font: Nomenclàtor Geogràfic de les Illes Balears (NGIB), ICGIB — ideib.caib.es"*.
Verifica los términos vigentes en https://ideib.caib.es antes de redistribuir.
