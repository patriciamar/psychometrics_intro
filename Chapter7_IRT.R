#-----------------------------------------------------------------
# Chapter 7 - Item response theory models
# Computational aspects of psychometric methods. With R.
# P. Martinkova & A. Hladka
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# Packages
#-----------------------------------------------------------------

library(eRm)
library(ggplot2)
library(lme4)
library(ltm)
library(mirt)
library(TAM)
library(brms)
library(lavaan)
library(reshape)
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

# margins for mirt plots
lw <- list(left.padding = list(x = 0.1, units = "inches"))
lw$right.padding <- list(x = -0.1, units = "inches")
lh <- list(bottom.padding = list(x = 0, units = "inches"))
lh$top.padding <- list(x = -0.2, units = "inches")

lattice.options(layout.widths = lw, layout.heights = lh)

#-----------------------------------------------------------------
# 7.3.1  Rasch model and 1PL IRT model
#-----------------------------------------------------------------

#--------------
data(HCI, package = "ShinyItemAnalysis")
head(HCI)
summary(HCI)
#--------------

#--------------
fit_rasch_mirt <- mirt::mirt(data = HCI[, 1:20], model = 1, 
                             itemtype = "Rasch", SE = TRUE)
#--------------

#--------------
# coefficients - intercept/slope parametrization d + a1 * x with SE added
coef(fit_rasch_mirt, SE = TRUE)
## $`Item 1`
##         a1     d  g  u
## par      1 0.963  0  1
## CI_2.5  NA 0.774 NA NA
## CI_97.5 NA 1.152 NA NA
##  ...
## $GroupPars
##         MEAN_1 COV_11
## par          0  0.669
## CI_2.5      NA  0.558
## CI_97.5     NA  0.780
#--------------

#--------------
# coefficients - IRT parametrization a * (x - b)
coef(fit_rasch_mirt, IRTpars = TRUE, simplify = TRUE)
## $items
##         a      b g u
## Item 1  1 -0.963 0 1
## Item 2  1 -1.267 0 1
## ...
## Item 20 1 -1.089 0 1
#--------------

#--------------
# ICC
plot(fit_rasch_mirt, type = "trace", facet_items = FALSE)
#--------------

#--------------
# test score curve
plot(fit_rasch_mirt)
#--------------

#--------------
# latent abilities (factor scores) with SE
fs_SE <- mirt::fscores(fit_rasch_mirt, full.scores.SE = TRUE)
head(fs_SE, n = 3)
##          F1  SE_F1
## [1,] 0.7096 0.4609
## [2,] 1.4169 0.5149
## [3,] 0.9286 0.4756
#--------------

#--------------
summary(fs_SE[, 1])
##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
## -1.7051 -0.4252 -0.0680 -0.0001  0.5028  1.6951
sd(fs_SE[, 1])
## [1] 0.6899
#--------------

#--------------
# comparison with total test score
total_score <- rowSums(HCI[, 1:20])
cor(total_score, fs_SE[, 1])
# [1] 0.9985

ggplot(
  data.frame(total_score, fs = fs_SE[, 1]),
  aes(x = total_score, y = fs)
) +
  geom_point(size = 1.8) +
  xlab("Total score") +
  ylab("Factor score") + 
  theme_fig()
#--------------

#--------------
ggplot(
  data.frame(fs = fs_SE[, 1]),
  aes(x = fs)
) +
  geom_histogram(bins = length(unique(total_score)), col = "black", fill = "gold") +
  xlab(expression(Ability~theta)) +
  ylab("Number of respondents") + 
  theme_fig()
#--------------

#--------------
# ltm package

#--------------
# Rasch model, discrimination fixed at value of 1
fit_rasch_ltm <- ltm::rasch(HCI[, 1:20], constraint = cbind(20 + 1, 1))
summary(fit_rasch_ltm)

# coefficients - IRT parametrization
coef(fit_rasch_ltm)
##          Dffclt Dscrmn
## Item 1  -0.9892      1
## Item 2  -1.2996      1
## ...
## Item 20 -1.1181      1
#--------------

#--------------
# ICC
plot(fit_rasch_ltm)
#--------------

