#!/usr/bin/env bash
# Download the GHS-POP 2020 (R2023A) population at 3 arcsec (~90 m) clipped to
# the Balearic Islands. It is the fine source for the Milos-style relief maps
# (much more granular than Kontur 400 m). The archipelago spans two GHSL tiles:
#   R5_C19  covers lat [39.10, 49.10]  -> Mallorca and Menorca
#   R6_C19  covers lat [29.10, 39.10]  -> Eivissa and Formentera
# Remote clip/mosaic with GDAL (/vsizip//vsicurl/): downloads only the needed
# window. Produces two files:
#   data/external/ghsl_mallorca.tif  (Mallorca only, for R/61)
#   data/external/ghsl_balears.tif   (whole archipelago, for R/62)
# Usage: bash scripts/07_download_ghsl.sh
source "$(dirname "$0")/lib.sh"
OUT="$ROOT/data/external"; mkdir -p "$OUT"

B="https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2020_GLOBE_R2023A_4326_3ss/V1-0/tiles"
F5="GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0_R5_C19"
F6="GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0_R6_C19"
S5="/vsizip//vsicurl/$B/$F5.zip/$F5.tif"
S6="/vsizip//vsicurl/$B/$F6.zip/$F6.tif"

# -projwin ulx uly lrx lry  (EPSG:4326: minlon maxlat maxlon minlat)
MALL="$OUT/ghsl_mallorca.tif"
if [ -s "$MALL" ]; then
  log "$MALL already exists"
else
  log "Clipping GHS-POP 3 arcsec (~90 m) to Mallorca (window lon 2.30–3.50, lat 39.24–39.98)..."
  gdal_translate -q -projwin 2.30 39.98 3.50 39.24 "$S5" "$MALL"
  log "OK -> $MALL ($(gdalinfo "$MALL" 2>/dev/null | awk '/Size is/{print $3 $4}') px, ~90 m)"
fi

# Whole archipelago: mosaic both tiles (seamless VRT), then clip. gdal_translate
# -projwin does a straight window read, so the original per-cell counts are kept.
BALE="$OUT/ghsl_balears.tif"
if [ -s "$BALE" ]; then
  log "$BALE already exists"
else
  log "Mosaicking GHS-POP tiles R5_C19 + R6_C19 and clipping to the Balearic Islands (lon 1.10–4.45, lat 38.55–40.15)..."
  VRT="$(mktemp -t ghsl_bale.XXXXXX).vrt"
  gdalbuildvrt -q "$VRT" "$S5" "$S6"
  gdal_translate -q -projwin 1.10 40.15 4.45 38.55 "$VRT" "$BALE"
  rm -f "$VRT"
  log "OK -> $BALE ($(gdalinfo "$BALE" 2>/dev/null | awk '/Size is/{print $3 $4}') px, ~90 m)"
fi
