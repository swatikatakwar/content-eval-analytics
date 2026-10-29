-- Analyze training and quality

USE ContentEvaluationAnalytics;
GO

WITH FirstTraining AS
(
    SELECT
        contributor_id,
        MIN(training_date) AS first_training_date
    FROM dbo.TrainingRecords
    GROUP BY contributor_id
),
AuditData AS
(
    SELECT
        ft.contributor_id,
        ft.first_training_date,
        t.task_date,
        qa.score,
        qa.result,

        CASE
            WHEN t.task_date >= DATEADD(
                DAY, -28, ft.first_training_date
            )
             AND t.task_date < ft.first_training_date
                THEN 'Before Training'

            WHEN t.task_date >= ft.first_training_date
             AND t.task_date < DATEADD(
                DAY, 28, ft.first_training_date
            )
                THEN 'After Training'
        END AS TrainingPeriod

    FROM FirstTraining ft
    INNER JOIN dbo.Tasks t
        ON ft.contributor_id = t.contributor_id
    INNER JOIN dbo.QualityAudits qa
        ON t.task_id = qa.task_id
    WHERE
        t.task_date >= DATEADD(
            DAY, -28, ft.first_training_date
        )
        AND t.task_date < DATEADD(
            DAY, 28, ft.first_training_date
        )
)
SELECT
    TrainingPeriod,
    COUNT(*) AS TotalAudits,
    COUNT(DISTINCT contributor_id) AS Contributors,

    CAST(
        AVG(CAST(score AS DECIMAL(5,2)))
        AS DECIMAL(5,2)
    ) AS AverageQualityScore,

    CAST(
        100.0 * SUM(
            CASE WHEN result = 'Pass' THEN 1 ELSE 0 END
        ) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS PassRatePercent

FROM AuditData
WHERE TrainingPeriod IS NOT NULL
GROUP BY TrainingPeriod
ORDER BY TrainingPeriod;
GO