#-------------- 
# latent abilities (factor scores)
head(factor.scores(fit_rasch_ltm)$score.dat[, c("z1", "se.z1")], n = 3)
##        z1  se.z1
## 1 -1.4503 0.4540
## 2 -1.8849 0.4807
## 3 -1.2482 0.4456
#--------------

#--------------
# ltm 1PL model, discrimination not fixed
fit_1PL_ltm <- ltm::rasch(HCI[, 1:20])
summary(fit_1PL_ltm)

# coefficients - IRT parametrization
coef(fit_1PL_ltm)
##              Dffclt    Dscrmn
##  Item 1  -1.1774477 0.8178688
##  Item 2  -1.5489772 0.8178688
## ...
##  Item 20 -1.3314659 0.8178688
#--------------

#--------------
# eRm package
# Rasch model with sum-0 beta restriction
fit_rasch_eRm1 <- eRm::RM(X = HCI[, 1:20])
fit_rasch_eRm1
summary(fit_rasch_eRm1)
coef(fit_rasch_eRm1)
## beta Item 1  beta Item 2  beta Item 3  beta Item 4  beta Item 5
##      0.3963       0.6994       1.3619      -1.0137      -0.8327
## beta Item 6  beta Item 7  beta Item 8  beta Item 9 beta Item 10
##     -1.2151      -0.3496       0.4294      -0.8758       0.1350
## beta Item 11 beta Item 12 beta Item 13 beta Item 14 beta Item 15
##      0.8608      -0.2278      -0.0602       0.7364      -0.8255
## beta Item 16 beta Item 17 beta Item 18 beta Item 19 beta Item 20
##     -0.0676      -1.5564       0.9823       0.9005       0.5222
#--------------

#--------------
# shifted by mean ability estimate
lat_var <- person.parameter(fit_rasch_eRm1)
lat_var$thetapar[1]
mean(as.numeric(unlist(lat_var$thetapar)))
## [1] 0.5789
coef(fit_rasch_eRm1) + mean(as.numeric(unlist(lat_var$thetapar)))
## beta Item 1  beta Item 2  beta Item 3  beta Item 4  beta Item 5 
##      0.9753       1.2784       1.9409      -0.4348      -0.2537 
## beta Item 6  beta Item 7  beta Item 8  beta Item 9 beta Item 10 
##     -0.6361       0.2294       1.0084      -0.2968       0.7139 
## beta Item 11 beta Item 12 beta Item 13 beta Item 14 beta Item 15 
##       1.4398       0.3512       0.5187       1.3154      -0.2466 
## beta Item 16 beta Item 17 beta Item 18 beta Item 19 beta Item 20 
##       0.5113      -0.9775       1.5612       1.4795       1.1012 
#--------------

#--------------
# Rasch model with beta.1 restricted to 0
fit_rasch_eRm2 <- eRm::RM(X = HCI[, 1:20], sum0 = FALSE)
fit_rasch_eRm2
coef(fit_rasch_eRm2)
## beta Item 1  beta Item 2  beta Item 3  beta Item 4  beta Item 5
##      0.0000       0.3031       0.9656      -1.4101       -1.229
## beta Item 6  beta Item 7  beta Item 8  beta Item 9 beta Item 10
##     -1.6114      -0.7459       0.0330      -1.2722      -0.2614
## beta Item 11 beta Item 12 beta Item 13 beta Item 14 beta Item 15
##      0.4645      -0.6241      -0.4566       0.3401      -1.2219
## beta Item 16 beta Item 17 beta Item 18 beta Item 19 beta Item 20
##     -0.4640      -1.9528       0.5859       0.5042       0.1259
#--------------


#--------------
# TAM package
# JML estimation
fit_rasch_TAM1 <- TAM::tam.jml(HCI[, 1:20])
fit_rasch_TAM1$xsi
##  [1] -0.9855 -1.2883 -1.9470  0.4327  0.2496  0.6366 -0.2373 -1.0186
##  [9]  0.2932 -0.7238 -1.4491 -0.3598 -0.5281 -1.3251  0.2424 -0.5207
## [17]  0.9830 -1.5700 -1.4887 -1.1113
#--------------

