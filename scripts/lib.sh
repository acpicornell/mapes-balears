#!/usr/bin/env bash
# Common configuration for the NGIB project.
set -euo pipefail

# --- ArcGIS REST endpoint of the Nomenclàtor Geogràfic de les Illes Balears ---
# Discovered at: https://ideib.caib.es/geoserveis/rest/services/public/NGIB/MapServer
export NGIB_BASE="https://ideib.caib.es/geoserveis/rest/services/public/NGIB/MapServer"

# Layer 0 = Lloc_anomenat (place names as points). Native CRS EPSG:25831 (ETRS89 / UTM 31N).
export NGIB_LAYER="${NGIB_LAYER:-0}"
export NGIB_SRID="${NGIB_SRID:-25831}"
export PAGE_SIZE="${PAGE_SIZE:-1000}"   # = service maxRecordCount

# Paths
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT
export RAW="$ROOT/data/raw"
export PROC="$ROOT/data/processed"
export LOOKUPS="$RAW/lookups"

# Robust download with retries.
fetch() {
  curl -sS --fail --retry 4 --retry-delay 2 --retry-connrefused -m 120 "$@"
}

log() { printf '\033[36m[ngib]\033[0m %s\n' "$*" >&2; }
