# Learning Module 1: Simple Area-Level Dataset Renovation

## Dataset type: Area Level

Area-level datasets aggregate information across a geographic area, such as a city or subcity. They typically include summary statistics rather than individual-level data. It is one row per geographic area, strata, time, and variable.

## Difficulty Level: Simple

This is a **simple level** training example that demonstrates the basic renovation workflow. Simple as in meaning

**Simple level** means:
- **No Stratification**: No breakdown by population characteristics (age, sex, income, etc.)
- **Single Source**: 1:1 relationship between SALURBAL dataset and original data source
- **Minimal Harmonization**: Data comes from one source and requires minimal processing
- **Straightforward Structure**: Variables map directly without complex transformations

## This Example: Dummy Air Pollution Dataset

For this training example, we use a dummy air pollution dataset located on the **UHC server** that demonstrates the characteristics of simple level datasets:

- **Type**: Area-level (geographic aggregation)
- **Complexity**: Simple level (single source, no stratification)
- **Variables**: PM2.5, PM10, NO2, O3 daily measurements
- **Geography**: L1AD (Large cities), L2 (Intermediate cities)
- **Time**: Daily measurements across multiple years
- **Stratification**: None (no age, sex, or population breakdowns)
- **Data Source**: UHC server with three separate dummy data files

By completing this example, you will learn:

1. **Basic renovation workflow** for simple level datasets
2. **Understanding simple vs. medium vs. complex** dataset characteristics
3. **Handling datasets with 1:1 source relationships**
4. **Processing datasets with no population stratification**
5. **Variable name standardization** and sanitization
6. **Data pivoting** from wide to long format
7. **Quality control** and validation steps
 
### Folder Structure

```
code/renovations/_training/
├── README.md                              # Training overview guide
├── _training__1_area_level_simple/        # → Module 1: Simple Area-Level
│   ├── _training__1_area_level_simple.qmd # Main renovation notebook
│   └── ....                               # Other files 
└── _datawarehouse/                        # → Training Data Warehouse
    └── _source/                           # Final outputs for all modules
        ├── _training__1_area_level_simple_v1_schema-v2_data.parquet
        ├── _training__1_area_level_simple_v1_schema-v2_metadata.parquet
        └── _training__1_area_level_simple_v1_schema-v2_loading.json
```

### Sample Data Structure

Dummy data is stored ont he UHC server in similiar format to regular SALURBLA datasets.

#### 1. Large Cities Data (dummy_L1AD_daily_sample.csv)
| ISO2 | SALID1 | L1_NAME | YEAR | MONTH | DAY | PM25_MEAN | PM10_MEAN | NO2_MEAN | O3_MEAN | geo |
|------|--------|---------|------|-------|-----|-----------|-----------|----------|---------|-----|
| BR | BR001 | São Paulo Metropolitan Area | 2019 | 1 | 1 | 15.2 | 25.8 | 32.1 | 45.3 | L1AD |
| BR | BR001 | São Paulo Metropolitan Area | 2019 | 1 | 2 | 14.8 | 24.9 | 30.7 | 47.1 | L1AD |
| MX | MX001 | Mexico City Metropolitan Area | 2019 | 1 | 1 | 22.3 | 35.6 | 28.9 | 38.7 | L1AD |

#### 2. Brazilian Sub Cities Data (dummy_L2_BR_daily_sample.csv)
| ISO2 | SALID1 | L1_NAME | SALID2 | L2_NAME | YEAR | MONTH | DAY | PM25_MEAN | PM10_MEAN | NO2_MEAN | O3_MEAN | geo |
|------|--------|---------|--------|---------|------|-------|-----|-----------|-----------|----------|---------|-----|
| BR | BR001 | São Paulo Metropolitan Area | BR004 | Sorocaba | 2019 | 1 | 1 | 10.8 | 17.5 | 24.2 | 52.8 | L2 |
| BR | BR001 | São Paulo Metropolitan Area | BR005 | Ribeirão Preto | 2019 | 1 | 1 | 9.8 | 16.3 | 22.1 | 54.7 | L2 |

#### 3. Mexican Sub Cities Data (dummy_L2_MX_daily_sample.csv)
| ISO2 | SALID1 | L1_NAME | SALID2 | L2_NAME | YEAR | MONTH | DAY | PM25_MEAN | PM10_MEAN | NO2_MEAN | O3_MEAN | geo |
|------|--------|---------|--------|---------|------|-------|-----|-----------|-----------|----------|---------|-----|
| MX | MX001 | Mexico City Metropolitan Area | MX004 | Puebla | 2019 | 1 | 1 | 19.5 | 31.2 | 26.8 | 39.6 | L2 |
| MX | MX001 | Mexico City Metropolitan Area | MX005 | Toluca | 2019 | 1 | 1 | 17.2 | 27.8 | 23.9 | 42.3 | L2 |

