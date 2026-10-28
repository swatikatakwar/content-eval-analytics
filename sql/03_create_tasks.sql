
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
