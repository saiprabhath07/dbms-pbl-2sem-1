Summary

DBMS PBL micro project — e-commerce normalization UNF→BCNF in MySQL (ecommerce_pbl); goals, working rules, scripts written

Details
- DBMS PBL micro project: e-commerce database design and normalization from UNF through 1NF, 2NF, 3NF to BCNF, implemented in MySQL (8.4.11) with SQL for schema, data, queries and tests
- Main objective is demonstrating normalization correctly, not building a full commercial e-commerce app
- Requirements: realistic business rules, FDs/candidate keys/primary keys identified, each decomposition justified mathematically, lossless-join and dependency-preservation checks, no manufactured dependencies, honest acknowledgment when a relation already meets a normal form
- Working rules for this project: concise replies without padding, incremental work with their input, discuss decisions rather than deciding for them, honest technical opinions and pushback, explain concepts only when asked, no unrequested features
- Database ecommerce_pbl; scripts written so far: unf.sql (Order_UNF with JSON repeating groups order_items, payments, return_details; two sample orders), ecommerce-1nf, -2nf, -3nf, -bcnf, ecommerce-check, ecommerce-fd-analysis, ecommerce-normalization-report
- Decided: unit_price stays in Listing (does not want a real-time/price-history design); project is a submission/presentation piece, so keep it simple, and they delegated the remaining design choices to Claude
- Submission also needs a written report and a PPT presentation; asked for a walkthrough of what the project is, which file does what, and what to present
- Team of 5 (roll numbers 26R15A66 + last two digits): 03 G. Angel, 04 K. Akshaya, 05 P. Shanmuka Sai Prabhath (the user), 06 R. Malavika, 07 V. Chaithanya. Guide/lecturer who assigned the work: Dr. K. Arpitha Sreenivasulu.
- Next step after the report: build the PPT
- College: Geethanjali College of Engineering and Technology; AR25 curriculum, AIML (CSE), 2nd year
