
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

### Convert to string
html_string <- html_text(html)

### Extract just the json data
html_json <- str_extract(html_string,"var playersArray = (.*?)\\]")
html_json <- gsub("var playersArray = ","",html_json)

parsed_data <- fromJSON(json)

parsed_data <- fromJSON("https://keeptradecut.com/dynasty-rankings")

##############
js <- html %>% 
  html_element(xpath = "//script[contains(., 'playersArray')]") %>% 
  html_text()

parsed_data <- js %>%
  stringr::str_extract("(?<=var playersArray =)[^;]+(?=;)") %>%
  jsonlite::parse_json(simplifyVector = T)
  #fromJSON(js)

substr(js,1,500)

##########################################################
### Scraping Rankings from Dynasty Rankings
##########################################################

