# Seeds

These items are generated during the last phase of ETL -  Loading. Below are descriptions of each item item and where they are consumed downstream. 

## Active

- **df_domains**: This is a single source of truth for all valid domains in SALURBAL. 
  - It is utilized during codebook QC to check that codebooks have valid domains
- **df_subdomains**: This is a single source of truth for all valid subdomains in SALURBAL. 
  - It is utilized during codebook QC to check that codebooks have valid subdomains


## Archive

- **df_primary_metadata.RDS** This is a compiled metadata source consumed during compile_derived_public() and the deprecated function compile_derived_metadata(). Note that compilation by variable origin may not be actively developed due to lack of accurate lineage metadata; in these cases, compile by source is the easier and more accurate approach.
