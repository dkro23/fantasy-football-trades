
###################################################################################
### Scraping Sleeper Data
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
### Test - Getting Data
# Ref: https://ffscrapr.ffverse.com/articles/sleeper_basics.html
##########################################################

### Get my league information
my_league <- sleeper_userleagues("dkro23",season = 2022)
str(my_league)

### Connect to my league
league <- my_league %>%
  filter(league_name == "Northeast Ohio Young Studs  ") %>%
  pull(league_id)

neoys <- sleeper_connect(season = 2022, league_id = league)
str(neoys)

### League Summary
league_summary <- ff_league(neoys)
str(league_summary)

### League Transactions
transactions <- ff_transactions(neoys)

### Get Schedule
schedule <- ff_schedule(neoys)

### Get Standings
standings <- ff_standings(neoys)

### Get Rosters
rosters <- ff_rosters(neoys)

### Trying other stuff
x <- ff_franchises(neoys)
x <- ff_scoring(neoys)
x <- ff_scoringhistory(neoys)
x <- ff_playerscores(neoys)

### Trying using FF Template
x <- ff_template(scoring_type = "ppr",roster_type = "1qb")

##########################################################
### Test - Transactions following wins and losses - Creating Dataset
##########################################################

### Adding Dates to Schedule
schedule_clean <- data.frame(
  week = c(1:17),
  date = seq(as_date("2022-09-11"), by = "7 days", length.out = 17)
) %>%
  mutate(date_end = date + 3) %>%
  right_join(schedule)  %>%
  mutate(points_margin = franchise_score - opponent_score)


### Analysis on Margin of defeat
summary(schedule_clean[schedule_clean$points_margin > 0,]$points_margin)

### Merge schedule outcome to transactions data
transactions_clean <- transactions %>%
  filter(as_date(timestamp) > as_date("2022-09-10"),
         type != "waiver_failed") %>%
  mutate(
    date = as_date(timestamp),
    week = lubridate::week(date) - 36,
    week = week %% 17,
    week_day = wday(date)
  ) %>%
  filter(
    week %in% c(1:14),
    week_day %in% c(3:7))

dat <- transactions_clean %>%
  left_join({
    schedule_clean %>%
      mutate(franchise_id = as.character(franchise_id)) %>%
      select(-date,-date_end,-opponent_id,-opponent_score)
  })

##########################################################
### Test - Transactions following wins and losses - Analysis
##########################################################

### Number of transactions for winners v. losers
dat %>%
  group_by(result) %>%
  summarise(
    total_transactions = n(),
    trades = sum(type == "trade"),
    free_agent = sum(type == "free_agent"),
    waiver = sum(type == "waiver_complete")
  )

### Number of transactions for close winners v. losers
dat %>%
  filter(abs(points_margin) < 25) %>%
  group_by(result) %>%
  summarise(
    total_transactions = n(),
    trades = sum(type == "trade"),
    free_agent = sum(type == "free_agent"),
    waiver = sum(type == "waiver_complete")
  )

### Number of transactions for close winners v. losers by day of the week
dat %>%
  filter(abs(points_margin) < 15) %>%
  group_by(result,week_day) %>%
  summarise(
    total_transactions = n(),
    trades = sum(type == "trade"),
    free_agent = sum(type == "free_agent"),
    waiver = sum(type == "waiver_complete")
  ) %>%
  ggplot(aes(week_day,trades,group = result)) +
  geom_bar(aes(fill = result),stat = "identity",position = position_dodge2(.9)) +
  geom_text(aes(label = trades),vjust = 1.3,color = "white",position = position_dodge2(.9)) +
  ylab("# of Trades") + xlab("Day of the Week") + 
  ggtitle("Number of Trades Completed by Close Winners and Losers") +
  labs(fill = "Result",
       caption = "Close outcomes are determined by a 25 point margin threshold.")
  

###############
### Regression Analysis
###############

### Create dataset
dat_reg <- dat %>%
  filter(
    type == "trade",
    week %in% c(1:12)
    ) %>%
  mutate(franchise_id = as.numeric(franchise_id)) %>%
  group_by(franchise_id,week) %>%
  summarise(
    num_trades = n()
  ) %>%
  right_join(schedule_clean) %>%
  mutate(
    num_trades = ifelse(!is.na(num_trades),num_trades,0),
    trade_indicator = ifelse(num_trades == 0,0,1)
    )

### Regression
m1 <- lm(
  trade_indicator ~ points_margin + 
    I(points_margin < 0) + I(points_margin < 0)*points_margin +
    franchise_score,
  data = dat_reg
)
summary(m1)

### Visualization
dat_reg %>%
  ggplot(aes(points_margin,trade_indicator,color = result)) +
  geom_point() +
  geom_smooth(method="lm") +
  xlab("Margin of Victory/Defeat") + ylab("Completed Trade Following Week?")

### Placebo
dat_reg %>%
  mutate(
    points_margin2 = points_margin - 10,
    result2 = ifelse(points_margin2 > 0,"W","L")
  ) %>%
  ggplot(aes(points_margin2,trade_indicator,color = result2)) +
  geom_point() +
  geom_smooth(method="lm") +
  xlab("Margin of Victory/Defeat") + ylab("Completed Trade Following Week?")

house_rd %>% 
  ungroup %>% 
  mutate(`Party Won` = ifelse(perc_R < .5, "Democrat", "Republican")) %>% 
  filter(!is.na(`Party Won`)) %>% 
  filter(perc_R >= .4 & perc_R <= .6) %>% 
  ggplot(aes(x = perc_R, y = ln_grants_nf, group=`Party Won`, color=`Party Won`)) +
  geom_point() +
  geom_smooth(method="lm") +
  ylim(14, 22)