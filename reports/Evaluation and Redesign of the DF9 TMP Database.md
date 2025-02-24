# Evaluation and Redesign of the DF9 TMP Database

**Evaluation and Redesign of the TMP DF9 Database for Migration from MS Access to PostgreSQL**

**NOTE!! NEED TO INTEGRATE MORE OF THE TEXT AND CITATIONS FROM “Denormalization of TMP Database”**

**ADDED REASONS AND POINTS**

the DF9 database mainly for use in analysis. Once data values are integrated and finalized, there will be no updates

modern statistical software like R and Python can easily handle strings as nominal (unordered) or ordinal (ordered) factor variables. Numeric values are misleading at best for the nominal variables. For those insistent on using spreadsheets for statistical analysis and visualization (e.g. MS Excel), ordinal string values can be can be replaced with numbers using “find and replace” or by using any number of free AI tools online to reduce the text of the ordinal string columns to their numeric prefixes (e.g. “1. Low” —> 1~~. Low~~)

Importantly, DF9 is only one component in the wider constellation of TMP databases and datasets to be integrated in the final product for tDAR:

- DF8/DF9/DF10
- The Ceramic REANs DF2
- The XOME architectural feature data
- The On-Site and Off-Site TMP Map GIS Features

These include data with different — spatially linked, but *distinct* — units of analysis.

Given that DF8/DF9/DF10 can be represented as a single table, tt makes the most sense to include it as one of the tables in an integrated database 

As well as further geospatially linked data that will be able to be queried spatially using the PostGIS framework

**THIS SUGGESTS THAT THE ETL PIPELINE SHOULD BE LAST!!** — ***AS A MEANS OF TESTING THE GEOSPATIAL DATABASE, AS WELL AS PROVIDING USER TEMPLATEs (Python notebook; Rmd) for how to use and extract data from the final integrated geospatial PostGIS database***

# **1. Introduction**

Database design is fundamentally a balance between **efficiency, flexibility, and performance**. At its core, normalization is a method for **structuring data to minimize redundancy and maintain integrity**, while denormalization is a **deliberate relaxation of these principles** to improve **query performance and usability**. The decision to normalize or denormalize a database depends on **the specific operational needs** of a system, including factors such as **data consistency, update frequency, query complexity, and reporting efficiency** (Codd, 1970; Chen, 2021).

This essay provides a structured discussion on when **greater normalization**, **lesser normalization**, and **denormalization** are appropriate in database design. It will serve as an introduction to a deeper analysis of the **TMP DF9 Database**, arguing for its **denormalization into a single table** to optimize its usability and efficiency.

## **1.1. The DF9 Database**

**SHIT TO ADD**

