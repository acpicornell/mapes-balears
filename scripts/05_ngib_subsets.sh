#!/usr/bin/env bash
# Extrae subconjuntos temáticos del NGIB a GeoPackages independientes usando el
# GeoPackage global (data/processed/ngib_llocs.gpkg) y ogr2ogr + SQL.
#
#   possessions  = TIPUS_LOCAL 3014 (Finca, possessió, lloc, casa pagesa, caseta)
#   llogarets    = TIPUS_LOCAL 3011 (Altre nucli de població, llogaret)
#   nuclis       = TIPUS_LOCAL 3010 (capital de municipi)
#
# Uso: bash scripts/05_ngib_subsets.sh
source "$(dirname "$0")/lib.sh"
SRC="$PROC/ngib_llocs.gpkg"
[ -s "$SRC" ] || { echo "Falta $SRC — ejecuta scripts/02_download_ngib.sh"; exit 1; }

extract() {  # nombre  codigo
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
