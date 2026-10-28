
USE ContentEvaluationAnalytics;
GO

CREATE TABLE dbo.Defects
(
    defect_id       VARCHAR(20) NOT NULL PRIMARY KEY,
    contributor_id  VARCHAR(10) NOT NULL,
    defect_type     VARCHAR(50) NOT NULL,
    bucket_tier     VARCHAR(30) NOT NULL,
    topic_bucket    VARCHAR(50) NOT NULL,
    watchlist_added BIT NOT NULL,
    opened_ts       DATETIME2 NOT NULL,
    resolved_ts     DATETIME2 NOT NULL,
    resolution_min  INT NOT NULL,

    CONSTRAINT FK_Defects_Contributors
        FOREIGN KEY (contributor_id)
        REFERENCES dbo.Contributors(contributor_id)
);
GO


INSERT INTO dbo.Defects
(
    defect_id,
    contributor_id,
    defect_type,
    bucket_tier,
    topic_bucket,
    watchlist_added,
    opened_ts,
    resolved_ts,
    resolution_min
)
SELECT
    defect_id,
    contributor_id,
    defect_type,
    bucket_tier,
    topic_bucket,
    CASE
        WHEN LOWER(LTRIM(RTRIM(
            CAST(watchlist_added AS VARCHAR(10))
        ))) IN ('true', '1', 'yes') THEN 1
        WHEN LOWER(LTRIM(RTRIM(
            CAST(watchlist_added AS VARCHAR(10))
        ))) IN ('false', '0', 'no') THEN 0
        ELSE NULL
    END,
    TRY_CONVERT(DATETIME2, opened_ts),
    TRY_CONVERT(DATETIME2, resolved_ts),
    TRY_CONVERT(INT, resolution_min)
FROM dbo.Defects_Import;
GO
