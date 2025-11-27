# Multivariate Wavelet Quantile Regression (MWQR)

## Overview
Multivariate Wavelet Quantile Regression (MWQR) is a time–frequency, quantile-based framework for analysing complex, nonlinear and asymmetric dependence among multiple time series. It combines MODWT-based wavelet decomposition with multivariate quantile regression, allowing relationships to be studied simultaneously:
- across quantiles (centre vs tails),
- across time scales (short, medium, long run bands),
- and across multiple variables (multivariate interactions with controls).

Compared with standard mean-based or purely bivariate methods, MWQR reveals heterogeneous linkages that are often hidden in aggregate, single-scale models.

---

## Key Features

- **Time–frequency resolution**  
  Uses MODWT wavelet decomposition to split each series into detail levels (e.g. D1–D6), which are aggregated into high-, medium-, and low-frequency bands.

- **Quantile-specific effects**  
  Estimates regression relationships at different quantiles, capturing behaviour in normal, boom, and stress states.

- **Multivariate structure**  
  Models several regressors jointly (main variable plus controls), mitigating omitted-variable bias and improving interpretation of partial effects.

- **Asymmetry and nonlinearity**  
  Naturally accommodates asymmetric impacts and nonlinear dependence that vary across both scales and quantiles.

- **R-based implementation**  
  Implemented in R using `waveslim` for MODWT and `quantreg` for quantile regression; the framework can be extended to other software.

---

## Methodological Sketch

1. **Pre-processing**
   - Load and clean the time series from an Excel file.
   - (Optional) Transform data (logs, differences, standardisation).

2. **Wavelet Decomposition**
   - Apply MODWT (e.g. `wf = "la8"`, `n.levels = 6`) to each series.
   - Extract detail coefficients D1–D6 and aggregate them into:
     - Short-run band (D1–D2),
     - Medium-run band (D3–D4),
     - Long-run band (D5–D6).

3. **Quantile Regression by Band**
   - For each band (Short, Medium, Long) and each target quantile τ:
     - Run a multivariate quantile regression of the response on the main regressor and control variables at that band.
   - Store estimated coefficients, bootstrapped standard errors, and p-values for each (band, τ) pair.

4. **Result Aggregation and Visualisation**
   - Build heatmaps of the main regressor’s coefficients across time bands and quantiles, overlaying significance stars.
   - Summarise patterns of sign, magnitude, and significance across scales and tails.
