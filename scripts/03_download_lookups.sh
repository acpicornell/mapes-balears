#!/usr/bin/env bash
# Descarga las tablas de códigos (Valor_*, Font, etc.) para decodificar los campos
# numéricos de la capa de topónimos (TIPUS_INSPIRE, TIPUS_LOCAL, MUNICIPI, ILLA...).
# Cada tabla -> data/raw/lookups/<id>_<nombre>.csv
#
# Uso: bash scripts/03_download_lookups.sh
source "$(dirname "$0")/lib.sh"
mkdir -p "$LOOKUPS"

# Lista dinámica de tablas del servicio (ids 3..18).
TABLES_JSON=$(fetch "$NGIB_BASE?f=json")
echo "$TABLES_JSON" | jq -c '.tables[]?' | while read -r t; do
  id=$(echo "$t" | jq -r .id)
  name=$(echo "$t" | jq -r .name | tr ' .' '__')
  out="$LOOKUPS/${id}_${name}.csv"
  log "tabla $id ($name)"
  fetch "$NGIB_BASE/$id/query" \
    --data-urlencode "where=1=1" \
    --data-urlencode "outFields=*" \
    --data-urlencode "returnGeometry=false" \
    --data-urlencode "f=json" -G \
  | jq -r '
      (.fields | map(.name)) as $h
      | ($h | @csv),
        (.features[].attributes | [ .[ $h[] ] ] | @csv)
    ' > "$out"
  rows=$(( $(wc -l < "$out") - 1 ))
  log "   -> $out ($rows filas)"
done
log "Tablas de códigos en $LOOKUPS"
