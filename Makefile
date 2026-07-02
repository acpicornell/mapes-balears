.PHONY: help explore extract lookups all relief density clean

help:
	@echo "NGIB — targets disponibles:"
	@echo "  make explore   Inspecciona la API (metadatos, esquema, conteo)"
	@echo "  make extract   Descarga los 55.696 topónimos -> data/processed/ngib_llocs.{gpkg,geojson,csv}"
	@echo "  make lookups   Descarga las tablas de códigos -> data/raw/lookups/*.csv"
	@echo "  make all       extract + lookups"
	@echo "  make relief    (shell R) Mapa 3D de relieve de Mallorca (rayshader)"
	@echo "  make density   (shell R) Mapa de densidad de topónimos"
	@echo "  make clean      Borra data/ y out/"

explore:
	bash scripts/01_explore_api.sh

extract:
	bash scripts/02_download_ngib.sh

lookups:
	bash scripts/03_download_lookups.sh

all: extract lookups

relief:
	Rscript R/10_relief_mallorca.R

density:
	Rscript R/20_toponym_density.R

clean:
	rm -rf data/raw data/processed out
