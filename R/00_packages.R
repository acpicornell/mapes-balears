# Package check. With the flake (nix develop .#r) they come pre-installed.
# Outside Nix, uncomment to install:
# install.packages(c("sf","terra","tidyverse","rayshader","elevatr",
#                     "giscoR","ggspatial","classInt","scales","MetBrewer","magick"))
pkgs <- c("sf","terra","tidyverse","rayshader","elevatr",
          "giscoR","ggspatial","classInt","scales","MetBrewer")
inv <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(inv)) stop("Missing packages: ", paste(inv, collapse = ", "))
cat("OK — all packages available\n")
