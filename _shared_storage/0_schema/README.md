# Seeds

These items are prior to ETL and serve as the single point of truth for project metadata. Below are descriptions of each item item and where they are consumed downstream.


- **df_domains**: This is a single source of truth for all valid domains in SALURBAL. 
  - It is utilized during codebook QC to check that codebooks have valid domains
- **df_subdomains**: This is a single source of truth for all valid subdomains in SALURBAL. 
  - It is utilized during codebook QC to check that codebooks have valid subdomains
- **/spatial**: This folder contains all boundaries and centroids. 