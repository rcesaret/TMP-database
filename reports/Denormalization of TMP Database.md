# Denormalization of TMP Database

# USER

I need to evaluate and possibly redesign a MS Access database for (prior to) conversion to postgresql and I need your help.

The database has 18 "core" tables that all share the same primary key with 1-to-1 relationships and the same number of rows (essentially, splitting a single large table into 18 smaller tables). Altogether these are some ~290 unique columns with 5050 rows, which are split into 18 tables that share the same primary key. Most of the values in these tables are numeric.

In addition to these "core" tables are 33 smaller "codes" tables, each of which contains two columns (usually <15 rows). Numerous columns in the "core" tables populated with numeric values are actually numeric codes for factor variables (nominal and ordinal). In this way, the "codes" tables store the descriptions and/or explanations of the numeric values for numeric values in specific "core" table columns. All of the "codes" tables each have 2 columns: "code" (the numeric value corresponding to the values populated in the corresponding "core" table columns) and "description" (a string variable explaining what the numeric code means). A single "codes" table often corresponds to multiple "core" table columns (some "codes" tables are linked to only one "core" tables column, while others are linked to 10-15 "core" tables columns). The numeric values populated in these linked "core" table columns can only have values that also exist in the code column of its corresponding "codes" table.

Normalization + denormalization: The data need to be compared and cross-validated against (and in a few limited cases, integrated with) other differently-structured versions of the same database.   However, the data are historical, and not being added to or updated aside from limited inaccuracy corrections. From this perspective, a full-scale de-normaization to a single large table might be warranted for the sake of simplicity. Doing so would require either replacing numeric coded values with either their description strings (nominal vars) or combining the number with the description (ordinal vars; e.g. if the codes table rows were 1 (code) == "low" (description), 2 == "moderate" and 3 == "high", then the new "core" table values might be "1. Low", "2. Moderate" and "3. High")

Can you please evaluate and critique the above database schema for me based on the verbal model explained above? What reccomendataions do you have? What further info do you need to offer better reccomendations? What additional considerations and use cases impact the optimal design principles that should be adopted?

Please feel free to ask clarifying questions in order to dive deeper into the optimal strategy for database design here

# CHATGPT

Thanks for the detailed explanation! Based on what you described, I have several observations and recommendations for evaluating and redesigning your MS Access database before migrating it to PostgreSQL.

---

### **Evaluation of Current Database Schema**

### **1. The "Core" Tables (18 tables with shared primary keys)**

- **Pros:** The current schema appears to follow a form of vertical partitioning, which can be beneficial when different parts of the dataset are accessed separately (Chen, 2021, p. 47).
- **Cons:**
    - This structure is **not inherently efficient** unless there’s a clear reason why these 18 tables need to be separate. The structure may lead to inefficiencies if there’s no compelling reason for the separation of these 18 tables (Chen, 2021, p. 63).
    - The fact that they share a primary key suggests that they could (or should) be **merged into a single table** or **restructured for better organization**. Sharing a primary key across all tables suggests that merging them into a single table or restructuring for better organization might be more effective (Sanders & Shin, 2001, p. 9).
    - Having 290 unique columns suggests **potential issues with normalization** and might make querying the data cumbersome.The presence of 290 unique columns indicates potential normalization issues and could complicate querying (Chudinov et al., 2017, p. 3).

### **2. The "Codes" Tables (33 lookup tables)**

- **Pros:** The use of lookup tables is a standard normalization practice, making the database more structured and avoiding repetition of string descriptions.Utilizing lookup tables aligns with standard normalization practices, promoting structure and avoiding redundancy (Chen, 2021, p. 32).
- **Cons:**
    - The current design **might be over-normalized**. Since multiple "core" table columns link to the same "codes" table, this could lead to an excessive number of joins in queries.The design might be over-normalized, especially if multiple "core" table columns link to the same "codes" table, leading to numerous joins in queries (Shin & Sanders, 2006, p. 271).
    - If the data is **mostly read-only**, it might be beneficial to **denormalize some of these relationships** for easier querying.Given that the data is primarily read-only, denormalizing some relationships could simplify querying (Sanders & Shin, 2001, p. 8).
    - The alternative approach of embedding the descriptions (instead of the numeric codes) in the main table could **simplify analysis and reporting**.Embedding descriptions directly into the main table might enhance analysis and reporting efficiency (Shin & Sanders, 2006, p. 275).

---

### **Recommendations for Redesign**

### **1. Consider Merging the "Core" Tables**

- Since all 18 tables share the same primary key and have the same number of rows, **you should strongly consider merging them into a single wide table**.
- This would simplify queries and reduce the need for constant joins.
- Downsides: A very wide table with 290 columns can be harder to manage in PostgreSQL, but since updates are minimal, this might not be a major concern.

