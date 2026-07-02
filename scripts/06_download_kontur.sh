#!/usr/bin/env bash
# Download the Kontur population (400 m H3 hexagons) for Spain and leave it
# ready to clip Mallorca. Source: Kontur Population 2023 (public S3).
# ~22 MB compressed.  Usage: bash scripts/06_download_kontur.sh
source "$(dirname "$0")/lib.sh"
OUT="$ROOT/data/external"; mkdir -p "$OUT"
URL="https://geodata-eu-central-1-kontur-public.s3.amazonaws.com/kontur_datasets/kontur_population_ES_20231101.gpkg.gz"
GZ="$OUT/kontur_ES.gpkg.gz"
GPKG="$OUT/kontur_ES.gpkg"

if [ -s "$GPKG" ]; then log "$GPKG already exists"; exit 0; fi
log "Downloading Kontur ES (~22 MB)..."
fetch "$URL" -o "$GZ"
log "Decompressing..."
gunzip -f "$GZ"
log "OK -> $GPKG ($(ogrinfo -so "$GPKG" $(ogrinfo "$GPKG" 2>/dev/null | awk '/^1:/{print $2; exit}') 2>/dev/null | awk -F': ' '/Feature Count/{print $2}') hexagons)"
