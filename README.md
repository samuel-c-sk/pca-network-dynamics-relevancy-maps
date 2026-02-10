# pca-network-dynamics-relevancy-maps

## Project overview

This project implements a **PCA-based network dynamics model** for clustering and relevance mapping of high-dimensional observational data.  
The workflow combines **statistical normalization, dimensionality reduction (PCA), nonlinear network dynamics, and relevance estimation**, resulting in spatial relevance maps for multiple clusters.

The project was developed in an **academic context** as part of coursework focused on data analysis, statistical modeling, and dynamical systems.

---

## Problem description

We are given two types of data:

1. **Learned (training) data**
   - Matrix size: **112 × 72**
   - Each row represents one learned observation
   - Each column represents a statistical feature
   - The data form **4 clusters** with sizes:
     - 22, 28, 31, and 31 samples

2. **New observations**
   - Matrix size: **3600 × 72**
   - Represent spatially distributed observations (60 × 60 grid)
   - Each row has the same type of statistical features as the learned data

Each column corresponds to a selected statistic (mean, standard deviation, min, max) computed for **18 optical channels**, giving:

4 statistics × 18 channels = 72 features

The goal is to:
- project both datasets into a common low-dimensional space,
- simulate network dynamics that move points toward cluster centers,
- assign new observations to clusters,
- compute **relevancy maps** for each cluster.

---

## Data availability

⚠️ **Important note on data availability**

The original input datasets used in this project are **not included in the repository**.

- The learned data and new observation statistics originate from an academic dataset.
- The data are subject to institutional and licensing restrictions.
- Therefore, they cannot be publicly redistributed.

All algorithms, processing steps, and workflows are fully included and documented, allowing the methodology to be inspected and reused with alternative datasets of the same structure.

---

## Data preprocessing

### Min–max normalization

Before applying PCA, each feature (column) is normalized independently using min–max scaling:

x_norm = (x - min) / (max - min)

- The minimum and maximum for each column are stored in `beforePCA`
- Special care is taken for constant columns (`max - min = 0`)

This ensures comparable feature scales and numerical stability.

---

## Principal Component Analysis (PCA)

PCA is applied to the normalized learned data:

- `coeff` — PCA transformation matrix
- `score` — transformed coordinates of learned points

After PCA:
- the transformed data are **normalized again** (stored in `afterPCA`)
- only the **first two principal components** are used in later stages

The learned data form clearly separated clusters in the PCA space.

---

## Projection of new observations

New observations are processed using the same transformations:

1. Min–max normalization using `beforePCA`
2. Centering
3. Projection using PCA coefficients (`coeff`)
4. Min–max normalization using `afterPCA`

This guarantees that new observations lie in the same normalized PCA space as the learned network.

---

## Network dynamics model

The learned points form a **dynamical network**, governed by a diffusion-like interaction rule.

### Diffusion coefficient

The interaction strength between two points depends on their distance in PCA space:

g(dx, dy) = 1 / (1 + K1·dx² + K2·dy²)

where:
- `dx`, `dy` are distances along the first two principal components
- `K1 = 3100`, `K2 = 1500`

Only the first two PCA components are used to control the dynamics.

---

### Time integration

- Time step: `τ = 1`
- Backward (negative) diffusion controlled by:
  - `ε = -0.01`
- The system evolves iteratively until a **stopping criterion** is met

The stopping criterion depends only on the learned network points and ensures convergence.

---

## Integration of new observations

New observations are gradually attached to the learned network:

- Diffusion coefficients are computed using the same parameters (`K1`, `K2`)
- If the interaction strength is below a threshold:

g < δ = 0.003

the interaction is set to zero

This prevents unrealistic long-range influences.

---

## Cluster assignment

After convergence:

- A new observation is assigned to a cluster if its distance to any learned point is:

distance < 0.05

- Otherwise, it is labeled as **unassigned**

---

## Relevancy maps

The final step computes **relevancy values** for each new observation:

- Parameter: `λ = 12`
- Unassigned points receive relevance `0`
- Each cluster produces one **60 × 60 relevance map**
- Total of **4 relevance maps**, one per cluster

### Interpretation note

The new observations originate from the **Danube river basin**, where habitats corresponding primarily to the **first cluster** are known to be present.  
Therefore, the relevance map associated with the first cluster is expected to contain the **largest number of non-zero relevance values**, which serves as an additional qualitative validation of the method.


---

## Notes on scope and focus

- The emphasis is on **algorithmic correctness and numerical behavior**
- Code structure and visualization are secondary
- The project prioritizes:
  - reproducibility of the workflow
  - clarity of the mathematical pipeline
  - interpretability of relevance maps

---

## Context

This project was developed in an **academic context** as part of coursework in data analysis and statistical modeling.  
It demonstrates the combination of **PCA, nonlinear network dynamics, and relevance estimation** for structured high-dimensional data.

The implementation is intended for educational and exploratory purposes rather than for production deployment.
