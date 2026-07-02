#!/usr/bin/env bash
# Explora el servicio NGIB: metadatos, capas, esquema de campos y conteo total.
# Uso: bash scripts/01_explore_api.sh
source "$(dirname "$0")/lib.sh"

log "Servicio: $NGIB_BASE"
fetch "$NGIB_BASE?f=json" | jq '{
  descripcio: (.serviceDescription | .[0:200]),
  copyright: .copyrightText,
  maxRecordCount,
  capabilities,
  crs: .spatialReference,
  extent: .fullExtent,
  capes: [.layers[] | {id, name, geometryType}],
  taules: [.tables[]? | {id, name}]
}'

log "Esquema de la capa $NGIB_LAYER (Lloc_anomenat)"
fetch "$NGIB_BASE/$NGIB_LAYER?f=json" | jq '{
  name, geometryType, maxRecordCount,
  pagination: .advancedQueryCapabilities.supportsPagination,
  fields: [.fields[] | {name, type, alias}]
}'

log "Conteo total de topónimos"
fetch "$NGIB_BASE/$NGIB_LAYER/query?where=1%3D1&returnCountOnly=true&f=json" | jq .
