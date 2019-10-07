#' Create a cropped scene
#'
#' @param datamat Original raster transformed as matrix with t(as.matrix(raster))
#' @param ray_image Rayshaded image created with sphere_shade, add_shadow, ...
#' @param position dataframe of point coordinates in the {rayshader} system
#' as created using sf_proj_as_ray()
#' @param position_next dataframe of another point coordinates in the {rayshader} 
#'system as created using sf_proj_as_ray()
#' @param window size of the square window in pixels around the position
#' @param zscale Ratio between Z and x/y. Adjust the zscale down to exaggerate
#' elevation features. Better to use the same for the entire workflow.
#' @param zoom Zoom factor. Reduce to zoom in.
#' @param windowsize Size of the rgl window
#' 
#' @importFrom dplyr tibble mutate
#' @importFrom rayshader plot_3d
#' @importFrom rgl spheres3d
#' 
#' 
#' @export
render_point_cropped_scene <- function(ray_image, datamat, position,
                                 position_next,
                                 window = 100,
                                 zscale = 5, zoom = 0.4,
                                 windowsize = c(500, 500)) {
  # Create a window around point
  bounds <- tibble(
    Xmin = max(round(position)[1] - window, 0), # X
    Xmax = min(round(position)[1] + window, dim(datamat)[1]),
    Ymin_pos = max(round(position)[3] - window, -dim(datamat)[2]), # Y
    Ymax_pos = min(round(position)[3] + window, 0),
    Ymin_row = dim(datamat)[2] + Ymin_pos + 1,
    Ymax_row = dim(datamat)[2] + Ymax_pos + 1
  )
  
  # Height of the block (min - 1/5 of total height) to correct z
  # soliddepth <- min(datamat, na.rm = TRUE))/zscale)
  one_5 <- (max(datamat, na.rm = TRUE) - min(datamat, na.rm = TRUE))/5
  soliddepth <- (min(datamat, na.rm = TRUE) - one_5)/zscale
  
  # Calculate new position of the point on the cropped raster
  position_bounds <- position %>% 
    mutate(
      X_ray = X_ray - bounds$Xmin + 1,
      Y_2d = Y_ray - bounds$Ymin_pos + 1,
      Y_ray = -1 * (Y_ray - bounds$Ymin_pos + 1),
      Z_ray = Z_ray #/zscale
    )
  
  # Plot cropped 3D output
  ray_image[bounds$Ymin_row:bounds$Ymax_row,bounds$Xmin:bounds$Xmax,] %>% 
    plot_3d(
      datamat[bounds$Xmin:bounds$Xmax, bounds$Ymin_row:bounds$Ymax_row],
      zscale = zscale, windowsize = windowsize,
      # soliddepth = -min(datamat, na.rm = TRUE)/zscale,
      soliddepth = soliddepth,
      water = TRUE, wateralpha = 0,
      theta = -90, phi = 30, 
      zoom = zoom, 
      fov = 80)
  
  # Add point at position
  spheres3d(position_bounds[,c("X_ray", "Z_ray", "Y_ray")],
            color = "red", add = TRUE, lwd = 5, radius = 5,
            alpha = 1)
  
  if (!missing(position_next)) {
    position_next_bounds <- position_next %>% 
      mutate(
        X_ray = X_ray - bounds$Xmin + 1,
        Y_2d = Y_ray - bounds$Ymin_pos + 1,
        Y_ray = -1 * (Y_ray - bounds$Ymin_pos + 1),
        Z_ray = Z_ray
      )
    
    # Add point at position
    spheres3d(position_next_bounds[,c("X_ray", "Z_ray", "Y_ray")],
              color = "blue", add = TRUE, lwd = 5, radius = 3,
              alpha = 1)
  }
}

