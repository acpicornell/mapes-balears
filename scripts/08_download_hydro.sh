#!/usr/bin/env bash
# Download the OpenStreetMap hydrography of Mallorca (its torrent network).
# Mallorca has no permanent rivers, but a dense web of seasonal "torrents";
# OSM maps them well and with names. Source: Geofabrik "Islas Baleares" extract.
# We keep the natural watercourses (waterway = stream / river) clipped to the
# Mallorca bbox and reprojected to UTM 31N (EPSG:25831).
# Produces:
#   data/external/balears-latest.osm.pbf   (raw OSM extract, cached)
#   data/external/mallorca_torrents.gpkg    (layer `torrents`)
# Usage: bash scripts/08_download_hydro.sh
source "$(dirname "$0")/lib.sh"
OUT="$ROOT/data/external"; mkdir -p "$OUT"
PBF="$OUT/balears-latest.osm.pbf"
GPKG="$OUT/mallorca_torrents.gpkg"

URL="https://download.geofabrik.de/europe/spain/islas-baleares-latest.osm.pbf"
if [ -s "$PBF" ]; then
  log "$PBF already exists"
else
  log "Downloading OSM extract (Islas Baleares) from Geofabrik..."
  curl -sL -o "$PBF" "$URL"
  log "OK -> $PBF ($(du -h "$PBF" | cut -f1))"
fi

if [ -s "$GPKG" ]; then
  log "$GPKG already exists"
else
  log "Extracting torrents (waterway stream/river) clipped to Mallorca -> UTM 31N..."
  # -spat/-clipsrc are in the source CRS (EPSG:4326): lon 2.28..3.50, lat 39.24..39.99
  ogr2ogr -f GPKG "$GPKG" "$PBF" lines \
    -where "waterway IN ('stream','river')" \
    -spat 2.28 39.24 3.50 39.99 -clipsrc 2.28 39.24 3.50 39.99 \
    -t_srs EPSG:25831 -nln torrents -select "osm_id,name,waterway"
  n=$(ogrinfo -q -so "$GPKG" torrents 2>/dev/null | awk -F= '/Feature Count/{print $2}')
  log "OK -> $GPKG (torrents layer)"
fi
