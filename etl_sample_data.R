
###################################################################################
###################################################################################
### Scraping Sleeper Data from a small sample of leagues
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

##########################################################
### Getting sample of leagues
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
str(franchises)

### Loop to get leagues
league_list <- list()

for (i in c(1:nrow(franchises))){
  league_list[[i]] <- sleeper_userleagues(franchises$user_id[i],season = 2022)$league_id
}

### Make into vector and deduplicate
league_dat <- do.call(c,league_list)
league_dat <- league_dat[!duplicated(league_dat)]


##########################################################
### Getting league summary, team transaction, and schedule data 
##########################################################

######################
## League Summary
######################

### Define Function
league_summary <- function(leagues,year = 2022){
  
  dat_list <- list()
  
  for (i in c(1:NROW(leagues))){
    league <- sleeper_connect(season = year, league_id = leagues[i])
    dat_list[[i]] <- ff_league(league)
  }
  
  dat <- do.call(rbind,dat_list)
  return(dat)  
}

### Run Function
summary_dat <- league_summary(leagues = league_dat)

x <- league_summary(leagues = league_dat,year = 2010)


######################
## Transactions
######################

### Define Function
league_transactions <- function(leagues,year = 2022){
  
  dat_list <- list()
  
  for (i in c(1:NROW(leagues))){
    league <- sleeper_connect(season = year, league_id = leagues[i])
    
    dat <- ff_transactions(league)
    dat$league_id <- leagues[i]
    dat$season <- year
    
    dat_list[[i]] <- dat
  }
  
  dat <- rbindlist(dat_list, fill = TRUE)

  return(dat)  
}

### Run Function
transactions_dat <- league_transactions(leagues = league_dat)


######################
## Schedules
######################

### Define Function
league_schedule <- function(leagues,year = 2022){
  
  dat_list <- list()
  
  for (i in c(1:NROW(leagues))){
    league <- sleeper_connect(season = year, league_id = leagues[i])
    
    dat <- ff_schedule(league)
    dat$league_id <- leagues[i]
    dat$season <- year
    
    dat_list[[i]] <- dat
  }
  
  dat <- rbindlist(dat_list, fill = TRUE)
  
  return(dat)  
}

### Run Function
schedule_dat <- league_schedule(leagues = league_dat)

##########################################################
### Save league summary, team transaction, and schedule data 
##########################################################

### League summary
write.csv(summary_dat,"summary_dat.csv",row.names = F)

### Transactions
write.csv(transactions_dat,"transactions_dat.csv",row.names = F)

### Schedules
write.csv(schedule_dat,"schedule_dat.csv",row.names = F)


