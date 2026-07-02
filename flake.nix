{
  description = "NGIB — Nomenclàtor Geogràfic de les Illes Balears: reproducible extraction + Milos Agathon-style maps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # ---- Lightweight shell: data pipeline (NGIB extraction) ----
        dataTools = with pkgs; [
          curl
          jq
          gdal          # ogr2ogr, ogrinfo, gdalwarp...
          coreutils
          gnumake
        ];

        # ---- R shell: Milos Agathon-style cartography ----
        # NOTE: rayshader + tidyverse take a long time to compile the first time.
        rPkgs = with pkgs.rPackages; [
          sf terra stars
          tidyverse       # includes ggplot2, dplyr, readr, tidyr...
          hexbin          # stat_bin_hex (density map)
          ragg            # high-quality PNG backend
          jsonlite        # parsing the IBESTAT JSON API
          ggrepel         # non-overlapping labels
          rayshader
          rayrender       # CPU pathtracing (render_highquality, no GPU)
          elevatr
          giscoR
          ggspatial
          classInt
          scales
          colorspace
          MetBrewer       # Milos Agathon-style palettes
          magick
          geodata
        ];
        rEnv = pkgs.rWrapper.override { packages = rPkgs; };
      in
      {
        devShells = {
          # nix develop            -> data tools (fast)
          default = pkgs.mkShell {
            buildInputs = dataTools;
            shellHook = ''
              echo "== NGIB data shell =="
              echo "gdal: $(ogr2ogr --version)"
              echo "Run:  make extract   (downloads the 55,696 toponyms)"
            '';
          };

          # nix develop .#r        -> R + rayshader/sf/terra (compiles the 1st time)
          r = pkgs.mkShell {
            buildInputs = dataTools ++ [
              rEnv pkgs.pandoc pkgs.dejavu_fonts pkgs.fontconfig
            ];
            # fontconfig so magick/ggplot can find fonts (titles)
            FONTCONFIG_FILE = pkgs.makeFontsConf {
              fontDirectories = [ pkgs.dejavu_fonts ];
            };
            shellHook = ''
              echo "== NGIB R shell (cartography) =="
              echo "R with: sf, terra, rayshader, elevatr, giscoR, MetBrewer..."
              echo "Run:  Rscript R/10_relief_mallorca.R"
            '';
          };
        };
      });
}
