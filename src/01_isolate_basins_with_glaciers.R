#The goal of this script is to:
#1. Load HydroBASINS data and glacier data
#2. Identify basins in N America that contain glaciers
#3. Create a dataset with lakes in N. America down gradient of glaciers


# 1. Load libraries -------------------------------------------------------

#Install packages if they are not in your package library
libs <- c(
  'tidyverse', 
  'sf', 
  'giscoR',
  'elevatr',
  'terra',
  'rayshader',
  'janitor',
  'mapview'
)

installed_libs <- libs %in% rownames(
  installed.packages()
)

if(any(installed_libs == FALSE)){
  install.packages(
    libs[!installed_libs]
  )
}

#Load all of the required libraries
invisible(
  lapply(
    libs, library, character.only = TRUE
  )
)

#Turn off spherical geometry in SF package

sf::sf_use_s2(FALSE)


# 2. Download HydroBASINS data --------------------------------------------

#**2a. North America----
#Hydrobasins data of North and Central America (customized with lakes)

#url_na <- 'https://data.hydrosheds.org/file/HydroBASINS/customized_with_lakes/hybas_lake_na_lev12_v1c.zip' 
url_na <- 'https://data.hydrosheds.org/file/HydroBASINS/standard/hybas_na_lev06_v1c.zip' 

download.file(
  url = url_na,
  destfile = basename(url_na),
  mode = 'wb'
)

list.files()

unzip(basename(url_na))

na_basins <- sf::st_read(
  'hybas_na_lev06_v1c.shp'
  #'hybas_lake_na_lev12_v1c.shp'
) #%>%  
  # filter(
  #   LAKE == 1
  # )


mapview(na_basins)

# plot(
#   sf::st_geometry(na_basins)
# )

#**2b. Northern Canada----

#Hydrobasins data of Arctic (northern Canada) (customized with lakes)

#url_ar <- 'https://data.hydrosheds.org/file/HydroBASINS/customized_with_lakes/hybas_lake_ar_lev12_v1c.zip' 
url_ar <- 'https://data.hydrosheds.org/file/HydroBASINS/standard/hybas_ar_lev06_v1c.zip' 

download.file(
  url = url_ar,
  destfile = basename(url_ar),
  mode = 'wb'
)

unzip(basename(url_ar))

list.files()

ar_basins <- sf::st_read(
  #'hybas_lake_ar_lev12_v1c.shp'
  'hybas_ar_lev06_v1c.shp'
) #%>%  
  # filter(
  #   LAKE == 1
  # )

# plot(
#   sf::st_geometry(ar_basins)
# )

mapview(ar_basins)

# 3. Combine NA and AR basin data -----------------------------------------

all_basins <- na_basins %>% 
  bind_rows(
    ar_basins
  )

mapview(all_basins)
# plot(
#   sf::st_geometry(all_basins)
# )


# 4. Import glacier data --------------------------------------------------

url_glaciers <- 'https://static-content.springer.com/esm/art%3A10.1038%2Fs41586-021-03436-z/MediaObjects/41586_2021_3436_MOESM5_ESM.xlsx'

download.file(
  url = url_glaciers,
  destfile = basename(url_glaciers),
  mode = 'wb'
)

list.files()

glaciers <- readxl::read_excel('41586_2021_3436_MOESM5_ESM.xlsx', skip = 1) #%>%
#   clean_names() %>% 
#   select(
#     subreg,
#     lon_reg,
#     lat_reg
#   ) %>% 
#   filter(
#     subreg != 'Global'
#   ) %>% 
#   mutate(
#     subreg = as.factor(subreg),
#     #The as.numeric conversion on its own introduced NAs
#     #likely due to some non-unicode characters.
#     #Found fix here: https://stackoverflow.com/questions/57656023/as-numeric-returns-na-for-no-apparent-reason-for-some-of-the-values-in-a-column
#     lon_reg = as.numeric(iconv(lon_reg, 'utf-8', 'ascii', sub='')),
#     lat_reg = as.numeric(iconv(lat_reg, 'utf-8', 'ascii', sub=''))
#   )

#Inspect map of glacier data points
 #mapview(glaciers, xcol = 'tile_lonmin', ycol = 'tile_latmin', crs = 4269, grid = F)


# 5. Filter glacier data to N. America ------------------------------------

na_glac <- glaciers %>% 
  filter(
    tile_latmin >= 35 & tile_latmin <=71 & tile_lonmin >= -170 & tile_lonmin <= -103
  )

#mapview(na_glac, xcol = 'tile_lonmin', ycol = 'tile_latmin', crs = 4269, grid = F)


# 6. Isolate watersheds with glaciers -------------------------------------

#Convert na_glac to sf object
na_glac_sf <- st_as_sf(na_glac, coords = c('tile_lonmin', 'tile_latmin'), crs = 4326)

#Test that coords look correct.
mapview(na_glac_sf) #Looks correct.

glac_ws <- st_intersection(na_glac_sf, all_basins) %>% 
  select(HYBAS_ID) %>% 
  st_drop_geometry()


glac_polys <- all_basins %>% 
  inner_join(glac_ws, by = 'HYBAS_ID')

mapview(glac_polys)
