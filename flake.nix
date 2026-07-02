{
  description = "NGIB — Nomenclàtor Geogràfic de les Illes Balears: extracción reproducible + mapas estilo Milos Agathon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # ---- Shell ligero: pipeline de datos (extracción NGIB) ----
        dataTools = with pkgs; [
          curl
          jq
          gdal          # ogr2ogr, ogrinfo, gdalwarp...
          coreutils
          gnumake
        ];

        # ---- Shell de R: cartografía estilo Milos Agathon ----
        # OJO: rayshader + tidyverse compilan mucho la primera vez.
        rPkgs = with pkgs.rPackages; [
          sf terra stars
          tidyverse       # incluye ggplot2, dplyr, readr, tidyr...
          hexbin          # stat_bin_hex (mapa de densidad)
          ragg            # backend PNG de alta calidad
          jsonlite        # parseo de la API JSON de IBESTAT
          ggrepel         # etiquetas sin solapamiento
          rayshader
          elevatr
          giscoR
          ggspatial
          classInt
          scales
          colorspace
          MetBrewer       # paletas tipo Milos Agathon
          magick
          geodata
        ];
        rEnv = pkgs.rWrapper.override { packages = rPkgs; };
      in
      {
        devShells = {
          # nix develop            -> herramientas de datos (rápido)
          default = pkgs.mkShell {
            buildInputs = dataTools;
            shellHook = ''
              echo "== NGIB data shell =="
              echo "gdal: $(ogr2ogr --version)"
              echo "Ejecuta:  make extract   (descarga los 55.696 topónimos)"
            '';
          };

          # nix develop .#r        -> R + rayshader/sf/terra (compila la 1ª vez)
          r = pkgs.mkShell {
            buildInputs = dataTools ++ [ rEnv pkgs.pandoc ];
            shellHook = ''
              echo "== NGIB R shell (cartografía) =="
              echo "R con: sf, terra, rayshader, elevatr, giscoR, MetBrewer..."
              echo "Ejecuta:  Rscript R/10_relief_mallorca.R"
            '';
          };
        };
      });
}
