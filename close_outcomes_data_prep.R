
###################################################################################
### Scraping Sleeper Data
# Ref: https://ffscrapr.ffverse.com/articles/sleeper_basics.html
###################################################################################

### Set Wd
setwd("C:/Users/David/Documents/Data Projects/FF Trades")

### Load Libraries
library(tidyverse)
library(data.table)
library(dplyr)

library(stringr)
library(ggplot2)
library(reshape2)
library(lubridate)

library(rvest)
library(stringr)
library(httr)
library(jsonlite)

library(ffscrapr)

##########################################################
### Get Sample of Leagues using home leagues
##########################################################

### Get my league information
my_league <- sleeper_userleagues("dkro23",season = 2022)
str(my_league)

### Get League IDs
league <- my_league %>%
  filter(league_name == "Northeast Ohio Young Studs  ") %>%
  pull(league_id)

### Connect to league
neoys <- sleeper_connect(season = 2022, league_id = league)
str(neoys)

### League Summary
league_summary <- ff_league(neoys)
str(league_summary)

### Get Franchises in home league
franchises <- ff_franchises(neoys)

### Loop to get leagues
league_list <- list()

for (i in c(1:nrow(franchises))){
  league_list[[i]] <- sleeper_userleagues(franchises$user_id[i],season = 2022)$league_id
}

### Make into vector and deduplicate
league_dat <- do.call(c,league_list)
league_dat <- league_dat[!duplicated(league_dat)]

### Loop to get more leagues
league_list2 <- list()

for (i in c(1:NROW(league_dat))){
  # Connect to league
  league <- sleeper_connect(season = 2022, league_id = league_dat[i])
  
  # List of Players
  franchises <- ff_franchises(league)
  
  # Get List of Leagues for Each Player
  x <- list()
  
  for (j in c(1:nrow(franchises))){
    if(!is.na(franchises$user_id[j])) {
      x[[j]] <- sleeper_userleagues(franchises$user_id[j],season = 2022)$league_id
    }else{
      x[[j]] <- NA
    }
    
    
  }
  
  x <- do.call(c,x)
  x <- x[!duplicated(x)]
  
  league_list2[[i]] <- x
}

league_dat2 <- do.call(c,league_list2)
league_dat2 <- league_dat2[!duplicated(league_dat2)]



###
transactions %>%
  filter(type == "trade") %>%
  group_by(franchise_name) %>%
  summarise(count = n()) %>%
  arrange(desc(count))

range(transactions$timestamp)

transactions %>%
  filter(type == "trade") %>%
  group_by(franchise_name,timestamp) %>%
  summarise(count = n()) %>%
  group_by(franchise_name) %>%
  summarise(count = n()) %>%
  arrange(desc(count))
