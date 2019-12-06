
<!-- README.md is generated from README.Rmd. Please edit that file -->

# maps2ray

<!-- badges: start -->

<!-- badges: end -->

The goal of maps2ray is to transform spatial objects from {sf} and
{raster} to be used in {rayshader} 3D outputs.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("statnmap/maps2ray")
```

## Example

This procedure is explained in a blog post at:
<https://statnmap.com/2019-10-06-follow-moving-particle-trajectory-on-raster-with-rayshader/>

``` r
library(maps2ray)
library(rayshader)
library(sf)
library(raster)
library(rasterVis)
library(ggplot2)
library(dplyr)
library(rgl)
```

  - Read internal raster file

<!-- end list -->

``` r
f <- system.file("extdata/altitude_l93.tif", package = "maps2ray")
altitude <- raster(f)
```

### Create rayshaded raster basis

Create the {rayshader} terrain object to be used in both 2D and 3D
outputs

``` r
# Transform raster as matrix
datamat <- t(as.matrix(altitude))
# Rayshade raster
zscale <- 5
ambmat <- ambient_shade(datamat, zscale = zscale)
raymat <- ray_shade(datamat, zscale = zscale, lambert = TRUE)

# Create ray_image
ray_image <- datamat %>%
  sphere_shade(texture = "imhof4") %>%
  add_shadow(raymat, max_darken = 0.5) %>%
  add_shadow(ambmat, max_darken = 0.5) 

# Plot 2D
plot_map(ray_image)
```

<img src="man/figures/README-unnamed-chunk-4-1.png" width="100%" />

### Example with points trajectory

  - Create a trajectory as {sf} object

<!-- end list -->

``` r
line_mat <- matrix(c(280000, 370000, 6700000, 6700000), ncol = 2)
line_traject <- st_linestring(x = line_mat)
point_traject <- st_sample(line_traject, size = 50, type = "regular") %>% 
  st_set_crs(2154) %>% 
  st_sf()

# Plot
gplot(altitude) +
  geom_tile(aes(fill = value)) +
  geom_sf(data = point_traject, colour = "white", inherit.aes = FALSE) +
  scale_fill_viridis_c()
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

  - Transform {sf} trajectory to {rayshader} coordinates reference
    system, relative to the `altitude` raster

<!-- end list -->

``` r
points_ray <- sf_proj_as_ray(r = altitude, sf = point_traject,
                             z_pos = maxValue(altitude) + 10,
                             zscale = zscale)
```

  - Plot rayshader image in 2D and add points with new coordinates
    reference system of {rayshader}: `sf` list in the output of
    `sf_proj_as_ray()`.

<!-- end list -->

``` r
# plot rayshader in 2D
plot_map(ray_image)
plot(points_ray$sf, col = "blue", pch = 20, add = TRUE, reset = FALSE)
```

<img src="man/figures/README-ray2dtotal-1.png" width="100%" />

  - Plot {rayshader} image in 3D and overlay points with the new
    coordinates reference system of {rayshader}: `coords` list in the
    output of `sf_proj_as_ray()`.

<!-- end list -->

``` r
# Create 3D scene
ray_image %>% 
  plot_3d(
    datamat,
    zscale = zscale, windowsize = c(500, 500),
    soliddepth = -max(datamat, na.rm = TRUE)/zscale,
    water = TRUE, wateralpha = 0,
    theta = 15, phi = 40,
    zoom = 0.6, 
    fov = 60)

# Add points over rayshader scene
spheres3d(
  bind_rows(points_ray$coords$coords),
  col = "blue", add = TRUE, radius = 10,
  alpha = 1)

# rgl::snapshot3d(file.path("img", "ray3dtotal.png"))
# rgl::rgl.close()
```

<img src="img/ray3dtotal.png" width="100%" />

### Example with line

``` r
line_mat <- matrix(c(280000, 370000, 6680000, 6720000), ncol = 2)
line_mat2 <- matrix(c(280000, 370000, 6680000, 6680000), ncol = 2)
line_traject <- st_sf(
  geometry = st_sfc(list(
    st_multilinestring(list(st_linestring(x = line_mat))),
    st_multilinestring(list(st_linestring(x = line_mat2)))
    )), crs = 2154)

# With no tranformation
plot(altitude)
plot(line_traject, col = "blue", pch = 20, add = TRUE)

# Transform for rayshader
zscale <- 5
lines_ray <- sf_proj_as_ray(r = altitude, sf = line_traject,
                             z_pos = maxValue(altitude) + 10,
                             zscale = zscale)

# Plot
# plot rayshader in 2D
plot_map(ray_image)
plot(lines_ray$sf, col = "blue", pch = 20, add = TRUE, reset = FALSE)
```

In 3D

``` r
ray_image %>% 
  plot_3d(
    datamat,
    zscale = zscale, windowsize = c(500, 500),
    soliddepth = -max(datamat, na.rm = TRUE)/zscale,
    water = TRUE, wateralpha = 0,
    theta = 15, phi = 40,
    zoom = 0.6, 
    fov = 60)

# Add points over rayshader scene
lines3d(
  bind_rows(lines_ray$coords$coords),
  col = "blue", add = TRUE, radius = 10,
  alpha = 1)

# rgl::snapshot3d(file.path("img", "ray3d_lines.png"))
# rgl::rgl.close()
```

<img src="img/ray3d_lines.png" width="100%" />

### Example with polygons

``` r
pol_mat <- matrix(
  c(280000, 370000, 370000, 280000,
    6680000, 6720000, 6680000, 6680000), ncol = 2)
pol_mat2 <- matrix(
  c(280000, 370000, 280000, 280000,
    6680000, 6720000, 6720000, 6680000), ncol = 2)

pol_traject <- st_sf(
  geometry = st_sfc(list(
    st_multipolygon(list(st_polygon(x = list(pol_mat)))),
    st_multipolygon(list(st_polygon(x = list(pol_mat2))))
    )), crs = 2154)

# With no tranformation
plot(altitude)
plot(pol_traject, col = c("red", "blue"), pch = 20, add = TRUE)
```

<img src="man/figures/README-unnamed-chunk-12-1.png" width="100%" />

``` r

# Transform for rayshader
zscale <- 5
pols_ray <- sf_proj_as_ray(r = altitude, sf = pol_traject,
                             z_pos = maxValue(altitude) + 10,
                             zscale = zscale)
#> Joining, by = "L2"Joining, by = "L2"

# Plot
# plot rayshader in 2D
plot_map(ray_image)
plot(pols_ray$sf, col = c("red", "blue"), pch = 20, add = TRUE, reset = FALSE)
#> Warning in plot.sf(pols_ray$sf, col = c("red", "blue"), pch = 20, add = TRUE, :
#> ignoring all but the first attribute
```

<img src="man/figures/README-unnamed-chunk-12-2.png" width="100%" />

In 3D

``` r
ray_image %>% 
  plot_3d(
    datamat,
    zscale = zscale, windowsize = c(500, 500),
    soliddepth = -max(datamat, na.rm = TRUE)/zscale,
    water = TRUE, wateralpha = 0,
    theta = 15, phi = 40,
    zoom = 0.6, 
    fov = 60)

# Add points over rayshader scene
lines3d(
  bind_rows(pols_ray$coords$coords),
  col = "blue", add = TRUE, radius = 10,
  alpha = 1)

# rgl::snapshot3d(file.path("img", "ray3d_polygons.png"))
# rgl::rgl.close()
```

<img src="img/ray3d_polygons.png" width="100%" />
