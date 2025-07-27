# LE_MEDIAN Variable Codebook (DUMMY METADATA IS MADE UP)

## Variable Definition

**LE_MEDIAN** represents the median life expectancy at birth for urban populations, measured in years. This indicator captures the middle value of life expectancy estimates when all births in a given geographic area and time period are ranked from lowest to highest expected lifespan.

### Technical Specifications

- **Variable Name**: `LE_MEDIAN`
- **Variable Label**: Life Expectancy Median
- **Value Type**: Numeric (continuous)
- **Units**: Years
- **Domain**: Health Outcomes
- **Subdomain**: Mortality and Life Expectancy
- **Temporal Resolution**: Daily estimates
- **Geographic Level**: Metropolitan Area (L1AD)

### Methodology

Life expectancy median is calculated using demographic life tables that incorporate age-specific mortality rates for the urban population. The median represents the age at which 50% of a birth cohort is expected to survive, providing a robust measure of population health that is less sensitive to extreme values than the mean.

### Data Quality Notes

- Values represent modeled estimates based on vital registration data
- Daily variations reflect updated mortality surveillance data
- Estimates are adjusted for urban-specific demographic patterns
- Missing or incomplete vital registration data may affect accuracy in some periods

## Data Sources by Country

### **🇧🇷 Brazil (BR)**
- **Population Data**: Brazilian Institute of Geography and Statistics (IBGE) - Demographic Census and Population Projections
- **Mortality Data**: Ministry of Health - Mortality Information System (SIM)

### **🇲🇽 Mexico (MX)**  
- **Population Data**: National Institute of Statistics and Geography (INEGI) - Population and Housing Census
- **Mortality Data**: Ministry of Health - General Directorate of Health Information (DGIS)

### **🇨🇴 Colombia (CO)**
- **Population Data**: National Administrative Department of Statistics (DANE) - National Population and Housing Census
- **Mortality Data**: Ministry of Health and Social Protection - National Public Health Surveillance System (SIVIGILA)

## Limitations

- **Temporal lag**: Official vital registration data may have 6-12 month reporting delays
- **Urban bias**: Estimates focus on metropolitan areas and may not represent rural populations
- **Data completeness**: Varies by country and time period based on civil registration coverage
- **Methodological differences**: Countries may use different life table construction methods
- **Migration effects**: Population mobility between urban areas may affect local estimates

## Public Access

**Public**: Yes (Level 1) - Aggregated metropolitan-level data suitable for public release