Since all 18 tables share the same primary key and row count, consider consolidating them into a single table. This approach simplifies queries and reduces the need for frequent joins (Chen, 2021, p. 71). However, managing a table with 290 columns can be challenging in PostgreSQL, but with minimal updates, this may not pose significant issues (PostgreSQL Global Development Group, 2023, Ch. 5).

### **2. Handle Factor Variables Intelligently**

- Instead of maintaining 33 separate "codes" tables, consider **consolidating them into a single "lookup" table** with a structure like this:
Instead of maintaining 33 separate lookup tables, create a unified "lookup" table with the following structure (Chudinov et al., 2017, p. 4):
    
    ```
    lookup_table (
      id SERIAL PRIMARY KEY,
      category VARCHAR(100),  -- The "type" of factor variable (e.g., 'Risk Level', 'Category')
      code INTEGER,           -- The numeric value stored in the core table
      description TEXT        -- The corresponding description
    )
    
    ```
    

This consolidation simplifies maintenance and querying, eliminating the need to manage multiple tables. Establish foreign key relationships linking core table columns to this unified lookup table (PostgreSQL Global Development Group, 2023, Ch. 6).

- This makes maintenance and queries easier, as you don’t need to track 33 separate tables.
- A foreign key would link core table columns to this table.

### **3. Consider Partial Denormalization**

If the primary use case is **historical analysis and cross-validation**, then full normalization **isn't necessarily the best approach**. Consider:

- **Replacing numeric coded values with meaningful descriptions** where practical/ appropriate (Shin & Sanders, 2006, p. 274).
- **For ordinal variables**, using a format like `"1. Low"`, `"2. Moderate"`, etc., as you suggested, to retain ordering information.(Sanders & Shin, 2001, p. 10).
- If queries often require looking up descriptions, **denormalizing some columns** by storing both the numeric code and description in the main table could **reduce join complexity**.(Shin & Sanders, 2006, p. 270).

### **4. Optimizing for PostgreSQL**

Since you are moving from MS Access to PostgreSQL, take advantage of:

- **JSONB columns:** If some attributes are rarely used but still need to be stored, consider JSONB to handle semi-structured data.
- **Indexes:** Use **GIN indexes** for searching JSONB fields and **BTREE indexes** for frequently used query conditions.
- **Partitioning (if necessary):** If your dataset grows or needs to be split logically, PostgreSQL supports table partitioning.

JSONB Columns: For attributes that are infrequently used but still necessary, consider using JSONB columns to store semi-structured data. This approach offers flexibility and can improve performance when dealing with sparse data (PostgreSQL Global Development Group, 2023, Ch. 8.14).

Indexes: Implement GIN indexes for efficient searching within JSONB fields and BTREE indexes for columns frequently used in query conditions (PostgreSQL Global Development Group, 2023, Ch. 11). Proper indexing enhances query performance and overall database efficiency (Chen, 2021, p. 89).

Partitioning: If your dataset is large or logically segmented, utilize PostgreSQL’s table partitioning capabilities. Partitioning can improve query performance and manageability by dividing large tables into smaller, more manageable pieces (PostgreSQL Global Development Group, 2023, Ch. 5.11).

### **Optimizing for PostgreSQL**

PostgreSQL provides **advanced features** that can help with performance and flexibility. Let’s break them down **with explanations and example code**.

### **JSONB Columns**

### **What is JSONB?**

- `JSONB` (Binary JSON) is a column type in PostgreSQL that allows **storing semi-structured data in JSON format**.
- Unlike a rigid table structure, JSONB allows for **flexible attributes** where some rows may have additional fields that others don’t.

### **When to Use JSONB?**

- If some columns in your database are **rarely used** or change frequently.
- If your data structure isn’t **fully fixed** and you need flexibility.
- When you need to **store key-value pairs**.

### **Example:**

Instead of adding many rarely used columns to your "core" table, store them in a JSONB column:

```sql
CREATE TABLE core_table (
    id SERIAL PRIMARY KEY,
    name TEXT,
    extra_data JSONB
);

```

Insert data:

```sql
INSERT INTO core_table (name, extra_data)
VALUES ('Sample 1', '{"age": 30, "risk": "High"}'),
       ('Sample 2', '{"age": 25}');  -- No "risk" field in this row

```

Query JSONB data:

```sql
SELECT name, extra_data->>'age' AS age FROM core_table;

```

---

### **Indexes in PostgreSQL**

Indexes speed up queries. PostgreSQL provides different types of indexes:

### **BTREE Index**

