
USE ContentEvaluationAnalytics;
GO

CREATE TABLE dbo.Tasks
(
    task_id       VARCHAR(20) NOT NULL PRIMARY KEY,
    contributor_id VARCHAR(10) NOT NULL,
    category      VARCHAR(30) NOT NULL,
    start_ts      DATETIME2 NOT NULL,
    end_ts        DATETIME2 NOT NULL,
    duration_min  INT NOT NULL,
    task_date     DATE NOT NULL,

    CONSTRAINT FK_Tasks_Contributors
        FOREIGN KEY (contributor_id)
        REFERENCES dbo.Contributors(contributor_id)
);
GO

INSERT INTO dbo.Tasks
(
    task_id,
    contributor_id,
    category,
    start_ts,
    end_ts,
    duration_min,
    task_date
)
SELECT
    task_id,
    contributor_id,
    category,
    TRY_CONVERT(DATETIME2, start_ts),
    TRY_CONVERT(DATETIME2, end_ts),
    TRY_CONVERT(INT, duration_min),
    TRY_CONVERT(DATE, task_date)
FROM dbo.Tasks_Import;
GO

USE ContentEvaluationAnalytics;
GO

-- Check the staging table's duration column type
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Tasks_Import'
  AND COLUMN_NAME = 'duration_min';
GO

-- Inspect some task durations in the staging table
SELECT TOP 10
    task_id,
    duration_min
FROM dbo.Tasks_Import
ORDER BY task_id;
GO

-- Calculate the staging table's duration totals
SELECT
    COUNT(*) AS TotalTasks,
    AVG(TRY_CAST(duration_min AS DECIMAL(10,2)))
        AS AverageDuration,
    SUM(TRY_CAST(duration_min AS DECIMAL(10,2)))
        AS TotalTaskMinutes
FROM dbo.Tasks_Import;
GO
