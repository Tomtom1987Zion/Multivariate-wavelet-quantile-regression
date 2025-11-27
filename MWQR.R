## multivariate wavelet quantile regression (MWQR) method
# Link: https://doi.org/10.1080/00036846.2025.2590632
# Authors: Adebayo, T. S., Abbas, S., Olanrewaju, V. O., & Uzun, B. (2025)
# Code By: Adebayo, T. S.,
# Title: Unpacking policy ambiguities in residential and commercial renewable energy adoption: A novel multivariate wavelet quantile regression analysis
# Journal: Applied Economics.

## ── Setup ────────────────────────────────────────────────────────────────────
rm(list=ls(all=TRUE))
library(readxl)      # for read_excel  
library(waveslim)    # for modwt
library(quantreg)    # for rq()
library(lattice)     # for levelplot
library(parallel)    # for detectCores
options(warn = -1)
options(mc.cores = detectCores())


## setwd("C:/Users/Admin/Adebayo/Collaboration/FINANCE-ENERGY PAPERS/Multivariate Wavelet Quantile Regression")

## ── Load & attach your data ─────────────────────────────────────────────────
Data <- read_excel("DATA.xlsx")
attach(Data)

## ── 1) Define variables & quantiles ─────────────────────────────────────────
Y  <- RREC    # Dependent variable
X  <- TPU     # Main independent variable
X2 <- MPU     # Control variable 1
X3 <- EPU     # Control variable 2
X4 <- CPU     # Control variable 3

tau <- c(0.01, 0.05, 0.10, 0.20, 0.30,
         0.40, 0.50, 0.60, 0.70, 0.80,
         0.90, 0.95, 0.99)

## ── 2) Apply MODWT to all variables ─────────────────────────────────────────
modwt_list <- list(
  Y  = modwt(Y,  wf = "la8", n.levels = 6, boundary = "periodic"),
  X  = modwt(X,  wf = "la8", n.levels = 6, boundary = "periodic"),
  X2 = modwt(X2, wf = "la8", n.levels = 6, boundary = "periodic"),
  X3 = modwt(X3, wf = "la8", n.levels = 6, boundary = "periodic"),
  X4 = modwt(X4, wf = "la8", n.levels = 6, boundary = "periodic")
)

# extract the first six detail levels (D1–D6) from each list
coeffs <- lapply(modwt_list, function(m) as.data.frame(m[1:6]))

aggregate_band <- function(df, idx) {
  rowSums(df[, idx, drop = FALSE])
}

bands <- list(
  Short  = 1:2,
  Medium = 3:4,
  Long   = 5:6
)

wave_data <- lapply(bands, function(idx) {
  data.frame(
    y  = aggregate_band(coeffs$Y,  idx),
    x  = aggregate_band(coeffs$X,  idx),
    x2 = aggregate_band(coeffs$X2, idx),
    x3 = aggregate_band(coeffs$X3, idx),
    x4 = aggregate_band(coeffs$X4, idx)
  )
})

## ── 3) Quantile regression + bootstrapped SEs ───────────────────────────────
get_qr_stats <- function(dat, taus, Rboot = 500) {
  out <- t(sapply(taus, function(t) {
    fit  <- rq(y ~ x + x2 + x3 + x4, data = dat, tau = t)
    summ <- summary(fit, se = "boot", R = Rboot)
    beta <- summ$coefficients["x", "Value"]
    se   <- summ$coefficients["x", "Std. Error"]
    pval <- 2 * pnorm(-abs(beta / se))
    c(beta = beta, pval = pval)
  }))
  as.data.frame(out)
}

res_list <- lapply(wave_data, get_qr_stats, taus = tau, Rboot = 500)

result_df <- data.frame(
  Quantile = tau,
  Short    = res_list$Short$beta,
  Medium   = res_list$Medium$beta,
  Long     = res_list$Long$beta,
  pS       = res_list$Short$pval,
  pM       = res_list$Medium$pval,
  pL       = res_list$Long$pval
)

## ── 4) Prepare matrices for plotting ────────────────────────────────────────
beta_mat <- as.matrix(result_df[, c("Short", "Medium", "Long")])
rownames(beta_mat) <- sprintf("%.2f", result_df$Quantile)
colnames(beta_mat) <- c("Short", "Medium", "Long")

sig_mat <- matrix("", nrow = nrow(beta_mat), ncol = ncol(beta_mat),
                  dimnames = dimnames(beta_mat))
for (i in seq_len(nrow(beta_mat))) {
  for (j in seq_len(ncol(beta_mat))) {
    pval <- result_df[i, c("pS","pM","pL")[j]]
    if (pval < 0.05)      sig_mat[i,j] <- "**"
    else if (pval < 0.10) sig_mat[i,j] <- "*"
  }
}

## ── 5) Plot heatmap ────────────────────────────────────────────────────────
palette <- colorRampPalette(c("darkseagreen1", "orange", "red"))(20)


levelplot(beta_mat,
          col.regions = palette,
          panel = function(...) {
            panel.levelplot(...)
            for (i in 1:nrow(beta_mat)) {
              for (j in 1:ncol(beta_mat)) {
                if (sig_mat[i,j] != "") {
                  panel.text(i, j, sig_mat[i,j], cex = 1.5)
                }
              }
            }
          },
          xlab = "Quantiles",
          ylab = "Time Horizons",
          main = ""
)

