#!/usr/bin/env bash
# Descarga la población de Kontur (hexágonos H3 de 400 m) para España y la deja
# lista para recortar Mallorca. Fuente: Kontur Population 2023 (S3 público).
# ~22 MB comprimido.  Uso: bash scripts/06_download_kontur.sh
source "$(dirname "$0")/lib.sh"
OUT="$ROOT/data/external"; mkdir -p "$OUT"
URL="https://geodata-eu-central-1-kontur-public.s3.amazonaws.com/kontur_datasets/kontur_population_ES_20231101.gpkg.gz"
GZ="$OUT/kontur_ES.gpkg.gz"
GPKG="$OUT/kontur_ES.gpkg"

if [ -s "$GPKG" ]; then log "Ya existe $GPKG"; exit 0; fi
log "Descargando Kontur ES (~22 MB)..."
fetch "$URL" -o "$GZ"
log "Descomprimiendo..."
gunzip -f "$GZ"
log "OK -> $GPKG ($(ogrinfo -so "$GPKG" $(ogrinfo "$GPKG" 2>/dev/null | awk '/^1:/{print $2; exit}') 2>/dev/null | awk -F': ' '/Feature Count/{print $2}') hexágonos)"