#--------------
#MML estimation - sum-0 constraint
fit_rasch_TAM2 <- TAM::tam.mml(HCI[, 1:20], constraint="items") 
betas_TAM2 <- c(fit_rasch_TAM2$xsi[,1],-sum(fit_rasch_TAM2$xsi[,1]))
# latent abilities
lat_var_TAM <- TAM::tam.wle(fit_rasch_TAM2)
# item parameters shifted by mean latent ability
betas_TAM2 - mean(lat_var_TAM[,"theta"])
##  [1] -0.9660 -1.2700 -1.9365  0.4412  0.2608  0.6420 -0.2207 -0.9992
##  [9]  0.3038 -0.7046 -1.4321 -0.3423 -0.5095 -1.3072  0.2536 -0.5022
## [17]  0.9825 -1.5543 -1.4721 -1.0930
#--------------

#--------------
# lme4 package
# data long format:
HCI.wide <- HCI
HCI.wide$person <- as.factor(1:nrow(HCI))
HCI.wide$zscore <- scale(rowSums(HCI.wide[, 1:20]))
# converting data to the long format
HCI.long <- reshape(
  data = HCI.wide,
  varying = list(paste("Item", 1:20)), timevar = "item",
  v.names = "rating",
  idvar = c("person", "gender", "major", "zscore"),
  direction = "long", new.row.names = 1:13020
)
summary(HCI.long)
head(HCI.long)
#--------------

#--------------
# fit Rasch model with lme4 (TAKES FEW MINUTES! COMMENTED FOR NOW)
HCI.long$item <- as.factor(HCI.long$item)
fit_rasch_glmer <- lme4::glmer(rating ~ -1 + item + (1 | person),
                               data = HCI.long, family = binomial)
coef(fit_rasch_glmer)$person[1, -1]
##    Item1 Item2 Item3   Item4   Item5  Item6  Item7  Item8   Item9
## 1 0.9494 1.266 1.925 -0.4515 -0.2701 -0.653 0.2068 0.9911 -0.3128
##   Item10 Item11 Item12 Item13 Item14  Item15 Item16  Item17 Item18
## 1 0.6961  1.424 0.3299  0.502  1.299 -0.2613 0.4977 -0.9936  1.549
##   Item19 Item20
## 1 1.4670 1.0880
#--------------

#--------------
# brms package (Bayesian 1PL IRT)
formula_1PL <- bf(rating ~ 1 + (1 | item) + (1 | person))
#formula_1PL <- bf(rating ~ 0 + item + (1 | person))
prior_1PL <- prior("normal(0, 3)", class = "sd", group = "person") +
             prior("normal(0, 3)", class = "sd", group = "item")
#prior_1PL <- prior("normal(0, 3)", class = "sd", group = "person")


fit_1PL_brms <- brm(formula = formula_1PL,
  data = HCI.long, family = brmsfamily("bernoulli", "logit"),
  prior = prior_1PL)
coef(fit_1PL_brms)$item[, , "Intercept"]
##     Estimate Est.Error     Q2.5    Q97.5
##  1    0.9602   0.09574  0.76907  1.15350
##  2    1.2570   0.09977  1.06261  1.45843
##  3    1.9112   0.11642  1.68002  2.14513
##  4   -0.4359   0.09231 -0.61655 -0.25707
##  5   -0.2549   0.08821 -0.42376 -0.07950
##  6   -0.6331   0.09203 -0.81080 -0.45376
##  7    0.2182   0.08939  0.04554  0.38996
##  8    0.9897   0.09536  0.80870  1.17961
##  9   -0.2992   0.08925 -0.47398 -0.12246
## 10    0.6982   0.09200  0.51844  0.87965
## 11    1.4174   0.10446  1.21841  1.62221
## 12    0.3417   0.08872  0.16662  0.51027
## 13    0.5081   0.09144  0.32887  0.69132
## 14    1.2946   0.10041  1.09431  1.49231
## 15   -0.2483   0.08794 -0.42191 -0.07667
## 16    0.4979   0.09009  0.32538  0.67370
## 17   -0.9669   0.09658 -1.15987 -0.77796
## 18    1.5384   0.10873  1.32993  1.75239
## 19    1.4557   0.10322  1.25663  1.64973
## 20    1.0797   0.09478  0.89838  1.26513

plot(fit_1PL_brms)
#--------------

#--------------
b_mirt = coef(fit_rasch_mirt, IRTpars = TRUE, 
             simplify = TRUE)$items[, "b"]
