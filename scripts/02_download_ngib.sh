#!/usr/bin/env bash
# Descarga COMPLETA de los topónimos del NGIB (capa Lloc_anomenat) por paginación.
# Estrategia: bucle sobre resultOffset (soportado: supportsPagination=true),
#   f=geojson, outSR=25831, outFields=*  ->  páginas GeoJSON  ->  merge a GeoPackage.
#
# Salidas en data/processed/:
#   ngib_llocs.gpkg     (GeoPackage, capa 'llocs')  <- formato de trabajo
#   ngib_llocs.geojson  (GeoJSON WGS84, para web/inspección)
#   ngib_llocs.csv      (atributos + X/Y en 25831)
#
# Uso: bash scripts/02_download_ngib.sh
source "$(dirname "$0")/lib.sh"

mkdir -p "$RAW/pages" "$PROC"
Q="$NGIB_BASE/$NGIB_LAYER/query"

TOTAL=$(fetch "$Q?where=1%3D1&returnCountOnly=true&f=json" | jq -r .count)
log "Topónimos a descargar: $TOTAL (páginas de $PAGE_SIZE)"

offset=0
page=0
while [ "$offset" -lt "$TOTAL" ]; do
  out=$(printf '%s/pages/p_%05d.geojson' "$RAW" "$offset")
  if [ ! -s "$out" ]; then
    fetch "$Q" \
      --data-urlencode "where=1=1" \
      --data-urlencode "outFields=*" \
      --data-urlencode "returnGeometry=true" \
      --data-urlencode "outSR=$NGIB_SRID" \
      --data-urlencode "resultOffset=$offset" \
      --data-urlencode "resultRecordCount=$PAGE_SIZE" \
      --data-urlencode "f=geojson" \
      -G -o "$out"
    n=$(jq '.features | length' "$out")
    log "  offset $offset -> $n features"
    [ "$n" -eq 0 ] && { log "página vacía, fin anticipado"; break; }
  fi
  offset=$((offset + PAGE_SIZE))
  page=$((page + 1))
done

log "Fusionando $(ls "$RAW"/pages/*.geojson | wc -l) páginas -> GeoPackage"
GPKG="$PROC/ngib_llocs.gpkg"
rm -f "$GPKG"
first=1
for f in "$RAW"/pages/p_*.geojson; do
  if [ "$first" -eq 1 ]; then
    ogr2ogr -f GPKG "$GPKG" "$f" -nln llocs -a_srs "EPSG:$NGIB_SRID"
    first=0
  else
    ogr2ogr -f GPKG -update -append "$GPKG" "$f" -nln llocs
  fi
done

CNT=$(ogrinfo -so "$GPKG" llocs | awk -F': ' '/Feature Count/{print $2}')
log "GeoPackage listo: $GPKG  ($CNT features)"

# Derivados
ogr2ogr -f GeoJSON "$PROC/ngib_llocs.geojson" "$GPKG" -t_srs EPSG:4326
ogr2ogr -f CSV "$PROC/ngib_llocs.csv" "$GPKG" -lco GEOMETRY=AS_XY
log "Derivados: ngib_llocs.geojson (WGS84) y ngib_llocs.csv"
