#!/usr/bin/env bash
# Descarga población municipal empadronada (IBESTAT, plataforma eDatos/METAMAC).
# Dataset 000001A_000001: "Població municipal empadronada segons el sexe.
#   Municipis de les Illes Balears per anys" (67 municipios × años × sexo).
# API: https://ibestat.es/edatos/apis/statistical-resources/v1.0
#
# Guarda el JSON crudo del último año -> data/raw/ibestat/pob_municipi.json
# (se parsea en R/50_join_ibestat.R). Reproducible.
#
# Uso: bash scripts/04_ibestat_population.sh [ANY]   (por defecto 2025)
source "$(dirname "$0")/lib.sh"
YEAR="${1:-2025}"
IBE="https://ibestat.es/edatos/apis/statistical-resources/v1.0"
DS="000001A_000001"
OUT="$RAW/ibestat"; mkdir -p "$OUT"

log "IBESTAT: población municipal $YEAR (dataset $DS)"
# Filtramos por año y por la medida absoluta (POBLACION_PADRON).
# SEXO viene con _T/M/F; el _T (total) se selecciona luego en R.
fetch -H "Accept: application/json" \
  "$IBE/datasets/IBESTAT/$DS/~latest?dim=TIME_PERIOD:$YEAR|MEDIDAS:POBLACION_PADRON" \
  -o "$OUT/pob_municipi.json"

n=$(jq -r '.data.observations | split(" ") | map(select(.!="")) | length' "$OUT/pob_municipi.json")
log "  observaciones: $n (esperado 67 municipios × 3 sexos = 201)"
log "  -> $OUT/pob_municipi.json"

# Guardamos también el catálogo de datasets (útil para explorar los 4150).
log "Volcando catálogo de datasets IBESTAT -> $OUT/catalogo_datasets.csv"
fetch -H "Accept: application/json" "$IBE/datasets/IBESTAT?limit=5000" \
  | jq -r '.dataset[] | [.id, (.name.text[] | select(.lang=="ca") | .value)] | @csv' \
  > "$OUT/catalogo_datasets.csv"
log "  catálogo: $(wc -l < "$OUT/catalogo_datasets.csv") datasets"
