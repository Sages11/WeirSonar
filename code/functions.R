# notes ----

# sarah.power@alaska.gov
# 2019.04.01
# WeirSonarfunctions

# load ----
library(tidyverse)
library(calibrate)
library(ggplot2)
library(broom)#for cleaning up data, used in prediction
library(caret)#used for cross validation 
library(cowplot)
library(purrr)
#library(naniar)
#library(stringr)
library(dplyr)
library(PairedData)

# functions ----

#returns a p value from a t distribution testing if the slope of the line is equvalend to 1. (In which case x and y are interchageable.)
pvalue_of_t_test_slope_eq_1 <- function(linear_model = lm){
  pt(-abs((coef(summary(linear_model))[2,1]-1)/coef(summary(linear_model))[2,2]), df = summary(linear_model)$df[2])*2
}
#http://r-statistics.co/Linear-Regression.html

#returns graph of linear model, complete with confidence and predictive intervals, line x = y 
graph_10vs60 <- function(data, linear_model, this_year, this_method, this_species) { #, newpoint){
  #Use to make 95% CI and PI 
  minsixty_minute <- min(data$sixty_minute, na.rm = TRUE)
  maxsixty_minute <- max(data$sixty_minute, na.rm = TRUE)
  predx <- data.frame(sixty_minute = seq(from = minsixty_minute, to = maxsixty_minute, by = (maxsixty_minute-minsixty_minute)/19))
  
  # ... confidence interval
  conf.int <- cbind(predx, predict(linear_model, newdata = predx, interval = "confidence", level = 0.95))
  # ... prediction interval
  pred.int <- cbind(predx, predict(linear_model, newdata = predx, interval = "prediction", level = 0.95))
  
  g.pred <- ggplot(pred.int, aes(x = sixty_minute, y = fit)) +
    geom_point(data = data, aes(x = sixty_minute, y = ten_minute)) + #plots all the points
    #geom_point(data = newpoint, aes(y = .fitted), size = 3, color = "red") + # add new point optional must specify newpoint when calling function.
    geom_smooth(data = pred.int, aes(ymin = lwr, ymax = upr), stat = "identity") + # prediction interval
    geom_smooth(data = conf.int, aes(ymin = lwr, ymax = upr), stat = "identity") + #confidence interval
    geom_abline(intercept = 0, slope = 1) + #line y = x for reference
    theme_bw() +
    theme(text = element_text(size=10), axis.text.x = element_text(size = 10), axis.text.y = element_text(size = 10)) +
    xlab("60 minute per hour count") +
    ylab("10 minute per hour estimate") +
    ggtitle(paste0(this_year, " ", this_method, " ", this_species, " 10 vs.60"))
  g.pred  
}

graph_weirvssonar <- function(data, linear_model) { #, newpoint){
  #Use to make 95% CI and PI 
  minweir <- min(data$weir, na.rm = TRUE)
  maxweir <- max(data$weir, na.rm = TRUE)
  predx <- data.frame(weir = seq(from = minweir, to = maxweir, by = (maxweir-minweir)/19))
  
  # ... confidence interval
  conf.int <- cbind(predx, predict(linear_model, newdata = predx, interval = "confidence", level = 0.95))
  # ... prediction interval
  pred.int <- cbind(predx, predict(linear_model, newdata = predx, interval = "prediction", level = 0.95))
  
  g.pred <- ggplot(pred.int, aes(x = weir, y = fit)) +
    geom_point(data = data, aes(x = weir, y = sonar)) + #plots all the points
    #geom_point(data = newpoint, aes(y = .fitted), size = 3, color = "red") + # add new point optional must specify newpoint when calling function.
    geom_smooth(data = pred.int, aes(ymin = lwr, ymax = upr), stat = "identity") + # prediction interval
    geom_smooth(data = conf.int, aes(ymin = lwr, ymax = upr), stat = "identity") + #confidence interval
    geom_abline(intercept = 0, slope = 1) + #line y = x for reference
    theme_bw() +
    theme(text = element_text(size=10), axis.text.x = element_text(size = 10), axis.text.y = element_text(size = 10)) +
    xlab("weir 60 minute per hour count") +
    ylab("sonar 60 minute per hour count") +
    ggtitle(paste0(this_year, " 60 min/hr ", this_species, " weir vs sonar"))
  g.pred  
}

