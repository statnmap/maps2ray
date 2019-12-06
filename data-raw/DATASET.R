## code to prepare `DATASET` dataset goes here

# usethis::use_data("DATASET")
library(raster)
library(sf)
library(dplyr)

f <- "data-raw/Alti_mosaic_L93.tif"
altitude <- raster(f)

# Create area
if (FALSE) {
  em <- mapview::mapview(altitude) %>% 
    mapedit::editMap()
  st_write(em$finished, "data-raw/area_wgs84.shp")
}

area <- st_read("data-raw/area_wgs84.shp")
zone <- area %>% 
  st_transform(crs = st_crs(altitude))
r <- raster::crop(altitude, zone)
plot(r)

writeRaster(r, filename = "inst/extdata/altitude_l93.tif")
