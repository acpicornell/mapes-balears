.PHONY: help explore extract lookups subsets ibestat all \
        relief density possessions llogarets crossibestat maps clean

help:
	@echo "NGIB — targets disponibles:"
	@echo "  -- datos (nix develop) --"
	@echo "  make explore     Inspecciona la API NGIB (metadatos, esquema, conteo)"
	@echo "  make extract     Descarga los 55.696 topónimos -> data/processed/ngib_llocs.*"
	@echo "  make lookups     Descarga las tablas de códigos NGIB"
	@echo "  make subsets     Extrae possessions/llogarets/nuclis a GeoPackages"
	@echo "  make ibestat     Descarga población municipal (IBESTAT eDatos)"
	@echo "  make kontur      Descarga población Kontur 400m (para spikes 3D)"
	@echo "  make all         extract + lookups + subsets + ibestat"
	@echo "  -- mapas (nix develop .#r) --"
	@echo "  make density     Densidad de topónimos (hexbin)"
	@echo "  make relief      Relieve hipsométrico de Mallorca"
	@echo "  make possessions Retrato nocturno de las 16.031 possessions"
	@echo "  make llogarets   Los 160 llogarets etiquetados"
	@echo "  make crossibestat  Coropleta possessions/100km² + scatter (NGIB×IBESTAT)"
	@echo "  make spikes      Mapa 3D de spikes de población (estilo Milos/Egipto)"
	@echo "  make maps        todos los mapas"
	@echo "  make clean       Borra data/ y out/"

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

maps: density relief possessions classify llogarets crossibestat spikes

clean:
	rm -rf data/raw data/processed out
