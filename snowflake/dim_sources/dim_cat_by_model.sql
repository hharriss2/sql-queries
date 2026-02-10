CREATE OR REPLACE TABLE walmart.dim_sources.dim_cat_by_model
(
    cbm_id INTEGER DEFAULT walmart.dim_sources.dim_cat_by_model_seq.NEXTVAL PRIMARY KEY,
    model VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(100),
    department VARCHAR(100),
    sub_category VARCHAR(100),
    inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

/*UPSERT */
MERGE INTO walmart.dim_sources.dim_cat_by_model AS target
USING (
    SELECT
        litm_identifier2nditem   AS model,
        supergroup_desc1         AS category,
        ultragroup_desc1         AS department,
        platform_desc1           AS sub_category
    FROM djus_jde_shared.public.ODS_F4101_ITEM_MASTER
) AS source
ON target.model = source.model

WHEN MATCHED THEN
    UPDATE SET
        category     = source.category,
        department   = source.department,
        sub_category = source.sub_category

WHEN NOT MATCHED THEN
    INSERT (
        model,
        category,
        department,
        sub_category
    )
    VALUES (
        source.model,
        source.category,
        source.department,
        source.sub_category
    );