- Used for **sorting and searching** (`ORDER BY`, `WHERE` conditions).
- Example: If you frequently search by `name`, create an index:
    
    ```sql
    CREATE INDEX idx_core_table_name ON core_table (name);
    
    ```
    

### **GIN Index (for JSONB)**

- Helps in searching inside JSONB fields.
- Example: If you frequently search for `risk` inside JSONB:
This makes queries like:
much faster.
    
    ```sql
    CREATE INDEX idx_core_table_extra_data ON core_table USING GIN (extra_data);
    
    ```
    
    ```sql
    SELECT * FROM core_table WHERE extra_data @> '{"risk": "High"}';
    
    ```
    

---

### **Partitioning in PostgreSQL**

### **What is Partitioning?**

- Partitioning **splits a large table into smaller pieces**, improving performance.
- Each partition contains **a subset of the data**.

### **When to Use Partitioning?**

- When the table **is very large** (millions of rows).
- When queries often **filter by a specific category** (e.g., date, region).

### **Example: Partitioning by Year**

Let’s create a table that stores data for different years:

```sql
CREATE TABLE measurements (
    id SERIAL,
    year INT,
    value FLOAT
) PARTITION BY RANGE (year);

```

Create **separate partitions** for each year:

```sql
CREATE TABLE measurements_2022 PARTITION OF measurements
    FOR VALUES FROM (2022) TO (2023);

CREATE TABLE measurements_2023 PARTITION OF measurements
    FOR VALUES FROM (2023) TO (2024);

```

Query automatically finds the correct partition:

```sql
SELECT * FROM measurements WHERE year = 2022;

```

---

Hierarchical Relationships in "Codes" Tables:

If any coded values exhibit parent-child relationships (e.g., "Regions" and "Countries"), consider implementing a self-referencing hierarchy within the unified lookup table to accurately represent these relationships (PostgreSQL Global Development Group, 2023, Ch. 5.5).
Sometimes, the coded values may have parent-child relationships instead of just being a flat list of codes. Instead of having separate lookup tables, a single table with a hierarchy is more efficient.

---

### **Additional Considerations**

1. **What are the most common queries and reports used?**
    - If queries frequently join the 18 core tables, merging them is an even stronger recommendation.
    - If reports require text descriptions often, denormalization is more justified.If your reports and queries frequently need to join the "core" tables with the "codes" tables to get text descriptions (instead of numeric codes), it may be better to store the text descriptions directly in the "core" table instead of keeping them separate in a lookup table.This reduces the need for frequent joins, making queries simpler and faster.
2. **Is performance a concern, or is readability/maintainability more important?**
    - Since the data is mostly read-only, optimizing for **query simplicity** and **analytical ease** is better than optimizing for frequent updates.
3. **How does this database interact with other systems?**
    - If external tools depend on the current structure, changing it too much might require significant downstream modifications.
4. **Are there hierarchical relationships in the "codes" tables?**
    - If any coded values have a parent-child relationship (e.g., "Regions" → "Countries"), then **a self-referencing hierarchy in a single lookup table** is better than multiple small tables.

---

### **Final Recommendations Summary**

✅ **Merge the 18 core tables into one large table** (unless there's a compelling reason to keep them separate).

✅ **Consolidate the 33 lookup tables into one or a few generalized lookup tables.**

✅ **Denormalize factor variables where it simplifies analysis.**

✅ **Store ordinal values as a combination of numeric and text for clarity.**

✅ **Use PostgreSQL features (JSONB, indexes, partial denormalization) for efficiency.**

## References

Chen, W. (2021). Database Design and Implementation. Retrieved from [https://orc.library.atu.edu/context/atu_oer/article/1002/viewcontent/OER_DatabaseDesignImplementation_WeiruChen.pdf](https://orc.library.atu.edu/context/atu_oer/article/1002/viewcontent/OER_DatabaseDesignImplementation_WeiruChen.pdf)

Chudinov, I. L., Osipova, V. V., & Bobrova, Y. V. (2017). The methodology of database design in organization management systems. Journal of Physics: Conference Series, 803.

PostgreSQL Global Development Group. (2023). PostgreSQL 15.2 Documentation. Retrieved from [https://www.postgresql.org/docs/current/index.html](https://www.postgresql.org/docs/current/index.html)

Sanders, G. L., & Shin, S. K. (2001). Denormalization effects on performance of RDBMS. Proceedings of the 34th Annual Hawaii International Conference on System Sciences. doi:10.1109/HICSS.2001.926505

Shin, S. K., & Sanders, G. L. (2006). Denormalization strategies for data retrieval from data warehouses. Decision Support Systems, 42(1), 267-282. doi:10.1016/j.dss.2004.10.003