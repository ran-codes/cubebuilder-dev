# CubeBuilder-Dev: A Project-Agnostic Data Harmonization Framework

[![Development Status](https://img.shields.io/badge/status-development-yellow.svg)](https://github.com/your-org/cubebuilder-dev)
[![Framework](https://img.shields.io/badge/framework-R-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

CubeBuilder-Dev is a development repository for building data harmonization and cube-building capabilities. This repository focuses on creating unified data structures that integrate both data and metadata into queryable cubes for efficient reporting and analysis.

## 🚀 Quick Start: Training Modules

1. Clone this repository
2. Read the root README for context on what a cube is
3. Read the `_training/README` for context on training
4. Navigate into the individual training modules
   - Read Module README for context on the goal of the training module
   - Run code if already available (e.g. Module 1 and 2)
   - Write code if an exercise (e.g. Module 3)
   - Check against solutions see branches 

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


---

*Incoming*

- *[Harmonized data sources jinja templating](https://salurbal-infrastructure.netlify.app/Data/templating/)*
- *Edge cases*
