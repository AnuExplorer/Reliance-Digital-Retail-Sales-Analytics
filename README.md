# Reliance-Digital-Retail-Sales-Analytics
End-to-end retail sales analytics project using MySQL to clean and validate raw laptop sales data, build relational tables, analyze sales and delivery performance, and develop actionable business insights.

# Reliance Digital — Retail Data Cleaning with MySQL

## Project Overview

This project focuses on importing, cleaning, standardizing, validating, and preparing retail laptop sales data for downstream analysis using MySQL.

The work involves handling a large dataset starting from 2 lakh + records to 3 lakh +   with inconsistent values, missing information, duplicate records, formatting issues, and data quality conflicts. The objective is to create more reliable, structured datasets while preserving the original source data.

**Currently completed :** SQL-based data cleaning, transformation, validation, and data handling.

## Technology Used

- MySQL
- SQL
- **`LOAD DATA LOCAL INFILE`** for data import
- SQL-based data profiling and validation
- MySQL table creation, modification, and data export

## Project Workflow

1. Import raw data into MySQL.
2. Profile data quality issues.
3. Create separate working and cleaned tables.
4. Standardize text, formats, and inconsistent values.
5. Investigate missing values and conflicting records.
6. Apply appropriate deduplication rules.
7. Validate cleaned tables and key fields.
8. Export selected results for inspection and further use.

## Data Quality Challenges

The project addresses issues including:

- Duplicate and potentially duplicate records
- Missing and inconsistent values
- Inconsistent text formatting
- Invalid or implausible delivery durations
- Date-format inconsistencies
- Conflicting customer, product, and store attributes
- Inconsistent product specifications and units

Cleaning rules are applied according to the type of issue rather than treating every missing or conflicting value in the same way.

## Data Integrity and Traceability

The original raw table is preserved. Cleaning operations are performed on derived tables to reduce the risk of unintended changes to source data.

Where applicable, source row identifiers are retained to support record traceability, investigation, and validation.

Validation includes row counts, duplicate checks, missing-value checks, distinct-value analysis, and checks on the expected grain of cleaned tables.

## SQL Work Showcase

This repository will contain selected examples of:

- Data profiling queries
- Text standardization and value normalization
- Duplicate detection and removal
- Date and delivery-duration handling
- Missing-value investigation
- Table-level validation
- Import and export workflows

Only selected SQL examples and limited, non-sensitive data samples will be published. The complete raw dataset is not included.

## Current Project Status

**Completed work**
- MySQL-based data import and export workflows
- Data profiling and issue investigation
- Cleaning and standardization of working tables
- Duplicate handling and validation of cleaned outputs

**Planned work**
- Finalize and document the relational data model
- Develop business KPI queries and analytical insights
- Build a dashboard using a selected visualization technology
- Add reproducible pipeline checks and project documentation

## Repository Structure

SQL scripts will be organized by workflow stage, with explanations of their purpose, execution order, and validation results.

## Data and Confidentiality

The complete raw dataset is intentionally excluded from this repository. Any examples published will be limited to data that is authorized for sharing and will avoid confidential or identifying information.

This repository documents the SQL workflow and technical approach; it does not imply endorsement or affiliation by Reliance Digital.

## Project Outcome

The goal is to establish a traceable and validated SQL data preparation workflow that can support reliable downstream retail analytics.
