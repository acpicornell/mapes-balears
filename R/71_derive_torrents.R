#!/usr/bin/env Rscript
# ============================================================================
# Derive Mallorca's COMPLETE torrent network from the DEM (D8 flow routing),
# instead of the fragmented OSM data. Pipeline (WhiteboxTools, via Nix):
#   fill depressions -> D8 pointer -> D8 flow accumulation ->
#   extract streams (drainage-area threshold) -> Strahler order -> vectorise.
# Every channel is topologically connected and drains to the sea. Strahler
# order is kept so the trunks can be drawn thicker than the headwaters.
# The sea is set to NoData so the coast acts as the drainage outlet.
# Output: data/external/mallorca_torrents_dem.gpkg  (layer `torrents`, field `order`)
# ============================================================================
options(rgl.useNULL = TRUE)
suppressPackageStartupMessages({
  library(sf); library(terra); library(elevatr); library(giscoR)
})
draft <- nchar(Sys.getenv("DRAFT")) > 0
zdem  <- if (draft) 10 else 11
area_km2 <- as.numeric(Sys.getenv("DRAINAGE_KM2", "0.5"))   # min drainage to start a channel

if (nchar(Sys.which("whitebox_tools")) == 0)
  stop("whitebox_tools not found — run inside `nix develop .#r`")

# --- Mallorca DEM (sea -> NoData = drainage outlet at the coast) -------------
bbox <- st_bbox(c(xmin = 437000, ymin = 4338000, xmax = 547000, ymax = 4428000),
                crs = 25831)
gadm_bale <- geodata::gadm("ESP", level = 1, path = "data/external/gadm")
gadm_bale <- gadm_bale[grepl("Balear", gadm_bale$NAME_1, ignore.case = TRUE), ]
mallorca  <- crop(project(gadm_bale, "EPSG:25831"),
                  ext(437000, 547000, 4338000, 4428000))
dem <- get_elev_raster(st_as_sf(st_as_sfc(bbox)), z = zdem, clip = "bbox") |> rast()
dem <- crop(dem, mallorca); dem[dem < 0] <- 0
dem <- mask(dem, mallorca)

wd <- normalizePath("data/external")
writeRaster(dem, file.path(wd, "_dem.tif"), overwrite = TRUE,
            datatype = "FLT4S", NAflag = -9999)
thr <- round(area_km2 * 1e6 / prod(res(dem)))          # threshold in cells
cat("DEM z", zdem, "·", paste(dim(dem)[1:2], collapse = "x"),
    "· cell", round(mean(res(dem))), "m · threshold", thr, "cells (", area_km2, "km2 )\n")

# --- WhiteboxTools D8 pipeline -----------------------------------------------
wbt <- function(tool, ...) {
  st <- system2("whitebox_tools",
                c(paste0("-r=", tool), paste0("--wd=", wd), ...),
                stdout = FALSE, stderr = FALSE)
  if (st != 0) stop("whitebox_tools ", tool, " failed (exit ", st, ")")
}
wbt("FillDepressions",       "--dem=_dem.tif",   "--output=_fill.tif", "--fix_flats")
wbt("D8Pointer",             "--dem=_fill.tif",  "--output=_pntr.tif")
wbt("D8FlowAccumulation",    "--input=_fill.tif","--output=_acc.tif", "--out_type=cells")
wbt("ExtractStreams",        "--flow_accum=_acc.tif", "--output=_streams.tif",
    paste0("--threshold=", thr), "--zero_background")
wbt("StrahlerStreamOrder",   "--d8_pntr=_pntr.tif", "--streams=_streams.tif",
    "--output=_order.tif", "--zero_background")
wbt("RasterStreamsToVector", "--streams=_order.tif", "--d8_pntr=_pntr.tif",
    "--output=_torrents.shp")

# --- Read, assign CRS + Strahler order per reach, save -----------------------
v <- st_read(file.path(wd, "_torrents.shp"), quiet = TRUE)
st_crs(v) <- 25831                                     # WBT writes no .prj; DEM is UTM 31N
ordr <- rast(file.path(wd, "_order.tif"))
ex <- terra::extract(ordr, vect(v))                    # order value(s) per reach
ag <- tapply(ex[, 2], ex[, 1], function(z) max(z, na.rm = TRUE))
v$order <- as.numeric(ag[as.character(seq_len(nrow(v)))])
v$order[!is.finite(v$order)] <- 1
v <- v[, "order"]
st_write(v, file.path(wd, "mallorca_torrents_dem.gpkg"), "torrents",
         delete_dsn = TRUE, quiet = TRUE)
cat("OK -> data/external/mallorca_torrents_dem.gpkg ·", nrow(v),
    "reaches · Strahler max", max(v$order), "\n")

invisible(file.remove(c(Sys.glob(file.path(wd, "_*.tif")),
                        Sys.glob(file.path(wd, "_torrents.*")))))