- Background
- Explain the data
- TMP Database genealogy / history (DF8—>DF9—>DF10)
- Visualizations, tables, changes in variable names+values, variable additions and removals
- problems with particular variables
- Going through the data by category + variable — metadata, data quality, analyzing their strengths and weaknesses, accuracy and validity (per DF8 and DF9 metadata documents
- Database structures
- Flow charts / Database ERDs compared
- Annies DF10 changes and normalization explanation
- Address Annies changes (non-normalization-related) … which to keep and which to revert
- Address Annie’s normalization changes
- Conversion of DF8, DF9 and DF10 into wide format

**DF8-DF9-DF10 COMPARISON, CROSS-VALIDATION, INTEGRATION, DATA DICTIONARY AND METADATA CODEBOOKS ⇒ YEILDING DF11**

- Data (cross-)validation; Automated Data Validation and Reporting; Missing Data; Data Validation and Organization of Metadata for Local and Remote Tables
- Data Dictionary; Data labeling; Metadata; Automatic Codebooks from Metadata Encoded in Dataset Attributes;

The existing DF9 database in MS Access consists of two major components:

1. **Core Tables:** The database has 18 "core" tables that all share the same primary key with 1-to-1 relationships and the same number of rows (essentially, splitting a single large table into 18 smaller tables). Altogether these are some ~290 unique columns with 5050 rows, which are split into 18 tables that share the same primary key. Most of the values in these tables are numeric.
2. **Codes Tables:** In addition to these "core" tables are 33 smaller "codes" tables, each of which contains two columns (usually <15 rows). Numerous columns in the "core" tables populated with numeric values are actually numeric codes for factor variables (nominal and ordinal). In this way, the "codes" tables store the descriptions and/or explanations of the numeric values for numeric values in specific "core" table columns. All of the "codes" tables each have 2 columns: "code" (the numeric value corresponding to the values populated in the corresponding "core" table columns) and "description" (a string variable explaining what the numeric code means). A single "codes" table often corresponds to multiple "core" table columns (some "codes" tables are linked to only one "core" tables column, while others are linked to 10-15 "core" tables columns). The numeric values populated in these linked "core" table columns can only have values that also exist in the code column of its corresponding "codes" table.

The data need to be compared and cross-validated against (and in a few limited cases, integrated with) other differently-structured versions of the same database.   However, the data are historical, and not being added to or updated aside from limited inaccuracy corrections. From this perspective, a full-scale de-normalization to a single large table might be warranted for the sake of simplicity. Doing so would require either replacing numeric coded values with either their description strings (nominal vars) or combining the number with the description (ordinal vars; e.g. if the codes table rows were 1 (code) == "low" (description), 2 == "moderate" and 3 == "high", then the new "core" table values might be "1. Low", "2. Moderate" and "3. High")

Given that this database is primarily historical, with only limited corrections applied, the key considerations in redesigning the schema for PostgreSQL include normalization versus denormalization, query efficiency, and ease of cross-validation with other database versions. The following analysis evaluates the current schema, identifies inefficiencies, and provides recommendations for optimizing the database design before its migration to PostgreSQL.

# 2. Background: **Normalization, Denormalization, and the Trade-offs of Database Design**

## **2.1. The Role of Normalization in Database Design**

### **What is Normalization?**

Normalization is a structured process that **organizes database tables** to minimize redundancy and dependency issues. The key objectives of normalization are to:

1. **Eliminate Data Redundancy** – Reduce duplicated data across tables.
2. **Ensure Data Integrity** – Prevent anomalies in inserts, updates, and deletions.
3. **Improve Maintainability** – Simplify schema updates without extensive modifications (Elmasri & Navathe, 2015).

The normalization process is typically defined through a **series of normal forms (NF)**:

- **First Normal Form (1NF)** ensures that each column contains atomic values (indivisible data).
- **Second Normal Form (2NF)** eliminates partial dependencies by ensuring all attributes depend on the full primary key.
- **Third Normal Form (3NF)** removes transitive dependencies, ensuring that non-key attributes depend only on the primary key.
- **Boyce-Codd Normal Form (BCNF)** is a stricter version of 3NF, addressing cases where candidate keys introduce redundancy (Codd, 1970; Garcia-Molina, Ullman, & Widom, 2008).

A fully normalized database is **ideal for transactional systems (OLTP)** where maintaining **high integrity, consistency, and reducing redundant storage** are primary concerns.

---

### **When is Greater Normalization Appropriate?**

Normalization is beneficial in databases that require:

1. **Data Consistency & Integrity**: Systems where data must be **strictly accurate**, such as **banking transactions, medical records, and financial applications** (Özsu & Valduriez, 2020).
2. **Frequent Updates & Inserts**: When records are modified often, normalized schemas prevent **update anomalies** and maintain **referential integrity** (Chen, 2021).
3. **Transactional Efficiency (OLTP)**: In high-volume transactional environments, normalized databases minimize redundant writes and keep updates efficient (PostgreSQL Global Development Group, 2023).
4. **Storage Efficiency**: Normalized designs **reduce disk usage**, as duplicate data is removed, which can be beneficial for large-scale storage constraints (Elmasri & Navathe, 2015).

🔹 **Example: Normalization in a Banking Database**
A **banking system** must ensure **accurate and consistent records** across accounts, transactions, and users. A fully normalized schema might include:

- **Customers(customer_id, name, email, address)**
- **Accounts(account_id, customer_id, balance)**
- **Transactions(transaction_id, account_id, amount, date)**

By ensuring **each entity is managed separately**, the system prevents data duplication while maintaining **strict financial accuracy**.

---

### **When is Lesser Normalization Appropriate?**

Although strict normalization improves **data consistency and maintenance**, it can sometimes be **too rigid or inefficient**. Lesser normalization, or **relaxed normalization**, is a compromise between **data integrity and performance**. It is most appropriate when:

1. **Queries Require Many Joins**: If normalized tables require **excessive JOIN operations** to fetch commonly accessed data, a slightly denormalized structure can improve query speed (Shin & Sanders, 2006).
2. **Read-Heavy Applications**: Systems where reads far outweigh writes (e.g., **reporting systems, dashboards**) benefit from reducing complex joins (Stonebraker & Hellerstein, 2005).
3. **Small, Static Data Sets**: If a database is **rarely updated**, maintaining strict normalization provides **little practical benefit** and can be relaxed for usability (Sanders & Shin, 2001).

🔹 **Example: A Product Database in an E-commerce System**
A highly normalized product catalog might store **categories, suppliers, brands, and product information** across multiple tables, requiring multiple joins to generate reports. However, if **product attributes rarely change**, a partially denormalized table that pre-stores category and brand information alongside product details can speed up **catalog queries**.

```sql
SELECT product_name, brand_name, category_name, price FROM Products;

```

This approach balances **read efficiency** with **maintainability**.

---

## **2.2. Denormalization: When Should a Database Be Denormalized?**

Denormalization is the **deliberate introduction of redundancy** in a database to improve **query performance and usability**. It is most appropriate when:

1. **Performance Bottlenecks Exist Due to Excessive Joins**: Highly normalized schemas can result in **slow query performance**, especially when **aggregating or joining many tables** (Kimball & Ross, 2013).
2. **Read-Heavy Analytical Workloads (OLAP)**: If a database is used mainly for **reporting, analysis, or data retrieval**, denormalization can **precompute and store aggregated results**, reducing query complexity (Chudinov, Osipova, & Bobrova, 2017).
3. **Historical, Read-Only Data**: If a database is **rarely updated**, strict normalization is unnecessary. Storing data in a **single wide table** can significantly improve **lookup speed** (Shin & Sanders, 2006).
4. **Improving Data Accessibility for Non-Technical Users**: If users frequently need **reports with human-readable descriptions**, replacing numeric codes with textual descriptions within a single table can **eliminate the need for lookups and joins** (Sanders & Shin, 2001).

🔹 **Example: Denormalization in a Data Warehouse**
A **customer orders report** might require **customer details, order history, and product information**. A normalized schema would require multiple joins across:

- **Customers**
- **Orders**
- **Products**
- **Order_Items**

Instead, a **denormalized "Orders_Flat" table** can store **precomputed sales totals, customer details, and product descriptions**:

| order_id | customer_name | product_name | total_price |
| --- | --- | --- | --- |
| 1001 | Alice | Laptop | 1200.00 |
| 1002 | Bob | Smartphone | 800.00 |

This approach **eliminates the need for complex joins**, speeding up reporting queries.

# **3. Evaluation of Current Database Schema**

### **3.1 The “Core” Tables**

The 18 core tables share a primary key and contain identical row counts, suggesting that they effectively represent a **single logical entity** artificially divided into multiple tables.

- **Advantages of the Current Design:**
    - Vertical partitioning can be beneficial when different parts of the dataset are accessed independently (Chen, 2021, p. 47).
    - It may improve **write** performance in some transactional databases, though this is not a significant factor in a read-heavy historical database.
- **Disadvantages of the Current Design:**
    - **Unnecessary complexity**: Since each table contains the same number of rows and primary key values, queries often require multiple joins to retrieve related data, increasing query complexity and execution time (Sanders & Shin, 2001, p. 9).
    - **Normalization concerns**: The schema appears to be over-normalized without a clear operational need. A **single merged table** would allow for more efficient querying and maintenance (Chudinov et al., 2017, p. 3).

### **3.2 The “Codes” Tables**

The 33 codes tables function as **lookup tables**, mapping numeric values in the core tables to human-readable descriptions. While lookup tables are a standard feature in relational database design, the current structure presents issues:

- **Advantages:**
    - Normalization prevents the repetition of text descriptions, reducing storage requirements (Chen, 2021, p. 32).
    - Lookup tables allow for easy modification of descriptions without affecting the core tables.
- **Disadvantages:**
    - **Over-normalization**: The presence of 33 separate lookup tables may lead to excessive joins, negatively impacting query performance (Shin & Sanders, 2006, p. 271).
    - **Complexity in maintenance**: Many codes tables are linked to multiple core table columns, making schema updates cumbersome.
    - **Query inefficiency**: If reports frequently require human-readable descriptions, querying often necessitates joining multiple lookup tables, increasing computational overhead (Sanders & Shin, 2001, p. 8).

---

# **4. Recommendations for Redesign**

### **4.1 Merging the Core Tables**

Given that the 18 core tables share the same primary key and row count, merging them into a **single wide table** is recommended.

- **Benefits of a Unified Table:**
    - Reduces the need for complex joins, simplifying queries.
    - Improves performance for **read-heavy** workloads, as PostgreSQL can efficiently index and retrieve data from a single table (PostgreSQL Global Development Group, 2023, Ch. 5).
    - Facilitates data validation and integrity checks.
- **Potential Challenges:**
    - Managing a 290-column table can be unwieldy. However, since the dataset is not actively modified, this is less of a concern.
    - Proper indexing strategies will be required to optimize query performance.

### **4.2 Consolidating the Codes Tables**

Rather than maintaining 33 separate lookup tables, a **single lookup table** structure should be implemented:

```sql
CREATE TABLE lookup_table (
    id SERIAL PRIMARY KEY,
    category VARCHAR(100),  -- The factor variable type (e.g., 'Risk Level', 'Category')
    code INTEGER,           -- The numeric value stored in the core table
    description TEXT        -- The corresponding description
);

```

- **Advantages:**
    - Eliminates the need to manage 33 separate tables.
    - Simplifies query logic by allowing a **single** lookup table join.
    - Ensures data consistency by centralizing factor variable definitions.

### **4.3 Partial Denormalization for Readability**

Because the dataset is primarily read-only, certain **denormalization strategies** can improve usability:

- **Replace numeric codes with meaningful descriptions** where practical, reducing the need for lookup joins (Shin & Sanders, 2006, p. 274).
- **For ordinal variables**, use a hybrid representation (e.g., `"1. Low"`, `"2. Moderate"`, `"3. High"`) to retain ordering information (Sanders & Shin, 2001, p. 10).
- **Denormalize descriptions into the core table for frequently queried fields** to optimize reporting (Shin & Sanders, 2006, p. 270).

### **4.4 Leveraging PostgreSQL Features**

PostgreSQL offers several features that can optimize the new database design:

**JSONB Columns for Semi-Structured Data:**

For attributes that are infrequently used, a `JSONB` column can store semi-structured data, improving flexibility without increasing table width:

```sql
CREATE TABLE core_table (
    id SERIAL PRIMARY KEY,
    name TEXT,
    extra_data JSONB
);

```

**Indexes for Query Optimization:**

- **BTREE Index**: Speeds up sorting and filtering on frequently queried fields.
- **GIN Index for JSONB**: Optimizes searches within JSONB fields.

```sql
CREATE INDEX idx_core_table_name ON core_table (name);
CREATE INDEX idx_core_table_extra_data ON core_table USING GIN (extra_data);

```

**Partitioning for Scalability:**

If future growth is expected, table partitioning can improve performance by distributing data across multiple physical storage units.

```sql
CREATE TABLE measurements (
    id SERIAL,
    year INT,
    value FLOAT
) PARTITION BY RANGE (year);

CREATE TABLE measurements_2022 PARTITION OF measurements
    FOR VALUES FROM (2022) TO (2023);

```

### **4.5 Consideration of Hierarchical Relationships in Codes Tables**

If some factor variables exhibit **parent-child relationships** (e.g., "Region" → "Country"), a **self-referencing hierarchy** can be implemented within the lookup table:

```sql
CREATE TABLE hierarchical_lookup (
    id SERIAL PRIMARY KEY,
    parent_id INTEGER REFERENCES hierarchical_lookup(id),
    category VARCHAR(100),
    code INTEGER,
    description TEXT
);

```

---

# **5. Additional Considerations**

1. **Common Query Patterns:**
    - If most queries require frequent joins between core tables and lookup tables, **denormalization is more justified**.
    - If reports primarily need text descriptions, storing them **directly in the core table** reduces complexity.
2. **Performance vs. Maintainability:**
    - Since the data is read-heavy, optimizing for **query simplicity** outweighs strict normalization.
3. **Integration with External Systems:**
    - If third-party applications depend on the existing structure, modifications may require **schema mapping** to maintain compatibility.

---

# **6. Conclusions**

## **6.1. Why Denormalization is Justified for the TMP DF9 Database**

Given that the **TMP DF9 Database** is primarily **historical** and not actively modified, a fully denormalized schema into **a single table** is the most practical approach. The **existing structure of 18 core tables** with identical primary keys suggests an **over-normalized design**, leading to:

- **Unnecessary complexity** in querying.
- **Slow cross-validation** with other datasets.
- **Excessive joins** reducing efficiency in data retrieval (Sanders & Shin, 2001).

By merging the core tables into a **single wide table** and integrating **factor variables with meaningful descriptions**, the new schema will:
✔ **Improve query speed and usability**.

✔ **Simplify schema maintenance**.

✔ **Reduce complexity for analytical queries**.

This analysis sets up the subsequent technical recommendations that advocate for a **fully denormalized structure** as the optimal migration strategy for PostgreSQL.

## **6.2. Summary of Recommendations**

**1.** **Merge the 18 core tables into a single wide table** for easier querying and maintenance.

**2.** **Consolidate the 33 lookup tables into a single generalized lookup table** to reduce schema complexity.

**3. Denormalize frequently accessed data** where it simplifies analysis and reporting.

**4.** **Use PostgreSQL features** such as JSONB columns, indexes, and partitioning for optimized performance.

**5.** **Consider hierarchical relationships** in lookup tables if applicable.

These recommendations balance normalization principles with practical efficiency, ensuring an optimized and maintainable PostgreSQL implementation.

---

# **References**

- Codd, E. F. (1970). "A relational model of data for large shared data banks." *Communications of the ACM*.
- Chen, W. (2021). *Database Design and Implementation*. Retrieved from [https://orc.library.atu.edu/context/atu_oer/article/1002/viewcontent/OER_DatabaseDesignImplementation_WeiruChen.pdf](https://orc.library.atu.edu/context/atu_oer/article/1002/viewcontent/OER_DatabaseDesignImplementation_WeiruChen.pdf)
- Chudinov, I. L., Osipova, V. V., & Bobrova, Y. V. (2017). *The methodology of database design in organization management systems*. Journal of Physics: Conference Series, 803.
- Elmasri, R., & Navathe, S. (2015). *Fundamentals of Database Systems*.
- Kimball, R., & Ross, M. (2013). *The Data Warehouse Toolkit*.
- PostgreSQL Global Development Group. (2023). PostgreSQL 15.2 Documentation. Retrieved from [https://www.postgresql.org/docs/current/index.html](https://www.postgresql.org/docs/current/index.html)
- Sanders, G. L., & Shin, S. K. (2001). *Denormalization effects on performance of RDBMS*. Proceedings of the 34th Annual Hawaii International Conference on System Sciences. doi:10.1109/HICSS.2001.926505
- Shin, S. K., & Sanders, G. L. (2006). *Denormalization strategies for data retrieval from data warehouses*. Decision Support Systems, 42(1), 267-282. doi:10.1016/j.dss.2004.10.003