#!/usr/bin/env bash
# Download the code tables (Valor_*, Font, etc.) to decode the numeric fields
# of the place names layer (TIPUS_INSPIRE, TIPUS_LOCAL, MUNICIPI, ILLA...).
# Each table -> data/raw/lookups/<id>_<name>.csv
#
# Usage: bash scripts/03_download_lookups.sh
source "$(dirname "$0")/lib.sh"
mkdir -p "$LOOKUPS"

# Dynamic list of service tables (ids 3..18).
TABLES_JSON=$(fetch "$NGIB_BASE?f=json")
echo "$TABLES_JSON" | jq -c '.tables[]?' | while read -r t; do
  id=$(echo "$t" | jq -r .id)
  name=$(echo "$t" | jq -r .name | tr ' .' '__')
  out="$LOOKUPS/${id}_${name}.csv"
  log "table $id ($name)"
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
  log "   -> $out ($rows rows)"
done
log "Code tables in $LOOKUPS"
