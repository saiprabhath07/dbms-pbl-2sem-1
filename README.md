# E-commerce Database Design & Normalization

**DBMS Micro Project | MySQL 8.4.11**

An academic DBMS micro project demonstrating the normalization of an e-commerce database from **Unnormalized Form (UNF) through First, Second, and Third Normal Forms (1NF, 2NF, 3NF) to Boyce–Codd Normal Form (BCNF)**.

The project focuses on relational database design, functional dependencies, candidate keys, and the mathematical justification of normalization.

## Project Information

| Detail | Information |
|---|---|
| Institution | Geethanjali College of Engineering and Technology |
| Curriculum | AR25 |
| Department / Branch | CSE — Artificial Intelligence and Machine Learning |
| Academic Year | Second Year |
| Subject | Database Management Systems (DBMS) |
| Database | `ecommerce_pbl` |
| DBMS | MySQL 8.4.11 |
| Project Type | Micro Project |

## Team Members

| Roll Number | Name |
|---|---|
| 26R15A66 03 | G. Angel |
| 26R15A66 04 | K. Akshaya |
| 26R15A66 05 | P. Shanmuka Sai Prabhath |
| 26R15A66 06 | R. Malavika |
| 26R15A66 07 | V. Chaithanya |

**Project Guide:** Dr. K. Arpitha Sreenivasulu

## Objectives

- Design an e-commerce database using relational database concepts.
- Begin with an intentionally unnormalized relation containing repeating groups.
- Demonstrate the progression from UNF to BCNF.
- Identify functional dependencies and candidate keys.
- Justify each decomposition using the relevant normalization rules.
- Investigate lossless joins and dependency preservation.
- Verify the resulting database using SQL scripts and test data.
- Document cases where a relation already satisfies a higher normal form without unnecessary decomposition.

## Project Overview

The project uses an initial relation named `Order_UNF` to represent e-commerce order information.

The original dataset contains JSON-based repeating groups representing:

- Order items
- Payments
- Return details

The database is then examined through successive normalization stages. Each stage is intended to address specific structural problems while preserving the information represented by the original dataset.

The objective is **to demonstrate correct normalization, not to build a complete commercial e-commerce application**.

## Normalization Stages

| Stage | Description |
|---|---|
| UNF | Initial relation containing repeating groups. |
| 1NF | Examine and remove repeating groups to establish atomic relational values. |
| 2NF | Identify and eliminate partial functional dependencies where applicable. |
| 3NF | Identify and eliminate transitive dependencies where applicable. |
| BCNF | Verify whether every determinant of a non-trivial functional dependency is a superkey. |

Every decomposition must be justified by the functional dependencies and candidate keys of the relation being examined.

If a relation already satisfies BCNF, the project will document that result rather than introduce unnecessary tables.

## Repository Structure

The repository contains the following SQL scripts:

| File | Purpose |
|---|---|
| `unf.sql` | Defines the original `Order_UNF` dataset, including JSON repeating groups and two sample orders. |
| `ecommerce-1nf.sql` | Contains the SQL implementation for the 1NF stage. |
| `ecommerce-2nf.sql` | Contains the SQL implementation for the 2NF stage. |
| `ecommerce-3nf.sql` | Contains the SQL implementation for the 3NF stage. |
| `ecommerce-bcnf.sql` | Contains the SQL implementation and/or verification for the BCNF stage. |
| `ecommerce-fd-analysis.sql` | Examines functional dependencies and related database properties. |
| `ecommerce-check.sql` | Contains database verification and consistency checks. |
| `ecommerce-normalization-report.sql` | Contains SQL-based documentation or reporting related to normalization. |

*The descriptions identify the intended roles of the files; their exact contents and successful execution must be verified against the current scripts.*

## Technical Requirements

- MySQL 8.4.11
- A MySQL client, such as the `mysql` command-line client
- Access to the project's SQL files

## Setup and Execution

### 1. Open MySQL

Connect to your MySQL server:

```bash
mysql -u root -p
```

Enter your MySQL password when prompted.

### 2. Create the database

```sql
CREATE DATABASE IF NOT EXISTS ecommerce_pbl;
USE ecommerce_pbl;
```

### 3. Execute the scripts

From the directory containing the SQL files, execute the scripts individually in the appropriate order.

For example:

```bash
mysql -u root -p ecommerce_pbl < unf.sql
```

Then execute the normalization, analysis, and verification scripts as appropriate for their dependencies.

**Important:** The exact execution order must be confirmed by inspecting the scripts. Some stages may depend on tables created by earlier stages. Avoid running scripts blindly against an existing database, as this may cause conflicts or affect existing data.

## Verification and Testing

The project is intended to verify more than successful SQL execution.

The verification process should examine:

1. **Data integrity:** Primary keys, foreign keys, and applicable constraints.
2. **Functional dependencies:** Whether the proposed dependencies hold under the defined business rules.
3. **Candidate keys:** Whether all relevant candidate keys have been identified.
4. **Normalization:** Whether each relation satisfies the claimed normal form.
5. **Lossless decomposition:** Whether decomposed relations can reconstruct the original information without losing records or introducing spurious tuples.
6. **Dependency preservation:** Whether the original functional dependencies remain enforceable after decomposition, where claimed.
7. **Data consistency:** Whether the resulting relations preserve the information represented by the initial dataset.

A successful test result should be reported only after the corresponding SQL checks or mathematical verification have been performed.

## Expected Deliverables

- Initial unnormalized dataset.
- SQL implementations for the normalization stages.
- Functional dependency and candidate-key analysis.
- Lossless-join and dependency-preservation verification.
- SQL test scripts and their results.
- Written project report.
- PowerPoint presentation for the project demonstration.

## Academic Scope

This project is designed to demonstrate understanding of relational database design and normalization through SQL implementation and theoretical analysis.

It does not aim to implement a production-ready e-commerce platform. Its primary focus is the correctness, justification, and verification of the database's normalization process.

## Acknowledgements

We thank **Dr. K. Arpitha Sreenivasulu** for assigning and guiding this DBMS micro project.

---

**Project:** E-commerce Database Design and Normalization  
**Database:** `ecommerce_pbl`  
**Technology:** MySQL 8.4.11
