
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
library(rdrobust)
library(lfe)

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

### All Leagues
p1 <- dat_reg %>%
  filter(abs(points_margin) < 15) %>%
  ggplot(aes(points_margin,trade_indicator,color = result)) +
  geom_point() +
  geom_smooth(method="lm") +
  xlab("Margin of Victory/Defeat") + ylab("Completed Trade Following Week?")

### All Leagues with bins
p2 <- dat_reg %>%
  filter(abs(points_margin) < 15) %>%
  ggplot(aes(points_margin,trade_indicator,color = result)) +
  geom_point(data = dat_reg %>%
               filter(abs(points_margin) < 15) %>%
               mutate(points_margin = round(points_margin,0)) %>%
               group_by(points_margin) %>%
               summarise(trade_indicator = mean(trade_indicator),
                         count = n()),
             aes(x = points_margin, y=trade_indicator, size=count), alpha=.2, inherit.aes=F
             ) +
  geom_smooth(method="lm") +
  geom_vline(xintercept=0, linetype="dashed", alpha=.7) +
  theme_classic() +
  xlab("Margin of Victory/Defeat") + ylab("") +
  ggtitle("Completed Trade Following Week?")

### Dynasty only
dat_reg %>%
  filter(abs(points_margin) < 15,
         league_type == "dynasty") %>%
  ggplot(aes(points_margin,trade_indicator,color = result)) +
  geom_point() +
  geom_smooth(method="lm") +
  xlab("Margin of Victory/Defeat") + ylab("Completed Trade Following Week?")

#############
## Regression
#############

### Finding Optimal Bandwidth
bw <- rdbwselect(y = dat_reg$trade_indicator,x = dat_reg$points_margin, c = 0, p = 1, bwselect = "mserd")

### Preparing for estimation
dat_reg <- dat_reg %>%
  mutate(
    bandwidth = bw$bws[1],
    kw = 1-(abs(0 - points_margin))/bandwidth,
    kw = ifelse(abs(points_margin) > bandwidth, 0, kw)
  )

### Estimation
m1 <- felm(
  trade_indicator ~ points_margin + I(points_margin > 0) + I(points_margin > 0)*points_margin +
    franchise_score | league_id + week | 0 | franchise_id,
  weights = subset(dat_reg,dat_reg$kw > 0)$kw,
  data = subset(dat_reg,dat_reg$kw > 0)
)
summary(m1)

m2 <- felm(
  trade_indicator ~ points_margin + I(points_margin > 0) + I(points_margin > 0)*points_margin +
    franchise_score | league_id + week | 0 | franchise_id,
  weights = dat_reg$kw,
  data = dat_reg
)
summary(m2)