graph_template <- function(data){
  # Linear Regression 
  linear_model<- lm(dep ~ indep , data=data)
  #Use to make 95% CI and PI 
  minindep <- min(data$indep, na.rm = TRUE)
  maxindep <- max(data$indep, na.rm = TRUE)
  predx <- data.frame(indep = seq(from = minindep, to = maxindep, by = (maxindep-minindep)/19))
  
  # ... confidence interval
  conf.int <- cbind(predx, predict(linear_model, newdata = predx, interval = "confidence", level = 0.95))
  # ... prediction interval
  pred.int <- cbind(predx, predict(linear_model, newdata = predx, interval = "prediction", level = 0.95))
  
  
  g.pred <- ggplot(pred.int, aes(x = indep, y = fit)) +
    geom_point(data = data, aes(x = indep, y = dep)) + #plots all the points
    geom_smooth(data = pred.int, aes(ymin = lwr, ymax = upr), stat = "identity") + # prediction interval
    geom_smooth(data = conf.int, aes(ymin = lwr, ymax = upr), stat = "identity") + #confidence interval
    theme_bw() +
    theme(text = element_text(size=10), axis.text.x = element_text(size = 10), axis.text.y = element_text(size = 10)) +
    xlab("indep") +
    ylab("dep") #+
   #ggtitle("ten_minute vs sixty_minute")
  g.pred  
}

#functions for graphing diagnositics and returning a model
#note data will have to be filtered and arranged appropriately.

lm_10vs60 <- function(data){
  linear_model <- lm(ten_minute ~ sixty_minute, data = data)
  #layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
  #plot(linear_model)
  return(linear_model)
}

lm_60vs10 <- function(data){
  linear_model <- lm(sixty_minute ~ ten_minute, data = data)
  layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
  plot(linear_model)
  return(linear_model)
}

lm_weir60vssonar60 <- function(data){
  linear_model <- lm(sonar ~ weir , data = data)
  #layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
  #plot(linear_model)
  return(linear_model)
}
lm_weir10vssonar10 <- function(data){
  linear_model <- lm(weir ~ sonar , data = data)
  layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
  plot(linear_model)
  return(linear_model)
}
lm_weir60vssonar10 <- function(data){
  linear_model <- lm(weir60 ~ sonar10 , data = data)
  layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
  plot(linear_model)
  return(linear_model)
}

pvalues_lm_graph <- function(data = data_gathered, this_species, this_method, this_year){
  #this_species <- "sockeye"
  #this_year <- 2016 
  #this_method <- "sonar"
  #Filter out wanted data
  data_gathered <- data_gathered %>% filter(species == this_species, method == this_method, year == this_year)
  
  #Non- parametric test Ho: period of time counting estimates are the same Ha: estimates are different
  wilcox_out <- wilcox.test(abundance ~ period, data = data_gathered, paired = TRUE, alternative = "two.sided")
  wilcox <- wilcox_out$p.value
  
  #prepare data for parametic tests & graphing
  data_wide1060 <- data_gathered %>% 
    spread(period, abundance)
  
  #data_wide1060 <- chignik
  
  #create linear model
  linear_model <- lm_10vs60(data_wide1060)
  summary(linear_model)# show results
  
  #Test for normality of residuals
  shapiro_out <- shapiro.test(linear_model$residuals)
  shapiro <- shapiro_out$p.value
  
  #Note the following p_values & R squared are only really valid if shapiro_pvalue > 0.05
  #Test to see if linear regression is statistically significant (in this case aka slope is statistically sig)
  lm <- coef(summary(linear_model))[2,4]
  
  #adjusted r squared for those that like it.
  adj_r_squared <- summary(linear_model)$adj.r.squared
  
  #Test: Ho: The slope of the line is = 1. (AKA methods are equivalent)
  slope_eq1<- pvalue_of_t_test_slope_eq_1(linear_model)
  
  # Graph regression and put in figure file
  (graph <- graph_10vs60(data_wide1060, linear_model, this_year, this_method, this_species))
  ggsave(paste0("figures/", this_species, this_method, this_year, ".png"),
         dpi=600, height=6, width=6, units="in")
  
  species <- this_species 
  method <- this_method
  year <- this_year
  
  # return data frame of pvalues and adj.r.squared
  df <- data.frame(species, method, year, wilcox, shapiro, slope_eq1, adj_r_squared)
  
  out <- list(values = df, graph = graph)
  return(out)
}
