#' Modify sf data to plot over rayshader
#'
#' @param r original raster used in rayshader
#' @param sf sf object to add on plot (with or without z column)
#' @param z_pos z-position of the sf on the 3d map if not in dataset
#' @param zscale if z-column existed in the dataset
#' @param as_sf Logical. Return sf object or not
#' @param groups Logical. Whether to group coordinates in blocks according to original structure. 
#' @param crop Whether to crop sf object to extent of raster
#' 
#' @importFrom sf st_crop st_bbox st_coordinates st_as_sf st_cast st_is st_drop_geometry
#' @importFrom dplyr mutate as_tibble group_by ungroup select summarise left_join n
#' @importFrom tidyr nest
#' 
#' @export
sf_proj_as_ray <- function(r, sf, z_pos = 1, zscale = 10, as_sf = TRUE, groups = TRUE, crop = TRUE) {
  
  # Crop to extent of raster
  if (isTRUE(crop)) {
    sf <- st_crop(sf, st_bbox(r))
  }
  
  if (!is.null(sf$z)) {
    sf <- sf %>% 
      mutate(
        L2 = 1:n(),
        Z_ray = z / zscale
      )
  } else {
    sf <- sf %>% 
      mutate(
        L2 = 1:n(),
        Z_ray = z_pos / zscale
      )
  }
  
  coords <- sf %>% 
    st_coordinates() %>% 
    as.data.frame() %>% 
    as_tibble() %>% 
    mutate(
      X_ray = (X - xmin(r)) / xres(r),
      # Y_ray = -1*(Y - ymin(r)) / yres(r)
      Y_ray = 1*(Y - ymin(r)) / yres(r)
    )
  
  if (!"L1" %in% names(coords)) {
    coords <- coords %>% 
      mutate(L1 = 1,
             L2 = 1:n()
      )
  } else if (!"L2" %in% names(coords)) {
    coords <- coords %>% 
      group_by(L1) %>% 
      mutate(L2 = L1,
             L1b = 1:n()) %>% 
      ungroup() %>% 
      mutate(L1 = L1b) %>% 
      select(-L1b)
  }
  
  if (isTRUE(as_sf)) {
    coords_sf <- coords %>% 
      select(-X, -Y) %>% 
      st_as_sf(coords = c("X_ray", "Y_ray")) %>% 
      group_by(L1, L2) %>% 
      summarise(do_union = FALSE) %>% 
      left_join(as.data.frame(sf) %>% select(-geometry))
    
    if (all(st_is(sf, c("POLYGON", "MULTIPOLYGON")))) {
      coords_sf <- coords_sf %>% 
        st_cast("POLYGON")
    } else  if (all(st_is(sf, c("LINESTRING", "MULTILINESTRING")))) {
      coords_sf <- coords_sf %>% 
        st_cast("LINESTRING")
    }else if (all(st_is(sf, c("POINT", "MULTIPOINT")))) {
      coords_sf <- coords_sf %>% 
        st_cast("POINT")
    }
  } 
  if (isTRUE(groups)) {
    coords_grp <- coords %>% 
      mutate(Y_ray = -1 * Y_ray) %>% 
      left_join(st_drop_geometry(sf)) %>% 
      group_by(L1, L2) %>% 
      nest(coords = c(X_ray, Z_ray, Y_ray))
  }
  
  if (isTRUE(as_sf) & isTRUE(groups)) {
    res <- list(sf = coords_sf, coords = coords_grp)
  } else if (isTRUE(as_sf) & !isTRUE(groups)) {
    res <- list(sf = coords_sf, coords = coords)
  } else if (isTRUE(as_sf) & !isTRUE(groups)) {
    res <- list(coords = coords_grp)
  } else {
    res <- list(coords = coords)
  }
  return(res)
}
