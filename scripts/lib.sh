#!/usr/bin/env bash
# Configuración común del proyecto NGIB.
set -euo pipefail

# --- Endpoint ArcGIS REST del Nomenclàtor Geogràfic de les Illes Balears ---
# Descubierto en: https://ideib.caib.es/geoserveis/rest/services/public/NGIB/MapServer
export NGIB_BASE="https://ideib.caib.es/geoserveis/rest/services/public/NGIB/MapServer"

# Capa 0 = Lloc_anomenat (topónimos como puntos). CRS nativo EPSG:25831 (ETRS89 / UTM 31N).
export NGIB_LAYER="${NGIB_LAYER:-0}"
export NGIB_SRID="${NGIB_SRID:-25831}"
export PAGE_SIZE="${PAGE_SIZE:-1000}"   # = maxRecordCount del servicio

# Rutas
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT
export RAW="$ROOT/data/raw"
export PROC="$ROOT/data/processed"
export LOOKUPS="$RAW/lookups"

# Descarga robusta con reintentos.
fetch() {
  curl -sS --fail --retry 4 --retry-delay 2 --retry-connrefused -m 120 "$@"
}

log() { printf '\033[36m[ngib]\033[0m %s\n' "$*" >&2; }
