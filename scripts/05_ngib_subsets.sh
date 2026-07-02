#!/usr/bin/env bash
# Extract thematic subsets of the NGIB into independent GeoPackages using the
# global GeoPackage (data/processed/ngib_llocs.gpkg) and ogr2ogr + SQL.
#
#   possessions  = TIPUS_LOCAL 3014 (Finca, possessió, lloc, casa pagesa, caseta)
#   llogarets    = TIPUS_LOCAL 3011 (Altre nucli de població, llogaret)
#   nuclis       = TIPUS_LOCAL 3010 (municipality capital)
#
# Usage: bash scripts/05_ngib_subsets.sh
source "$(dirname "$0")/lib.sh"
SRC="$PROC/ngib_llocs.gpkg"
[ -s "$SRC" ] || { echo "Missing $SRC — run scripts/02_download_ngib.sh"; exit 1; }

extract() {  # name  code
  local name="$1" code="$2"
  ogr2ogr -f GPKG "$PROC/ngib_${name}.gpkg" "$SRC" \
    -sql "SELECT GRAFIA, MUNICIPI, NUCLI, ILLA, TIPUS_LOCAL, TIPUS_INSPIRE, geom FROM llocs WHERE TIPUS_LOCAL = $code" \
    -nln "$name"
  local n; n=$(ogrinfo -so "$PROC/ngib_${name}.gpkg" "$name" | awk -F': ' '/Feature Count/{print $2}')
  log "$name (TIPUS_LOCAL $code): $n -> $PROC/ngib_${name}.gpkg"
}

extract possessions 3014
extract llogarets   3011
extract nuclis      3010
