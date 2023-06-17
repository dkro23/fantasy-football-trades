
###################################################################################
###################################################################################
### Regression Discontinuity Analysis using sample data
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
### Load data
##########################################################

### League summary
summary_dat <- fread("summary_dat.csv")

### Transactions
transactions_dat <- fread("transactions_dat.csv")

### Schedules
schedule_dat <- fread("schedule_dat.csv")


##########################################################
### Prep data for analysis
##########################################################

############
## Adding Dates to Schedule and Margin of Victory/Defeat
############

schedule_dat <- data.frame(
  week = c(1:17),
  date = seq(as_date("2022-09-11"), by = "7 days", length.out = 17)
  ) %>%
  right_join(schedule_dat)  %>%
  mutate(points_margin = franchise_score - opponent_score)

#############
## Merge schedule outcome to transactions data
#############

dat <- transactions_dat %>%
  filter(as_date(timestamp) > as_date("2022-09-10"), # Take out preseason trades
         type != "waiver_failed") %>% # Take out failed waiver claims
  mutate(
    date = as_date(timestamp),
    week = lubridate::week(date) - 36,
    week = week %% 17, # Creating week variable for merge
    week_day = wday(date) # Day of week
  ) %>%
  filter(
    week %in% c(1:8), # Reduce to pre-playoffs and fairly early in the season
    week_day %in% c(3:7)) %>% # Taking out Sunday and Monday (b/c games happening those days)
  
  left_join(schedule_dat)


#############
## Clean Data for Regressions
#############

dat_reg <- dat %>%
  filter(
    type == "trade" # Reduce to just trades
  ) %>%
  group_by(franchise_id,league_id,week) %>%
  summarise(
    num_trades = n()
  ) %>%
  right_join(schedule_dat) %>%
  mutate(
    num_trades = ifelse(!is.na(num_trades),num_trades,0),
    trade_indicator = ifelse(num_trades == 0,0,1)
  ) %>%
  filter(week %in% c(1:8)) %>%
  left_join(summary_dat)

#############
## Visualization
#############

dat_reg %>%
  filter(abs(points_margin) < 15) %>%
  ggplot(aes(points_margin,trade_indicator,color = result)) +
  geom_point() +
  geom_smooth(method="lm") +
  xlab("Margin of Victory/Defeat") + ylab("Completed Trade Following Week?")

#############
## Regression
#############
m1 <- lm(
  trade_indicator ~ points_margin + 
    I(points_margin < 0) + I(points_margin < 0)*points_margin +
    franchise_score,
  data = dat_reg
)
summary(m1)




