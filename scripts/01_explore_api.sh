#!/usr/bin/env bash
# Explore the NGIB service: metadata, layers, field schema and total count.
# Usage: bash scripts/01_explore_api.sh
source "$(dirname "$0")/lib.sh"

log "Service: $NGIB_BASE"
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

log "Schema of layer $NGIB_LAYER (Lloc_anomenat)"
fetch "$NGIB_BASE/$NGIB_LAYER?f=json" | jq '{
  name, geometryType, maxRecordCount,
  pagination: .advancedQueryCapabilities.supportsPagination,
  fields: [.fields[] | {name, type, alias}]
}'

log "Total count of place names"
fetch "$NGIB_BASE/$NGIB_LAYER/query?where=1%3D1&returnCountOnly=true&f=json" | jq .
