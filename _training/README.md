# Cube Building Training Modules

## Introduction

Welcome to the training folder! This is a safe space with example datasets designed to help you learn the cube building process. You can practice here without affecting any real project data, making it the perfect place to get comfortable with the workflow and tools.

**CubeBuilder** is a data harmonization framework that transforms raw research data into unified data/metadata cubes. As part of the data team, you integrate data and metadata at the data point level, creating cubes where every data point contains both its value and complete contextual information.

The goal is to standardize both data and metadata, then integrate them at the data point level across many datasets to create a centralized, easily accessible cube. This involves:
- Taking messy research data from various sources (Excel files, surveys, administrative records)
- Standardizing both the data structure and metadata documentation
- Integrating data and metadata at the data point level into cubes where each data point includes its value and complete context
- Loading integrated cubes into our data warehouse so analysts can query data and metadata together seamlessly


**Your learning path:**
1. First, read through this getting started guide to understand the cube building process
2. Then proceed to do a few training exercises in the folders 


## Overview of the Cube Building Process

Each dataset goes through a standardized **cube building notebook** with two main sections:

## Section 1: Data Standardization
This is the technical foundation work that sets up the data structure:

### 1.1 Setup & Configuration
- Initialize the processing context and load global configurations
- Set up file paths and data connections

### 1.2 Variable Name Standardization
- Clean and standardize variable names from the raw data
- Create a `df_var_name` table mapping raw variable names to standardized names
- Assign basic domain/subdomain classifications

### 1.3 Strata Definition
- Identify and standardize stratification variables (like age, sex, population groups)
- Create a `df_strata` table defining how data is broken down by subgroups
- Map raw strata values to human-readable labels (e.g., "1" → "Male", "0" → "Female")

### 1.4 Data Cube Processing
- Transform raw data into standardized format with proper composite keys
- Reshape data (often pivot from wide to long format)
- Add standardized identifiers (iso2, observation_id, year, etc.)
- Validate data structure and cache for efficient processing

## Section 2: Metadata Standardization
This is where you document and validate the standardized data:

### 2.1 Setup Metadata Template
- Process the `linkage.csv` file, which defines how metadata connects to different combinations of keys (like country, year, geography level)
- Generate empty codebook templates based on the standardized variables and strata
- Create the `4.1-raw__codebook.xlsx` file for metadata documentation
- Set up the metadata structure for the entire dataset

### Key Files You'll Work With
- **`4.1-raw__codebook.xlsx`** - Your main workspace for metadata entry
- **`4.3-int__codebook.xlsx`** - The reviewed version after management approval
- **Linkage files** - Help map variables to the right metadata structure
- **Templating data** - Reusable content blocks (sources, definitions) that get inserted automatically

### 2.2 Raw Metadata Entry
**Your main work:** Mine and document metadata
- Fill out the `4.1-raw__codebook.xlsx` file with variable definitions, sources, and documentation
- Extract information from original Excel sheets, PDFs, and documentation provided by researchers
- Complete variable labels, descriptions, coding schemes, and domain classifications

**Key tasks:**
- Review original data documentation
- Fill in variable definitions (`var_def`)
- Assign domain/subdomain categories 
- Document data sources and acknowledgments
- Add templating keys like `{{health-survey-adult}}` for dynamic content


**The packages work:** Your work gets validated
- The system runs automated checks on your raw codebook
- Structural validation ensures everything follows our standards
- Intermediate codebooks are generated for management review
- Any errors or missing information is flagged

**Your role:** Fix any validation errors and ensure completeness

### 2.3 Management Review & Final Processing
**What happens:** DMC (Data Management Committee) reviews your work
- Review the intermediate codebooks for quality and completeness
- Ingest any new templating data if needed
- Render templates with dynamic content (sources, acknowledgments, etc.)
- Run final validation

**Your role:** Address any feedback from the review process

## Section 3: Data Warehouse Loading
**Final integration and deployment:**
- Test data and metadata together
- Run integrated validation to ensure everything works as expected
- Load final datasets into the data warehouse
 

## Key Files You'll Work With

- **`4.1-raw__codebook.xlsx`** - Your main workspace for metadata entry
- **`4.3-int__codebook.xlsx`** - The reviewed version after management approval
- **Linkage files** - Help map variables to the right metadata structure
- **Templating data** - Reusable content blocks (sources, definitions) that get inserted automatically