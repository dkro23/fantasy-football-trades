
###################################################################################
###################################################################################
### Scraping KTC Rankings Data
###################################################################################
###################################################################################

### Load Libraries
library(tidyverse)
library(data.table)
library(dplyr)

library(stringr)
library(ggplot2)
library(reshape2)
library(lubridate)
library(stringr)

library(ffscrapr)
library(rvest)
library(httr)
library(jsonlite)

##########################################################
### Test with Patrick Mahomes
# Ref: https://stackoverflow.com/questions/76535564/where-is-data-coming-from-on-this-web-page
##########################################################

### Set html
html <- read_html("https://keeptradecut.com/dynasty-rankings/players/patrick-mahomes-272")

### Get JS
js <- html %>% 
  html_element(xpath = "//script[contains(., 'playerOneQB')]") %>% 
  html_text()

### Get 1QB Value
overallValue <- js %>% 
  stringr::str_extract("(?<=var playerOneQB =)[^;]+(?=;)") %>% 
  jsonlite::parse_json(simplifyVector = T) %>% 
  getElement("overallValue") %>%
  rename(date = d, value = v)

### Test Plot
overallValue %>%
  mutate(date = as_date(date)) %>%
  ggplot(aes(date, value)) +
  geom_line() +
  xlab("") + ylab("Value") + 
  ggtitle("Patrick Mahomes 1QB Dynasty Value, 2020-04-01 to 2023-07-13") +
  labs(caption = "Data from KeepTradeCut.")

### Get SuperFlex Value
overallValue_sf <- js %>% 
  stringr::str_extract("(?<=var playerSuperflex =)[^;]+(?=;)") %>% 
  jsonlite::parse_json(simplifyVector = T) %>% 
  getElement("overallValue") %>%
  rename(date = d, value = v)

### Test Plot
overallValue %>%
  mutate(date = as_date(date),
         type = "1QB") %>%
  rbind({
    overallValue_sf %>%
      mutate(date = as_date(date),
             type = "SF")
  }) %>%
  ggplot(aes(date, value,group = type)) +
  geom_line(aes(color = type)) +
  xlab("") + ylab("Value") + 
  ggtitle("Patrick Mahomes 1QB Dynasty Value, 2020-04-01 to 2023-07-13") +
  labs(caption = "Data from KeepTradeCut.",
       color = "Type")
  
  
##########################################################
### Getting the set of players to scrape
##########################################################

### Set html
html <- read_html("https://keeptradecut.com/dynasty-rankings")

### Get to JSON
js <- html %>% 
  html_element(xpath = "//script[contains(., 'playersArray')]") %>% 
  html_text()

### Parse Data
player_links <- js %>%
  stringr::str_extract("(?<=var playersArray =)[^;]+(?=;)") %>%
  jsonlite::parse_json(simplifyVector = T) %>%
  select(playerName,playerID,slug,positionID)


##########################################################
### Scraping Rankings from Dynasty Rankings
##########################################################

### Lists
dat_list_1qb <- list()
dat_list_sf <- list()

### Scrape Data in Loop
for (i in c(1:nrow(player_links))){
  
  ### Set html
  html <- read_html(paste("https://keeptradecut.com/dynasty-rankings/players/",player_links$slug[i],sep=""))
  
  ### Get JS
  js <- html %>% 
    html_element(xpath = "//script[contains(., 'playerOneQB')]") %>% 
    html_text()
  
  ### Get 1QB Value
  overallValue_1qb <- js %>% 
    stringr::str_extract("(?<=var playerOneQB =)[^;]+(?=;)") %>% 
    jsonlite::parse_json(simplifyVector = T) %>% 
    getElement("overallValue") %>%
    rename(date = d, value = v)
  

  
  ### Get SuperFlex Value
  overallValue_sf <- js %>% 
    stringr::str_extract("(?<=var playerSuperflex =)[^;]+(?=;)") %>% 
    jsonlite::parse_json(simplifyVector = T) %>% 
    getElement("overallValue") %>%
    rename(date = d, value = v)
  
  ### Add in Player ID
  overallValue_1qb$playerID <- player_links$playerID[i]
  overallValue_sf$playerID <- player_links$playerID[i]
  
  ### Store Data
  dat_list_1qb[[i]] <- overallValue_1qb
  dat_list_sf[[i]] <- overallValue_sf
  
}

### Combine Together
dat_1qb <- do.call(rbind,dat_list_1qb)
dat_sf <- do.call(rbind,dat_list_sf)


##########################################################
### Save Data - 07/13/2023
##########################################################

### KTC 1QB Rankings
write.csv(dat_1qb,"ktc_1qb_daily_rankings.csv",row.names = F)

### KTC SF Rankings
write.csv(dat_sf,"ktc_sf_daily_rankings.csv",row.names = F)

