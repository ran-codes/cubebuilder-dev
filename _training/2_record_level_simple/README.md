# Learning Module 2: Simple Record-Level Dataset Renovation

## Dataset type: Record Level

Record-level datasets contain individual observations (people, households, visits, transactions). Each row represents a unique individual or event with multiple variables capturing detailed information. It is one row per observation, strata, time, and variable.

## Difficulty Level: Simple

This is a **simple level** training example that demonstrates the basic renovation workflow for individual-level data.

**Simple level** means:
- **Minimal Stratification**: No complex population breakdown beyond basic demographics (sex only)
- **Single Source**: 1:1 relationship between SALURBAL dataset and original data source
- **Minimal Harmonization**: Data comes from one source and requires minimal processing
- **Straightforward Structure**: Variables map directly without complex transformations

## This Example: Dummy Health Survey Dataset

For this training example, we use a dummy health survey dataset located on the **UHC server** that demonstrates the characteristics of simple record level datasets:

- **Type**: Record-level (individual survey responses)
- **Complexity**: Simple level (single source, minimal stratification)
- **Variables**: Basic demographics, health behaviors, and outcomes
- **Geography**: Urban areas in 2-3 Latin American countries
- **Time**: Single wave survey (cross-sectional, 2019)
- **Stratification**: Basic (sex only)
- **Data Source**: UHC server with simulated survey data

By completing this example, you will learn:

1. **Basic renovation workflow** for record-level datasets
2. **Observation ID management** and unique identifier creation
3. **Basic stratification** (sex) for individual-level data
4. **Variable name standardization** for survey data
5. **Data cube creation** from individual records
6. **Geographic linkage** between records and SALURBAL geography
7. **Quality control** specific to record-level data

### Folder Structure

```
code/renovations/_training/
├── README.md                              # Training overview guide
├── _training__2_record_level_simple/      # → Module 2: Simple Record-Level
│   ├── _training__2_record_level_simple.qmd # Main renovation notebook
│   └── ....                               # Other files 
└── _datawarehouse/                        # → Training Data Warehouse
    └── _source/                           # Final outputs for all modules
        ├── _training__2_record_level_simple_v1_schema-v2_data.parquet
        ├── _training__2_record_level_simple_v1_schema-v2_metadata.parquet
        └── _training__2_record_level_simple_v1_schema-v2_loading.json
```

### Sample Data Structure

Dummy data is stored on the UHC server in similar format to regular SALURBAL datasets.

#### File 1: MX_health_survey_2019.csv (24 records, including 4 repeat visits)
| RESPONDENT_ID | SALID1 | SALID2 | SURVEY_YEAR | SURVEY_MONTH | SURVEY_DAY | AGE | SEX | EDUCATION | BMI | SMOKING | HEALTH_STATUS |
|---------------|---------|---------|-------------|--------------|------------|-----|-----|-----------|-----|---------|---------------|
| MX2019001 | 23 | 245 | 2019 | 3 | 15 | 34 | 1 | 3 | 24.5 | 0 | 2 |
| MX2019002 | 23 | 245 | 2019 | 3 | 18 | 28 | 0 | 2 | 22.1 | 1 | 1 |
| MX2019003 | 23 | 245 | 2019 | 3 | 22 | 45 | 1 | 4 | 27.8 | 0 | 3 |
| MX2019004 | 23 | 245 | 2019 | 4 | 5 | 52 | 0 | 2 | 29.3 | 0 | 2 |
| MX2019005 | 23 | 245 | 2019 | 4 | 12 | 29 | 1 | 3 | 26.1 | 1 | 1 |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
| MX2019001 | 23 | 245 | 2019 | 9 | 15 | 34 | 1 | 3 | 24.2 | 0 | 2 |
| MX2019005 | 23 | 245 | 2019 | 10 | 12 | 29 | 1 | 3 | 25.8 | 0 | 1 |

#### File 2: MX_health_survey_2015.csv (24 records, including 4 repeat visits)
| RESPONDENT_ID | SALID1 | SALID2 | SURVEY_YEAR | SURVEY_MONTH | SURVEY_DAY | AGE | SEX | EDUCATION | BMI | SMOKING | HEALTH_STATUS |
|---------------|---------|---------|-------------|--------------|------------|-----|-----|-----------|-----|---------|---------------|
| MX2015001 | 23 | 245 | 2015 | 2 | 10 | 30 | 1 | 2 | 23.8 | 1 | 2 |
| MX2015002 | 23 | 245 | 2015 | 2 | 15 | 25 | 0 | 1 | 21.5 | 0 | 1 |
| MX2015003 | 23 | 245 | 2015 | 2 | 22 | 42 | 1 | 3 | 26.9 | 0 | 3 |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
| MX2015003 | 23 | 245 | 2015 | 10 | 5 | 42 | 1 | 3 | 26.5 | 0 | 2 |
| MX2015007 | 11 | 170 | 2015 | 10 | 18 | 38 | 1 | 2 | 24.6 | 1 | 2 |

**Key Variables:**
- `RESPONDENT_ID`: Unique survey respondent identifier (some appear multiple times)
- `SALID1/SALID2`: SALURBAL geographic identifiers (cities/sub-cities)
- `SURVEY_YEAR/MONTH/DAY`: Exact survey completion date
- `SEX`: 0=Female, 1=Male (stratification variable)
- `AGE`: Age in years
- `EDUCATION`: Education level (1=Primary, 2=Secondary, 3=Higher, 4=University)
- `BMI`: Body Mass Index
- `SMOKING`: 0=Non-smoker, 1=Current smoker
- `HEALTH_STATUS`: Self-reported health (1=Excellent, 2=Good, 3=Fair, 4=Poor)
- `PHYSICAL_ACTIVITY`: 0=Inactive, 1=Active
- `INCOME_LEVEL`: 1=Low, 2=Middle, 3=High

**Record-Level Challenges in This Data:**
- **Multiple visits**: Some respondents have follow-up surveys (MX2019001, MX2019005, etc.)
- **Temporal data**: Survey dates span February-November in each year
- **Health changes**: BMI and behaviors may change between visits
- **Geographic distribution**: 3 metropolitan areas (SALID1: 4, 11, 23) with sub-cities