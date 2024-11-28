#The goal of this script is to:
#1. Load filtered HydroBASINS data with glaciers from script 01
#2. Load HydroLAKES data
#3. Identify lakes within watersheds with glaciers
#4. Create a dataset with those filtered lakes

#For now this is just North America, but can be expanded to the globe


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
  'mapview',
  'here',
  'rnaturalearth',
  'rnaturalearthdata'
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


# 2. Load glacier basin data ----------------------------------------------

glac_poly <- sf::st_read(
  here(
    'data/glacier_basins.shp'
  )
)

#mapview(glac_poly)

# 3. Read in HydroLAKES data ----------------------------------------------

url_hl <- 'https://data.hydrosheds.org/file/hydrolakes/HydroLAKES_polys_v10_shp.zip'

download.file(
  url = url_hl,
  destfile = basename(url_hl),
  mode = 'wb'
)

unzip(basename(url_hl))

list.files()

filename <- list.files(
  path = "HydroLAKES_polys_v10_shp",
  pattern = ".shp",
  full.names = T
)

#Filter a box around the area of interest

bbox_wkt <- "POLYGON((
  -164 33,
  -164 149,
  -100 149,
  -100 33,
  -164 33
))"

na_lakes <- sf::st_read(
  filename,
  wkt_filter = bbox_wkt
)

#mapview(na_lakes)


# 4. Find lakes within watersheds -----------------------------------------

glac_lakes <- st_intersection(glac_poly, na_lakes) %>% 
  clean_names()

mapview(
  list(
    glac_poly, glac_lakes
  ),
  layer.name = c(
    'Glacier Polygons', 
    'Glacier Lakes'
  )
)


# 5. Make a readable plot -------------------------------------------------

#Creat a world map
world <- ne_countries(
  scale = 'medium',
  returnclass = 'sf'
)

#**5a. Map of watershed polygons with glaciers----

ggplot()+
  geom_sf(
    data = world, 
    color = 'black', 
    alpha = 0.5
  )+
  xlab('Longitude')+
  ylab('Latitude')+
  theme_classic()+
  geom_sf(
    data = glac_poly,
    fill = 'lightblue3'
  )+
  coord_sf(
    xlim = c(-164, -102),
    ylim = c(33, 71)
  )

# ggsave(
#   here(
#     'output/maps/basin_map.png'
#   ),
#   dpi = 300,
#   width = 10,
#   height = 10,
#   units = 'in'
# )

#**5a. Map of lake polygons with watersheds----

ggplot()+
  geom_sf(
    data = world, 
    color = 'black', 
    alpha = 0.5
  )+
  xlab('Longitude')+
  ylab('Latitude')+
  theme_classic()+
  geom_sf(
    data = glac_poly,
    fill = 'lightblue'
  )+
  # geom_sf(
  #   data = glac_lakes,
  #   fill = 'red'
  # )+
  geom_point(
    data = glac_lakes,
    aes(
      x = pour_long,
      y = pour_lat
    ),
    shape = 21,
    fill = 'green4',
    alpha = 0.2
  )+
  coord_sf(
    xlim = c(-164, -102),
    ylim = c(33, 71)
  )

ggsave(
  here(
    'output/maps/lake_point_w_basins_map.png'
  ),
  dpi = 300,
  width = 10,
  height = 10,
  units = 'in'
)


test <- glac_lakes %>% 
  st_drop_geometry() %>% 
  summarise(
    mean = mean(lake_area, na.rm = T),
    median = median(lake_area, na.rm = T),
    max = max(lake_area, na.rm = T),
    min = min(lake_area, na.rm = T)
  )