b_ltm = coef(fit_rasch_ltm)[, 1]
b_eRm1 = -coef(fit_rasch_eRm1) - mean(as.numeric(unlist(lat_var$thetapar)))
b_lme4 = -unlist(coef(fit_rasch_glmer)$person[1, -1])
b_TAMj = fit_rasch_TAM1$xsi
b_TAMm = betas_TAM2 - mean(lat_var_TAM[,"theta"])
b_brms = - coef(fit_1PL_brms)$item[, "Estimate", "Intercept"]
cbind(b_mirt, b_ltm, b_eRm1, b_lme4, b_TAMj, b_TAMm, b_brms)

##          b_mirt   b_ltm  b_eRm1  b_lme4  b_TAMj  b_TAMm  b_brms
## Item 1  -0.9632 -0.9892 -0.9753 -0.9494 -0.9855 -0.9660 -0.9595
## Item 2  -1.2672 -1.2996 -1.2784 -1.2662 -1.2883 -1.2700 -1.2612
## Item 3  -1.9339 -1.9787 -1.9409 -1.9255 -1.9470 -1.9365 -1.9122
## Item 4   0.4443  0.4531  0.4348  0.4515  0.4327  0.4412  0.4341
## ...
## Item 20 -1.0894 -1.1181 -1.1012 -1.0876 -1.1113 -1.0930 -1.0868
#--------------


# #--------------
# # traditional difficulty estimates
(dif_trad <- colMeans(HCI[, 1:20])) # traditional difficulty estimates
# ##  Item 1  Item 2  Item 3  Item 4  Item 5  Item 6  Item 7  Item 8  Item 9
# ##  0.6989  0.7527  0.8479  0.4040  0.4424  0.3625  0.5469  0.7051  0.4332
# ## Item 10 Item 11 Item 12 Item 13 Item 14 Item 15 Item 16 Item 17 Item 18
# ##  0.6482  0.7788  0.5730  0.6083  0.7588  0.4439  0.6068  0.2965  0.7972
# ## Item 19 Item 20
# ##  0.7849  0.7220
#
# as.vector(scale(dif_trad))
cor(b_mirt, dif_trad)
## [1] -0.998
plot(b_mirt, dif_trad)
#--------------

#--------------
# Wright map
b <- coef(fit_rasch_mirt, simplify = TRUE, IRTpars = TRUE)$items[, "b"]
ggWrightMap(fs_SE[, 1], b)
#--------------

#-----------------------------------------------------------------
# 7.3.2 2PL IRT model
#-----------------------------------------------------------------

#--------------
# mirt() of mirt package
fit_2PL_mirt <- mirt::mirt(HCI[, 1:20], model = 1, itemtype = "2PL", 
                           SE = TRUE)
# coefficients
coef(fit_2PL_mirt, IRTpars = TRUE, simplify = TRUE)
## $items
##             a      b g u
## Item 1  0.851 -1.146 0 1
## Item 2  0.717 -1.723 0 1
## ...
## Item 20 0.988 -1.162 0 1
#--------------

#--------------
# ltm package
fit_2PL_ltm <- ltm::ltm(HCI[, 1:20] ~ z1)
coef(fit_2PL_ltm)
##          Dffclt Dscrmn
## Item 1  -1.1459 0.8511
## Item 2  -1.7226 0.7167
## ...
## Item 20 -1.1617 0.9886
#--------------

#-----------------------------------------------------------------
# 7.3.3 Normal ogive model
#-----------------------------------------------------------------

# TO BE ADDED

#-----------------------------------------------------------------
# 7.3.4 3PL IRT model
#-----------------------------------------------------------------

#--------------
fit_3PL_mirt <- mirt::mirt(HCI[, 1:20], model = 1, itemtype = "3PL", 
                           SE = TRUE, technical = list(NCYCLES = 2000))
# coefficients
coef(fit_3PL_mirt, IRTpars = TRUE, simplify = TRUE)
## $items
##             a      b     g u
## Item 1  1.080 -0.331 0.296 1
## Item 2  0.759 -1.353 0.135 1
## ...
## Item 20 0.952 -1.041 0.079 1
#--------------

#--------------
# test score function
plot(fit_3PL_mirt)
 
# ICC
plot(fit_3PL_mirt, type = "trace", facet_items = FALSE)
 
# IIC
plot(fit_3PL_mirt, type = "infotrace", facet_items = FALSE)
 
