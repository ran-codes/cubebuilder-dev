# CubeBuilder-Dev: A Project-Agnostic Data Harmonization Framework

[![Development Status](https://img.shields.io/badge/status-development-yellow.svg)](https://github.com/your-org/cubebuilder-dev)
[![Framework](https://img.shields.io/badge/framework-R-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

CubeBuilder-Dev is a development repository for building data harmonization and cube-building capabilities. This repository focuses on creating unified data structures that integrate both data and metadata into queryable cubes for efficient reporting and analysis.

## 🎯 What is a Data/Metadata Cube?

A **data/metadata cube** is a unified data structure that combines raw data with its descriptive metadata into a single, queryable format. This approach enables:

### 🔄 **Join-Free Queries**
- **No complex joins required**: Data and metadata are pre-integrated
- **Single query access**: Retrieve both values and their context simultaneously
- **Simplified analysis**: Users don't need to understand complex table relationships

### 📊 **Efficient Reporting** 
- **Self-documenting datasets**: Every data point includes its full context
- **Automated metadata access**: Variable definitions, units, sources available with data
- **Consistent structure**: Standardized format across all datasets and domains

### 🎯 **Harmonized Data Assets**
- **Multi-source integration**: Combine data from different systems and formats
- **Standardized variables**: Common naming and structure across datasets  
- **Quality assurance**: Built-in validation and provenance tracking
- **Machine-actionable**: Ready for automated processing and distribution

The cube structure eliminates the complexity of managing relationships between data and metadata tables, making harmonized datasets immediately accessible for analysis, reporting, and automated processing.

## 📁 Repository Structure

Note that for this training most of storage is on GitHub/local but this workflow is designed so that storage can be on shared drives, encrypted drives or the cloud. Its just changing the path in the configurations.

```
cubebuilder-dev/
├── `_training/`                        # 🎓 Self-contained learning modules
│   ├── 1_area_level_simple/           # → Basic area-level data cube creation
│   ├── 2_record_level_simple/         # → Individual-level data processing  
├── `_shared_storage/`                    # 💾 Shared data storage layer
│   ├── 1_unstandardized/              # → Raw dummy datasets for training 
│   ├── 2_freeze/                      # → Immutable data snapshots  
│   ├── 3_cache_temp/                  # → Interemdiate cache folders
│   ├── 4_standardized/                # → Standardized data and metadata cubes
│   └── 5_datawarehouse/               # → Datawrehouse that orchestrates across cubes
├── R/                                  # 🔧 Core framework functions
│   ├── setup/                         # → Global configuration and setup
│   ├── renovation_functions/          # → Data processing pipeline
│   ├── validation/                    # → Quality control and testing
│   └── metadata/                      # → Metadata management utilities
└── README.md                          # 📖 This file
```

## 🚀 Quick Start: Training Modules

### Prerequisites
- **R 4.0+** with packages: `tidyverse`, `arrow`, `here`
- **RStudio** (recommended for .qmd notebook execution)
- **GitHub Desktop** for evaluating code diffs
- Access to shared storage (local or cloud)

### Training Path

#### 1️⃣ **Module 1: Simple Area-Level Data** (`_training/1_area_level_simple/`) ✅ **SOLVED**
**Learn**: Basic cube creation, variable standardization, metadata templates
- **Dataset**: Dummy air pollution measurements (PM2.5, NO2, etc.)
- **Complexity**: Single source, no stratification, dataset-level metadata
- **Output**: Area-aggregated environmental data cube
- **Status**: Complete example for reference and code rerunning

#### 2️⃣ **Module 2: Simple Record-Level Data** (`_training/2_record_level_simple/`) ✅ **SOLVED**
**Learn**: Individual-level processing, observation IDs, record-to-cube transformation
- **Dataset**: Dummy health survey responses
- **Complexity**: Individual records, basic demographics, dataset-level metadata
- **Output**: Person-level health data cube
- **Status**: Complete example for reference and code rerunning

#### 3️⃣ **Module 3: Medium Area-Level Data** (`_training/3_area_level_medium/`) 🎯 **READY TO SOLVE**
**Learn**: Country-specific metadata, geographic variation in sources, medium complexity cube building
- **Dataset**: Dummy life expectancy data (LE_MEDIAN)
- **Complexity**: Single variable with **metadata varying by country** (sources, acknowledgements)
- **Output**: Life expectancy cube with country-specific metadata integration
- **Status**: Set up and ready for hands-on learning - solve this module to master medium complexity patterns


---

*Incoming*

- *[Harmonized data sources jinja templating](https://salurbal-infrastructure.netlify.app/Data/templating/)*
- *Edge cases*
