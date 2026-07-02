#!/usr/bin/env bash
# Download the GHS-POP 2020 (R2023A) population at 3 arcsec (~90 m) clipped to
# Mallorca. It is the fine source for the Milos "Egypt-style" map (much more
# granular than Kontur 400 m). The R5_C19 tile covers lat [39.10,49.10], lon [0,10].
# Remote clip with GDAL (/vsizip//vsicurl/): downloads only the needed window.
# Usage: bash scripts/07_download_ghsl.sh
source "$(dirname "$0")/lib.sh"
OUT="$ROOT/data/external"; mkdir -p "$OUT"
TIF="$OUT/ghsl_mallorca.tif"

F="GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0_R5_C19"
B="https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2020_GLOBE_R2023A_4326_3ss/V1-0/tiles"
SRC="/vsizip//vsicurl/$B/$F.zip/$F.tif"

if [ -s "$TIF" ]; then log "$TIF already exists"; exit 0; fi
log "Clipping GHS-POP 3 arcsec (~90 m) to Mallorca (window lon 2.30–3.50, lat 39.24–39.98)..."
# -projwin ulx uly lrx lry  (EPSG:4326: minlon maxlat maxlon minlat)
gdal_translate -q -projwin 2.30 39.98 3.50 39.24 "$SRC" "$TIF"
log "OK -> $TIF ($(gdalinfo "$TIF" 2>/dev/null | awk '/Size is/{print $3 $4}') px, ~90 m)"