# TIC
plot(fit_3PL_mirt, type = "infoSE")
#--------------

#--------------
# latent abilities (factor scores)
fs <- as.vector(fscores(fit_3PL_mirt))
summary(fs)
#--------------

#--------------
# ltm package
fit_3PL_ltm <- ltm::tpm(HCI[, 1:20])
coef(fit_3PL_ltm)
##         Gussng  Dffclt Dscrmn
## Item 1  0.2983 -0.3177 1.0864
## Item 2  0.1785 -1.2092 0.7837
## ...
## Item 20 0.0678 -1.0653 0.9437
#--------------

#-----------------------------------------------------------------
# 7.3.5 4PL IRT model
#-----------------------------------------------------------------

#--------------
fit_4PL_mirt <- mirt(HCI[, 1:20], model = 1, itemtype = "4PL", 
                     SE = TRUE)
summary(fit_4PL_mirt)
coef(fit_4PL_mirt)
## $`Item 1`
## a1     d     g     u
## par 1.22 0.087 0.378 0.999
## ...
## $GroupPars
## MEAN_1 COV_11
## par      0      1

## Warning message:
## Could not invert information matrix; model likely is not 
## empirically identified.
#--------------

#--------------
# ICC
plot(fit_4PL_mirt, type = "trace", facet_items = FALSE)
 
# IIC
plot(fit_4PL_mirt, type = "infotrace", facet_items = FALSE)
 
# TIC
plot(fit_4PL_mirt, type = "infoSE")
 
# test score function
plot(fit_4PL_mirt)
#--------------

#--------------
# coefficients
coef(fit_4PL_mirt, simplify = TRUE)
coef(fit_4PL_mirt, IRTpars = TRUE, simplify = TRUE)
#--------------

#--------------
# latent abilities (factor scores)
fs <- as.vector(fscores(fit_4PL_mirt))
summary(fs)
#--------------

#-----------------------------------------------------------------
# 7.3.6 Item and test information
#-----------------------------------------------------------------

#--------------
# ICC
plot(fit_2PL_mirt, type = "trace", facet_items = FALSE)
#--------------

#--------------
# IIC
plot(fit_2PL_mirt, type = "infotrace", facet_items = FALSE)
#--------------

#--------------
# TIC
plot(fit_2PL_mirt, type = "infoSE")
#--------------

#--------------
# latent abilities (factor scores)
fs <- as.vector(fscores(fit_2PL_mirt))
summary(fs)
##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
## -2.0438 -0.6429 -0.0262  0.0000  0.6541  1.8618
#--------------

#-----------------------------------------------------------------
# 7.4  IRT models for polytomous items
#-----------------------------------------------------------------

#--------------
data("Anxiety", package = "lordif")
head(Anxiety_items <- Anxiety[, paste0("R", 1:29)], n = 2)
##   R1 R2 R3 R4 R5 R6 R7 R8 R9 R10 R11 R12 R13 R14 R15 R16 R17
## 1  1  1  1  1  1  1  1  2  2   1   2   2   1   1   1   1   1
## 2  1  1  1  1  1  1  1  1  1   1   1   1   1   1   1   1   1
##   R18 R19 R20 R21 R22 R23 R24 R25 R26 R27 R28 R29
## 1   2   1   2   2   1   1   2   3   2   1   1   2
## 2   1   1   1   1   1   1   1   2   1   1   1   1
#--------------

#-----------------------------------------------------------------
# 7.4.1  Graded response model
#-----------------------------------------------------------------

#--------------
# GRM with the mirt package
fit_GRM_mirt <- mirt::mirt(Anxiety_items, model = 1, itemtype = "graded")
#--------------

#--------------
# coefficients
coef(fit_GRM_mirt, IRTpars = TRUE, simplify = TRUE)
## $items
##         a     b1    b2    b3    b4
## R1  3.449  0.494 1.251 2.031 2.814
## R2  3.168  0.568 1.426 2.253 3.253
## ...
## R25 1.372 -0.762 0.154 1.377 2.592
## ...
#--------------

#--------------
mirt::itemplot(fit_GRM_mirt, item = 1, type = "infotrace")
#--------------

#--------------
mirt::itemplot(fit_GRM_mirt, item = 25, type = "infotrace")
#--------------

