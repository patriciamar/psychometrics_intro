#-----------------------------------------------------------------
# Chapter 8 - Differential item functioning
# Computational aspects of psychometric methods. With R.
# P. Martinkova & A. Hladka
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# Packages
#-----------------------------------------------------------------

library(deltaPlotR)
library(difNLR)
library(difR)
library(ggplot2)
library(ltm)
library(mirt)
library(ShinyItemAnalysis)
library(cowplot)
library(Cairo)

#-----------------------------------------------------------------
# Plot settings
#-----------------------------------------------------------------

theme_fig <- function(base_size = 17, base_family = "") {
  theme_bw(base_size = base_size, base_family = base_family) +
    theme(
      legend.key = element_rect(fill = "white", colour = NA),
      axis.line = element_line(colour = "black"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_blank(),
      plot.title = element_blank(),
      legend.background = element_blank()
    )
}

#-----------------------------------------------------------------
# 8.3.1 Delta method
#-----------------------------------------------------------------

#--------------
data(MSATB, package = "difNLR")
head(MSATB, n = 2)
##   Item49 Item27 Item41 ...
## 1      1      0      0 ...
## 2      1      0      1 ...
## ...
#--------------

#--------------
# calculating proportions of correct answer per group
(pi0 <- colMeans(MSATB[MSATB$gender == 0, -21]))[1:3]
## Item49 Item27 Item41
## 0.8161 0.2335 0.3843
(pi1 <- colMeans(MSATB[MSATB$gender == 1, -21]))[1:3]
## Item49 Item27 Item41
## 0.8776 0.2470 0.3803
#--------------

#--------------
# calculation of standard normal quantiles
(z0 <- qnorm(1 - pi0))[1:3]
##  Item49  Item27  Item41
## -0.9007  0.7275  0.2942
(z1 <- qnorm(1 - pi1))[1:3]
## Item49  Item27  Item41
## -1.1629  0.6839  0.3047

# transformation into delta scores
(delta0 <- 4 * z0 + 13)[1:3]
## Item49  Item27  Item41
## 9.3974 15.9099 14.1769
(delta1 <- 4 * z1 + 13)[1:3]
## Item49  Item27  Item41
## 8.3482 15.7356 14.2190
#--------------

#--------------
s0 <- sd(delta0) # SD of delta scores - males
s1 <- sd(delta1) # SD of delta scores - females
s01 <- cov(delta0, delta1) # covariance of delta scores
m0 <- mean(delta0) # mean of delta scores - males
m1 <- mean(delta1) # mean of delta scores - females

# calculation of parameters a and b of major axis
(b <- (s1^2 - s0^2 + sqrt((s1^2 - s0^2)^2 + 4 * s01^2)) / (2 * s01))
## [1] 0.9784
(a <- m1 - b * m0)
## [1] 0.3787
#--------------

#--------------
# calculation of distances of delta scores from major axis
(D <- (b * delta0 + a - delta1) / (sqrt(b^2 + 1)))[1:3]
## Item49 Item27 Item41
## 0.8753 0.1493 0.0214
#--------------

#--------------
# delta plot using fixed threshold
(DP_fixed <- deltaPlotR::deltaPlot(data = MSATB, group = "gender",
                                   focal.name = 1, thr = 1.5))
## ...
##        Prop.Ref Prop.Foc Delta.Ref Delta.Foc   Dist.
## Item1    0.8161   0.8776    9.3974    8.3482  0.8753
## Item2    0.2335   0.2470   15.9099   15.7356  0.1493
## Item3    0.3843   0.3803   14.1769   14.2190  0.0214
## ...
## Code: '***' if item is flagged as DIF
## Parameters of the major axis:
##      a     b
##  0.379 0.978
## ...
#--------------

#--------------
# delta plot using normal approximation threshold
(DP_norm <- deltaPlotR::deltaPlot(data = MSATB, group = "gender",
                                  focal.name = 1, thr = "norm"))
## ...
##        Prop.Ref Prop.Foc Delta.Ref Delta.Foc   Dist.
## Item1    0.8161   0.8776    9.3974    8.3482  0.8753 ***
## Item2    0.2335   0.2470   15.9099   15.7356  0.1493
## Item3    0.3843   0.3803   14.1769   14.2190  0.0214
## ...
## Code: '***' if item is flagged as DIF
##
## Parameters of the major axis:
##      a     b
##  0.379 0.978
##
## Detection threshold: 0.606 (significance level: 5%)
## Items detected as DIF items:
## Item1
## ...
#--------------

#--------------
deltaPlotR::diagPlot(DP_fixed, thr.draw = TRUE)
deltaPlotR::diagPlot(DP_norm, thr.draw = TRUE)
#--------------

#-----------------------------------------------------------------
# 8.3.2 Mantel-Haenszel test
#-----------------------------------------------------------------

#--------------
score <- rowSums(MSATB[, 1:20]) # total score
MSATB$Item49 <- factor(MSATB$Item49, levels = c(1, 0))

# contingency table for item 49 and score 5
(tab1 <- table(MSATB[score == 5, c("gender", "Item49")]))
##       Item49
## gender  1  0
##      0 10  8
##      1 23  9
# odds ratio in contingency table above
n_item49_01_5 <- tab1[1, 1]
n_item49_00_5 <- tab1[1, 2]
n_item49_11_5 <- tab1[2, 1]
n_item49_10_5 <- tab1[2, 2]
(n_item49_01_5 * n_item49_10_5) / (n_item49_00_5 * n_item49_11_5)
## [1] 0.4891 

# contingency table for item 49 and score 12
(tab2 <- table(MSATB[score == 12, c("gender", "Item49")]))
##       Item49
## gender  1  0
##      0 30  6
##      1 86  8
# odds ratio in contingency table above
n_item49_01_12 <- tab2[1, 1]
n_item49_00_12 <- tab2[1, 2]
n_item49_11_12 <- tab2[2, 1]
n_item49_10_12 <- tab2[2, 2]
(n_item49_01_12 * n_item49_10_12) / (n_item49_00_12 * n_item49_11_12)
## [1] 0.9701
#--------------

#--------------
# contingency table for item 1 and all levels of total score
tabs <- xtabs(~ gender + Item49 + score, data = MSATB)

n_item49_01 <- sapply(1:dim(tabs)[3], function(i) tabs[1, 1, i])
n_item49_00 <- sapply(1:dim(tabs)[3], function(i) tabs[1, 2, i])
n_item49_11 <- sapply(1:dim(tabs)[3], function(i) tabs[2, 1, i])
n_item49_10 <- sapply(1:dim(tabs)[3], function(i) tabs[2, 2, i])
n_item49 <- n_item49_01 + n_item49_00 + n_item49_11 + n_item49_10

# alphaMH
(alphaMH <- sum(n_item49_01 * n_item49_10 / n_item49) /
  sum(n_item49_00 * n_item49_11 / n_item49))
## [1] 0.5430
#--------------

#--------------
# deltaMH
-2.35 * log(alphaMH)
## [1] 1.4352
#--------------

#--------------
n_item49_R <- n_item49_01 + n_item49_00 # reference group
n_item49_F <- n_item49_11 + n_item49_10 # focal group
n_item49_1 <- n_item49_01 + n_item49_11 # correct answers
n_item49_0 <- n_item49_00 + n_item49_10 # incorrect answers

# MH test statistic
(MHstat <- (abs(sum(n_item49_01 - n_item49_R * n_item49_1 / n_item49))
- 0.5)^2 /
  sum((n_item49_R * n_item49_F * n_item49_1 * n_item49_0) /
    (n_item49^2 * (n_item49 - 1))))
## [1] 12.4456
# critical value on 0.05 significance level
qchisq(p = 0.95, df = 1)
## [1] 3.8415
# p-value
(pvalue <- 1 - pchisq(MHstat, df = 1))
## [1] 0.0004

MSATB$Item49 <- as.numeric(paste(MSATB$Item49))
#--------------

#--------------
difR::difMH(Data = MSATB, group = "gender", focal.name = 1)
## ...
##        Stat.   P-value
## Item49 12.4456  0.0004 ***
## Item27  0.9159  0.3386
## ...
## Item68  5.0871  0.0241 *
## ...
## Items detected as DIF items:
## Item49
## Item68
##
## Effect size (ETS Delta scale):
## Effect size code:
## 'A': negligible effect
## 'B': moderate effect
## 'C': large effect
##
##        alphaMH deltaMH
## Item49  0.5430  1.4352 B
## Item27  0.8546  0.3693 A
## ...
## Item68  1.3659 -0.7328 A
## ...
## Effect size codes: 0 'A' 1.0 'B' 1.5 'C'
## (for absolute values of 'deltaMH')
## ...
#--------------

#-----------------------------------------------------------------
# 8.3.3 SIBTEST
#-----------------------------------------------------------------

#--------------
difR::difSIBTEST(MSATB, group = "gender", focal.name = 1)
## ...
##           Beta      SE X2 Stat. P-value
## Item49 -0.0871  0.0231 14.1465   0.0002 ***
## Item27 -0.0179  0.0230  0.6073   0.4358
## Item41 -0.0053  0.0246  0.0471   0.8282
## Item7   0.0356  0.0261  1.8647   0.1721
## Item38 -0.0321  0.0266  1.4620   0.2266
## ...
## Item2  -0.0213  0.0238  0.8000   0.3711
## ...
## Detection threshold: 3.841 (significance level: 0.05)
## Items detected as DIF items:
##   Item49
#--------------

#--------------
difR::difSIBTEST(MSATB, group = "gender", focal.name = 1, 
                 type = "nudif")
## ...
##           Beta    SE X2 Stat. P-value
## Item49  0.0871    NA 14.1465   0.0002 ***
## Item27  0.0179    NA  0.6073   0.4358
## Item41  0.0229    NA  0.8891   0.6411
## Item7   0.0356    NA  1.8647   0.1721
## Item38  0.0591    NA  7.2962   0.0260 *
## ...
## Item2   0.0175      NA  0.8053   0.6685
## ...
## Detection threshold: 3.841 (significance level: 0.05)
## ...
## Items detected as DIF items:
##   Item49
##   Item38
##   Item76
#--------------

#--------------
lapply(1:20, function(i)
  mirt::SIBTEST(dat = MSATB[, 1:20], group = MSATB$gender,
                suspect_set = i)
)
## [[1]]
##                     focal_group n_matched_set n_suspect_set  beta
## SIBTEST                       0            19             1 0.087
## CSIBTEST                      0            19             1 0.087
##                        SE     X2 df     p
## SIBTEST             0.023 14.146  1 0.000
## CSIBTEST               NA 14.146  1 0.000
## ...
#--------------

#-----------------------------------------------------------------
# 8.4.1. Logistic regression
#-----------------------------------------------------------------

#--------------
zscore <- as.vector(scale(rowSums(MSATB[, 1:20]))) # Z-score
fit1 <- glm(Item49 ~ zscore * gender, data = MSATB, family = binomial)
fit0 <- glm(Item49 ~ zscore, data = MSATB, family = binomial)
anova(fit0, fit1, test = "LRT")
## Analysis of Deviance Table
##
## Model 1: Item49 ~ score
## Model 2: Item49 ~ score * gender
## Resid. Df Resid. Dev Df Deviance Pr(>Chi)
## 1      1405      982.09
## 2      1403      967.33  2    14.76 0.0006 ***
## ---
## Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
#--------------

#--------------
predict(fit1, newdata = data.frame(zscore = c(-1, 0, 1), gender = 0),
        type = "response")
##      1      2      3
## 0.6457 0.8660 0.9582

predict(fit1, newdata = data.frame(zscore = c(-1, 0, 1), gender = 1),
        type = "response")
##      1      2      3
## 0.7819 0.9215 0.9747
#--------------

#--------------
summary(fit0)
## ...
##              Estimate Std. Error z value Pr(>|z|)
## (Intercept)    2.2231     0.1060   20.97   <2e-16 ***
## zscore         1.1860     0.1026   11.56   <2e-16 ***
## ...
summary(fit1)
## ...
##               Estimate Std. Error z value Pr(>|z|)
## (Intercept)     1.8659     0.1582   11.79  < 2e-16 ***
## zscore          1.2659     0.1671    7.58  3.6e-14 ***
## gender          0.5973     0.2147    2.78   0.0054 **
## zscore:gender  -0.0797     0.2142   -0.37   0.7099
## ...
#--------------

#--------------
c(a = coef(fit1)[2],
  b = -coef(fit1)[1] / coef(fit1)[2],
  aDIF = coef(fit1)[4],
  bDIF = (coef(fit1)[1] * coef(fit1)[4] - coef(fit1)[2] * coef(fit1)[3]) / 
    (coef(fit1)[2] * (coef(fit1)[2] + coef(fit1)[4])))
##      a       b    aDIF    bDIF
## 1.2659 -1.4740 -0.0797 -0.6025
#--------------

#--------------
msm::deltamethod(list(~x2, ~ -x1 / x2,
                      ~x4, ~ (x1 * x4 - x2 * x3) / (x2 * (x2 + x4))),
                 mean = coef(fit1),
                 cov = vcov(fit1))
## [1] 0.1671 0.1584 0.2142 0.2374
#--------------

#--------------
(fit.LR <- difR::difLogistic(Data = MSATB, group = "gender", 
                             focal.name = 1, match = zscore))
## ... 
##        Stat.   P-value    
## Item49 14.7603  0.0006 ***
## Item27  1.2130  0.5453    
## Item41  0.6366  0.7274    
## ...
## Items detected as DIF items:
## Item49
## 
## Effect size (Nagelkerke's R^2): 
## Effect size code: 
##  'A': negligible effect 
##  'B': moderate effect 
##  'C': large effect 
##        R^2    ZT JG
## Item49 0.0164 A  A 
## Item27 0.0007 A  A 
## Item41 0.0003 A  A 
## ...
## Effect size codes: 
##  Zumbo & Thomas (ZT): 0 'A' 0.13 'B' 0.26 'C' 1 
##  Jodoin & Gierl (JG): 0 'A' 0.035 'B' 0.07 'C' 1 
## ...
#--------------

#--------------
fit.LR$logitPar[1, ]
## (Intercept)       SCORE       GROUP SCORE:GROUP 
##      1.8659      1.2659      0.5973     -0.0797
#--------------

#--------------
plot(fit.LR, plot = "itemCurve", item = 1)
#--------------

#--------------
(fit.NLR.2PL <- difNLR::difNLR(Data = MSATB, group = "gender", 
                               focal.name = 1, model = "2PL"))
## ...
##        Chisq-value P-value
## Item49 22.5070      0.0000 ***
## Item27  0.8534      0.6527
## Item41  0.8120      0.6663
## ...
## Items detected as DIF items:
## Item49
## Item68
coef(fit.NLR.2PL)$Item49
##      a       b    aDif    bDif
## 1.1203 -1.5514 -0.0928 -0.6922
#--------------

#--------------
plot(fit.NLR.2PL, item = "Item49")
#--------------

#--------------
(fit.NLR.3PL <- difNLR::difNLR(Data = MSATB, group = "gender", 
                               focal.name = 1,  model = "3PLc"))
## ...
##        Chisq-value P-value
## Item49 22.3978      0.0001 ***
## Item27  1.0883      0.7799
## Item41  1.4556      0.6925
## ...
## Items detected as DIF items:
## Item49
## Item47
#--------------

#--------------
# parameters for item 47
coef(fit.NLR.3PL, SE = TRUE)$Item47
##               a       b       c    aDif    bDif    cDif
## estimate 3.9562 -1.4195  0.4807 -2.7970 -1.0999 -0.4807
## SE       1.3838  0.1689  0.1284  1.4310  1.8441  1.3225

# plot of characteristic curves for item 47
plot(fit.NLR.3PL, item = "Item47", group.names = c("Males", "Females"))
#--------------

#--------------
# loading data
data(Anxiety, package = "lordif")
Anxiety_items <- Anxiety[, paste0("R", 1:29)]
#--------------

#--------------
# DIF with cumulative logit regression model
(fit.ORD1 <- difNLR::difORD(Data = Anxiety_items, group = Anxiety$gender,
                            focal.name = 1, model = "cumulative"))
## ...
##     Chisq-value P-value 
## ...
## R6  13.8917      0.0010 ***
## R7   9.3795      0.0092 **
## R8   1.2370      0.5388
## ...
## R19  9.0748      0.0107 *
## R20 10.6796      0.0048 **
## R21  5.9576      0.0509 .
## ...
## Items detected as DIF items:
## R6
## R7
## R10
## R19
## R20

#--------------
# coefficients for item R6
coef(fit.ORD1, SE = TRUE)$R6
##              b2     b3     b4     b5     a
## estimate 0.2248 1.1264 2.1714 3.2289 2.1390
## SE       0.0640 0.0899 0.1393 0.2235 0.1490
##           bDIF2  bDIF3  bDIF4  bDIF5   aDIF
## estimate 0.3112 0.2811 0.2462 0.2109 0.0738
## SE       0.0821 0.1049 0.1711 0.2498 0.1791
#--------------

#--------------
# plot of cumulative probabilities
plot(fit.ORD1, item = "R6", plot.type = "cumulative", 
     group.names = c("Males", "Females"))
# plot of category probabilities
plot(fit.ORD1, item = "R6", plot.type = "category", 
     group.names = c("Males", "Females"))
#--------------

#--------------
# DIF with adjacent category logit regression model
(fit.ORD2 <- difNLR::difORD(Data = Anxiety_items, 
                            group = Anxiety$gender,
                            focal.name = 1, model = "adjacent"))
## ...
##     Chisq-value P-value 
## ...
## R6   9.8619      0.0072 **
## R7   9.9535      0.0069 **
## R8   1.0119      0.6029
## ...
## R19  9.1928      0.0101 *
## R20 11.1244      0.0038 **
## R21  3.0459      0.2181
## ...
## Items detected as DIF items:
## R6
## R7
## R19
## R20
#--------------

#--------------
# coefficients for item R6
coef(fit.ORD2, SE = TRUE)$R6
##              b2     b3     b4     b5      a
## estimate 0.6395 0.9013 2.1545 3.1694 1.3925
## SE       0.1119 0.1248 0.1905 0.3116 0.1205
##           bDIF2  bDIF3  bDIF4  bDIF5   aDIF
## estimate 0.2754 0.2677 0.2307 0.2008 0.0423
## SE       0.0900 0.0969 0.1745 0.2564 0.1274

# plot of category probabilities
plot(fit.ORD2, item = "R6", group.names = c("Males", "Females"))
#--------------

#--------------
# loading data
data(HCItest, HCIkey, package = "ShinyItemAnalysis")

# DDF with multinomial regression model
(fit.DDF <- difNLR::ddfMLR(Data = HCItest[, 1:20], 
                           group = HCItest$gender, 
                           focal.name = 1, key = unlist(HCIkey)))
##         Chisq-value P-value
## ...
## Item.12 18.5029      0.0178 *
## Item.13  9.1026      0.1679
## ...
## Item.18  6.8674      0.3333
## Item.19 19.9421      0.0106 *
## Item.20 12.0779      0.0603 .
## ...
## Items detected as DDF items:
## Item.12
## Item.19
#--------------

#--------------
# estimated coefficients for item 12
coef(fit.DDF, SE = TRUE)[[12]]
##                  b       a    bDIF    aDIF
## A estimate -2.0365 -1.0434  1.0564 -0.3526
## A SE        0.3755  0.2183  0.4323  0.3274
## B estimate -2.2219 -2.3621 -0.6212  1.3403
## B SE        0.2960  0.6244  1.3024  0.7707
## C estimate -2.6307 -1.0247  1.1059 -0.9152
## C SE        0.6225  0.2779  0.6715  0.4874
## E estimate -0.9933 -0.8399  0.4498 -0.3577
## E SE        0.1953  0.1385  0.2633  0.2436

# plot of ICCs for item 12
plot(fit.DDF, item = 12, group.names = c("Males", "Females"))
#--------------

#-----------------------------------------------------------------
# 8.3.5.1 Lord's test
#-----------------------------------------------------------------

#--------------
difR::difLord(Data = MSATB, group = "gender", focal.name = 1, 
              model = "2PL")
## ...
##          Stat.  P-value
## Item49 9.5230 0.0086  **
## Item27 0.7242 0.6962
## Item41 0.6427 0.7252
## ...
## Detection threshold: 5.992 (significance level: 0.05)
## Items detected as DIF items:
##   Item49
#--------------

#--------------
fitMG <- mirt::multipleGroup(data = MSATB[, 1:20], model = 1, 
                             group = as.factor(MSATB$gender),
                             SE = TRUE)
mirt::DIF(fitMG, which.par = c("a1", "d"), Wald = TRUE)
##            W df     p
## Item49 9.334  2 0.009
## Item27 0.409  2 0.815
## Item41 0.764  2 0.683
## ...
#--------------

#--------------
coef(fitMG)
## $`0`
## $Item49
##            a1     d  g  u
## par     1.040 1.789  0  1
## CI_2.5  0.664 1.465 NA NA
## CI_97.5 1.416 2.113 NA NA
## ...
## $`1`
## $Item49
##            a1     d  g  u
## par     0.998 2.301  0  1
## CI_2.5  0.697 2.021 NA NA
## CI_97.5 1.299 2.582 NA NA
## ...
#--------------

#--------------
mirt::itemplot(fitMG, item = "Item49")
#--------------

#-----------------------------------------------------------------
# 8.3.5.2 Likelihood ratio test
#-----------------------------------------------------------------

#--------------
difR::difLRT(Data = MSATB, group = "gender", focal.name = 1)
#--------------

#--------------
mirt::DIF(fitMG, which.par = c("a1", "d"), Wald = FALSE)
##           AIC   AICc  SABIC     HQ    BIC    X2 df     p
## Item49 -5.288 -4.794 -1.143 -1.364  5.210 9.288  2 0.010
## Item27  3.585  4.079  7.730  7.509 14.083 0.415  2 0.813
## Item41  3.255  3.749  7.400  7.179 13.753 0.745  2 0.689
## ...
#--------------

#-----------------------------------------------------------------
# 8.3.5.3 Raju's test
#-----------------------------------------------------------------

#--------------
difR::difRaju(Data = MSATB, group = "gender", focal.name = 1, 
              model = "1PL")
## ...
##           Stat.   P-value
## Item49 -3.4433  0.0006 ***
## Item27 -0.8871  0.3750
## Item41 -0.2233  0.8233
## ...
## Detection thresholds: -1.96 and 1.96 (significance level: 0.05)
## Items detected as DIF items:
##   Item49
##   Item68
##
## Effect size (ETS Delta scale):
## Effect size code:
##   'A': negligible effect
##   'B': moderate effect
##   'C': large effect
##
##          mF-mR   deltaRaju
## Item49 -0.5967  1.4022   B
## Item27 -0.1369  0.3217   A
## Item41 -0.0310  0.0728   A
## ...
## Effect size codes: 0 'A' 1.0 'B' 1.5 'C'
## (for absolute values of 'deltaRaju')
#--------------

#-----------------------------------------------------------------
# 8.4.1 Item purification
#-----------------------------------------------------------------

#--------------
fit_ORD3 <- difNLR::difORD(Data = Anxiety_items, 
                           group = Anxiety$gender,
                           focal.name = 1, model = "cumulative",
                           purify = TRUE)
fit_ORD3$difPur
##       R1 R2 R3 R4 R5 R6 R7 R8 R9 R10 R11 R12 R13 R14 R15 R16
## Step0  0  0  0  0  0  1  1  0  0   1   0   0   0   0   0   0
## Step1  0  0  0  0  0  1  1  0  0   0   0   0   0   0   0   0
## Step2  0  0  0  0  0  1  1  0  0   0   0   0   0   0   0   0
## Step3  0  0  0  0  0  1  1  0  0   0   0   0   0   0   0   0
##       R17 R18 R19 R20 R21 R22 R23 R24 R25 R26 R27 R28 R29
## Step0   0   0   1   1   0   0   0   0   0   0   0   0   0
## Step1   0   0   1   1   1   0   0   0   0   0   0   0   0
## Step2   0   0   1   1   0   0   0   0   0   0   0   0   0
## Step3   0   0   1   1   0   0   0   0   0   0   0   0   0
#--------------

#-----------------------------------------------------------------
# 8.4.1 Corrections for multiple comparisons
#-----------------------------------------------------------------

#--------------
# without multiple comparison correction
difR::difLogistic(Data = HCI[, 1:20], group = HCI$gender, 
                  focal.name = 1)$p.value
##  [1] 0.0380 0.9420 0.8183 0.2199 0.5072 0.2608 0.8268 0.4240 0.1889
## [10] 0.2971 0.0823 0.0425 0.1989 0.8801 0.8078 0.9019 0.7614 0.8740
## [19] 0.0078 0.0102
# using Benjamini-Hochberg correction
difR::difLogistic(Data = HCI[, 1:20], group = HCI$gender, 
                  focal.name = 1, p.adjust.method = "BH")$adjusted.p
##  [1] 0.2123 0.9420 0.9420 0.5497 0.8453 0.5796 0.9420 0.7709 0.5497
## [10] 0.5943 0.3290 0.2123 0.5497 0.9420 0.9420 0.9420 0.9420 0.9420
## [19] 0.1017 0.1017
#--------------