#!/usr/bin/env bash
# Download registered municipal population (IBESTAT, eDatos/METAMAC platform).
# Dataset 000001A_000001: "Població municipal empadronada segons el sexe.
#   Municipis de les Illes Balears per anys" (67 municipalities × years × sex).
# API: https://ibestat.es/edatos/apis/statistical-resources/v1.0
#
# Saves the raw JSON of the latest year -> data/raw/ibestat/pob_municipi.json
# (parsed in R/50_join_ibestat.R). Reproducible.
#
# Usage: bash scripts/04_ibestat_population.sh [YEAR]   (default 2025)
source "$(dirname "$0")/lib.sh"
YEAR="${1:-2025}"
IBE="https://ibestat.es/edatos/apis/statistical-resources/v1.0"
DS="000001A_000001"
OUT="$RAW/ibestat"; mkdir -p "$OUT"

log "IBESTAT: municipal population $YEAR (dataset $DS)"
# We filter by year and by the absolute measure (POBLACION_PADRON).
# SEXO comes with _T/M/F; the _T (total) is selected later in R.
fetch -H "Accept: application/json" \
  "$IBE/datasets/IBESTAT/$DS/~latest?dim=TIME_PERIOD:$YEAR|MEDIDAS:POBLACION_PADRON" \
  -o "$OUT/pob_municipi.json"

n=$(jq -r '.data.observations | split(" ") | map(select(.!="")) | length' "$OUT/pob_municipi.json")
log "  observations: $n (expected 67 municipalities × 3 sexes = 201)"
log "  -> $OUT/pob_municipi.json"

# We also save the dataset catalog (useful to explore the 4150).
log "Dumping IBESTAT dataset catalog -> $OUT/catalogo_datasets.csv"
fetch -H "Accept: application/json" "$IBE/datasets/IBESTAT?limit=5000" \
  | jq -r '.dataset[] | [.id, (.name.text[] | select(.lang=="ca") | .value)] | @csv' \
  > "$OUT/catalogo_datasets.csv"
log "  catalog: $(wc -l < "$OUT/catalogo_datasets.csv") datasets"