#--------------
# test score curve
plot(fit_GRM_mirt)
# test score curve with 95% CI
# plot(fit_GRM_mirt, MI = 200)

# TIC
plot(fit_GRM_mirt, type = "info") # test information
plot(fit_GRM_mirt, type = "infoSE") # test information and SE
#--------------

#--------------
# Factor scores vs standardized total scores
fs <- as.vector(fscores(fit_GRM_mirt))
sts <- as.vector(scale(rowSums(Anxiety[, paste0("R", 1:29)])))
plot(fs ~ sts)
#--------------

#--------------
# GRM in the ltm package
fit_GRM_ltm <- ltm::grm(Anxiety_items)

# coefficients
coef(fit_GRM_ltm)
##     Extrmt1 Extrmt2 Extrmt3 Extrmt4 Dscrmn
## R1    0.560   1.461   2.366   3.325  2.773
## R2    0.657   1.667   2.604   3.741  2.605
## ...
## R25  -0.918   0.150   1.612   3.056  1.153
## ...
#--------------

#--------------
fs_GRM_mirt <- unique(sort(as.vector(mirt::fscores(fit_GRM_mirt))))
fs_GRM_ltm <- ltm::factor.scores(fit_GRM_ltm)$score.dat[, "z1"]

cor(fs_GRM_mirt, fs_GRM_ltm)
## [1] 0.9066

df <- data.frame(fs_GRM_mirt, fs_GRM_ltm)
ggplot(data = df, aes(x = fs_GRM_mirt, y = fs_GRM_ltm)) +
  geom_point() +
  theme_fig() +
  xlab("Factor scores by mirt") + ylab("Factor scores by ltm") + 
  geom_smooth(method = "lm", se = FALSE)
#--------------

#-----------------------------------------------------------------
# 7.4.2  Graded rating scale model
#-----------------------------------------------------------------

#--------------
# GRSM with the IRT parametrization
fit_GRSMirt_mirt <- mirt::mirt(Anxiety_items, model = 1, 
                               itemtype = "grsmIRT")
# coefficients
coef(fit_GRSMirt_mirt, simplify = TRUE)
##  $items
##        a1     b1     b2     b3     b4      c
## R1  3.200 -0.454 -1.256 -2.214 -3.202  0.000
## R2  3.109 -0.454 -1.256 -2.214 -3.202 -0.110
## ...
## R25 1.613 -0.454 -1.256 -2.214 -3.202  1.081
## ...
#--------------

#--------------
anova(fit_GRSMirt_mirt, fit_GRM_mirt)
##        AIC     AICc    SABIC       HQ      BIC    logLik
## 1 35268.78 35279.52 35358.19 35377.76 35551.89 -17573.39
## 2 35130.82 35199.11 35343.35 35389.87 35803.79 -17420.41
##        X2  df   p
## 1     NaN NaN NaN
## 2 305.959  84   0
#--------------

#-----------------------------------------------------------------
# 7.4.3  Generalized partial credit model
#-----------------------------------------------------------------

#--------------
fit_GPCM_mirt <- mirt(Anxiety_items, model = 1, 
                      itemtype = "gpcm")
# coefficients
coef(fit_GPCM_mirt, IRTpars = TRUE, simplify = TRUE)
## $items
##         a     b1     b2    b3    b4
## R1  2.935  0.614  1.204 1.859 2.439
## R2  2.823  0.680  1.355 2.012 2.829
## ...
## R25 0.741  0.013 -0.182 1.468 2.119
## ...
#--------------

#--------------
mirt::itemplot(fit_GPCM_mirt, item = 1, type = "infotrace")
#--------------

#--------------
mirt::itemplot(fit_GPCM_mirt, item = 25, type = "infotrace")
#--------------

#-----------------------------------------------------------------
# 7.4.4  Partial credit model
#-----------------------------------------------------------------

#--------------
model_PCM <- "F = 1-29
FIXED = (1-29, a1),
START = (1-29, a1, 1)"
fit_PCM_mirt <- mirt::mirt(Anxiety_items, model = model_PCM, 
                           itemtype = "gpcm")
# coefficients
coef(fit_PCM_mirt, IRTpars = TRUE, simplify = TRUE)
## $items
##     a     b1     b2    b3    b4
## R1  1  1.305  1.948 3.184 4.106
## R2  1  1.390  2.243 3.434 4.814
## ...
## R25 1 -0.462 -0.106 1.639 2.670
## ...
#--------------

