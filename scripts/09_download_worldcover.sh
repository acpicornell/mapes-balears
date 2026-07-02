#!/usr/bin/env bash
# ESA WorldCover 2021 v200 (10 m land cover) for Mallorca. One authoritative
# raster that carries both vegetation (tree cover / shrubland / grassland /
# cropland) and water (permanent water + herbaceous wetland: s'Albufera,
# es Salobrar de Campos, the Cúber / Gorg Blau reservoirs). It is a mosaic of
# the two 3x3° tiles that meet at 3°E, clipped to Mallorca and downsampled to
# ~30 m with mode resampling (categorical) to stay light.
# Output: data/external/mallorca_worldcover.tif  (EPSG:4326, class codes)
# Usage: bash scripts/09_download_worldcover.sh
source "$(dirname "$0")/lib.sh"
OUT="$ROOT/data/external"; mkdir -p "$OUT"
TIF="$OUT/mallorca_worldcover.tif"

B="https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map"
T0="/vsicurl/$B/ESA_WorldCover_10m_2021_v200_N39E000_Map.tif"
T3="/vsicurl/$B/ESA_WorldCover_10m_2021_v200_N39E003_Map.tif"

if [ -s "$TIF" ]; then log "$TIF already exists"; exit 0; fi
log "Mosaicking + clipping ESA WorldCover to Mallorca (~30 m, mode resampling)..."
VRT="$(mktemp -t wc.XXXXXX).vrt"
gdalbuildvrt -q "$VRT" "$T0" "$T3"
gdalwarp -q -te 2.27 39.24 3.51 40.01 -tr 0.00028 0.00028 -r mode \
  -co COMPRESS=DEFLATE "$VRT" "$TIF"
rm -f "$VRT"
log "OK -> $TIF ($(gdalinfo "$TIF" 2>/dev/null | awk '/Size is/{print $3 $4}') px)"
