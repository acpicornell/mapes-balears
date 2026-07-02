.PHONY: help explore extract lookups subsets ibestat kontur ghsl osmhydro worldcover torrents all \
        relief density possessions llogarets crossibestat spikes poblacio balears hydro maps clean

help:
	@echo "NGIB — available targets:"
	@echo "  -- data (nix develop) --"
	@echo "  make explore     Inspect the NGIB API (metadata, schema, count)"
	@echo "  make extract     Download the 55,696 toponyms -> data/processed/ngib_llocs.*"
	@echo "  make lookups     Download the NGIB code tables"
	@echo "  make subsets     Extract possessions/llogarets/nuclis to GeoPackages"
	@echo "  make ibestat     Download municipal population (IBESTAT eDatos)"
	@echo "  make kontur      Download Kontur 400m population (for 3D spikes)"
	@echo "  make ghsl        Download GHS-POP 3 arcsec ~90m population (for relief map)"
	@echo "  make osmhydro    Download OSM torrent network of Mallorca (Geofabrik)"
	@echo "  make worldcover  Download ESA WorldCover 2021 land cover of Mallorca"
	@echo "  make all         extract + lookups + subsets + ibestat"
	@echo "  -- maps (nix develop .#r) --"
	@echo "  make density     Toponym density (hexbin)"
	@echo "  make relief      Hypsometric relief of Mallorca"
	@echo "  make possessions Night portrait of the 16,031 possessions"
	@echo "  make llogarets   The 160 llogarets, labeled"
	@echo "  make crossibestat  Choropleth possessions/100km² + scatter (NGIB×IBESTAT)"
	@echo "  make spikes      3D population spike map (warm, Milos style)"
	@echo "  make poblacio    Blue 3D relief of Mallorca + population as yellow points"
	@echo "  make balears     Population relief triptych of all the Balearic Islands"
	@echo "  make torrents    Derive the complete torrent network from the DEM (WhiteboxTools D8)"
	@echo "  make hydro       Water & land-cover map of Mallorca (torrents + wetlands + vegetation)"
	@echo "  make maps        all maps"
	@echo "  make clean       Delete data/ and out/"

explore:
	bash scripts/01_explore_api.sh

extract:
	bash scripts/02_download_ngib.sh

lookups:
	bash scripts/03_download_lookups.sh

subsets:
	bash scripts/05_ngib_subsets.sh

ibestat:
	bash scripts/04_ibestat_population.sh

kontur:
	bash scripts/06_download_kontur.sh

ghsl:
	bash scripts/07_download_ghsl.sh

osmhydro:
	bash scripts/08_download_hydro.sh

worldcover:
	bash scripts/09_download_worldcover.sh

all: extract lookups subsets ibestat

relief:
	Rscript R/10_relief_mallorca.R

density:
	Rscript R/20_toponym_density.R

possessions:
	Rscript R/40_possessions.R

classify:
	Rscript R/42_finques_classif.R

llogarets:
	Rscript R/41_llogarets.R

crossibestat:
	Rscript R/50_join_ibestat.R

spikes: kontur
	Rscript R/60_population_spikes.R

poblacio: ghsl
	Rscript R/61_population_relief.R

balears: ghsl
	Rscript R/62_population_relief_balears.R

torrents:
	Rscript R/71_derive_torrents.R

hydro: worldcover torrents
	Rscript R/70_hydro_mallorca.R

maps: density relief possessions classify llogarets crossibestat spikes poblacio balears hydro

clean:
	rm -rf data/raw data/processed out
