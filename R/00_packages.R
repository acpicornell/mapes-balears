# Comprobación de paquetes. Con el flake (nix develop .#r) ya vienen instalados.
# Fuera de Nix, descomenta para instalar:
# install.packages(c("sf","terra","tidyverse","rayshader","elevatr",
#                     "giscoR","ggspatial","classInt","scales","MetBrewer","magick"))
pkgs <- c("sf","terra","tidyverse","rayshader","elevatr",
          "giscoR","ggspatial","classInt","scales","MetBrewer")
inv <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(inv)) stop("Faltan paquetes: ", paste(inv, collapse = ", "))
cat("OK — todos los paquetes disponibles\n")