#--------------
anova(fit_PCM_mirt, fit_GPCM_mirt)
##        AIC     AICc    SABIC       HQ      BIC    logLik
## 1 36632.50 36674.32 36802.53 36839.74 37170.88 -18200.25
## 2 35326.84 35395.13 35539.37 35585.89 35999.81 -17518.42
##         X2  df   p
## 1      NaN NaN NaN
## 2 1363.662  29   0
#--------------

#-----------------------------------------------------------------
# 7.4.5  Rating scale model
#-----------------------------------------------------------------

#--------------
fit_RSM_mirt <- mirt::mirt(Anxiety_items, model = 1, itemtype = "rsm")

# coefficients
coef(fit_RSM_mirt, IRTpars = TRUE, simplify = TRUE)
## $items
##     a1    b1   b2    b3    b4      c
## R1   1 1.347 2.09 3.797 5.101  0.000
## R2   1 1.347 2.09 3.797 5.101 -0.205
## ...
## R25  1 1.347 2.09 3.797 5.101  2.030
## ...
#--------------

#--------------
mirt::itemplot(fit_RSM_mirt, item = 1, type = "infotrace")
#--------------

#--------------
mirt::itemplot(fit_RSM_mirt, item = 25, type = "infotrace")
#--------------

#--------------
anova(fit_RSM_mirt, fit_GPCM_mirt)
##        AIC     AICc    SABIC       HQ      BIC    logLik
## 1 36446.99 36450.05 36495.36 36505.94 36600.15 -18190.49
## 2 35326.84 35395.13 35539.37 35585.89 35999.81 -17518.42
##
## X2  df   p
## 1      NaN NaN NaN
## 2 1344.149 112   0
#--------------

#-----------------------------------------------------------------
# 7.4.6  Nominal response model
#-----------------------------------------------------------------

#--------------
HCI.numeric <- HCItest[, 1:20]
HCI.numeric[] <- sapply(HCI.numeric, as.numeric)

fit_NRM_mirt <- mirt::mirt(HCI.numeric, model = 1, 
                           itemtype = "nominal")
# coefficients in default model parametrization as in Thissen et al. (2010)
coef(fit_NRM_mirt, simplify = TRUE)
##             a1 ak0     ak1     ak2     ak3 d0     d1     d2     d3 ak4     d4
## Item 1   0.449   0   2.158   0.591   3.000  0  1.261  1.608  3.282  NA     NA
## Item 2   0.282   0   3.376   2.000      NA  0  1.886 -0.143     NA  NA     NA
## ...
## Item 19  0.086   0  -2.096  17.969   3.758  0 -0.104  3.081 -0.059   4 -0.227
## Item 20  0.473   0  -0.607   1.369   3.000  0  0.983  3.024  4.356  NA     NA
#--------------

#--------------
# coefficients in (intercept-slope) model parametrization as proposed by Bock (1972)
coef(fit_NRM_mirt, IRTpars = TRUE, simplify = TRUE)
##             a1     a2     a3     a4     c1     c2     c3     c4     a5     c5
## Item 1  -0.645  0.323 -0.379  0.701 -1.538 -0.277  0.070  1.744     NA     NA
## Item 2  -0.505  0.447  0.059     NA -0.581  1.305 -0.724     NA     NA     NA
## ...
## Item 19 -0.407 -0.587  1.139 -0.083 -0.538 -0.642  2.542 -0.597 -0.062 -0.766
## Item 20 -0.445 -0.732  0.203  0.974 -2.091 -1.108  0.934  2.265     NA     NA
#--------------

#--------------
# item characteristic curve for item 1
mirt::itemplot(fit_NRM_mirt, item = 1, type = "infotrace")
# item information curves
plot(fit_NRM_mirt, type = "infotrace", facet_items = FALSE)
# test information curve
plot(fit_NRM_mirt, type = "infoSE")
# factor scores vs standardized total scores
fs <- as.vector(fscores(fit_NRM_mirt))
sts <- as.vector(scale(rowSums(HCI[, 1:20])))
plot(fs ~ sts, xlab = "Standardized total score", ylab = "Factor score")
cor(fs, sts)
#--------------