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


-- Checking whether improvement was consistent across contributors

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
        t.task_date,
        qa.score,
        qa.result,
        CASE
            WHEN t.task_date >= DATEADD(
                DAY, -28, ft.first_training_date
            )
             AND t.task_date < ft.first_training_date
                THEN 'Before'

            WHEN t.task_date >= ft.first_training_date
             AND t.task_date < DATEADD(
                DAY, 28, ft.first_training_date
            )
                THEN 'After'
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
),
ContributorResults AS
(
    SELECT
        contributor_id,
        TrainingPeriod,
        COUNT(*) AS TotalAudits,
        AVG(CAST(score AS DECIMAL(5,2))) AS AvgQualityScore,
        100.0 * SUM(
            CASE WHEN result = 'Pass' THEN 1 ELSE 0 END
        ) / COUNT(*) AS PassRate
    FROM AuditData
    WHERE TrainingPeriod IS NOT NULL
    GROUP BY contributor_id, TrainingPeriod
),
PairedResults AS
(
    SELECT
        contributor_id,

        MAX(CASE WHEN TrainingPeriod = 'Before'
            THEN TotalAudits END) AS AuditsBefore,

        MAX(CASE WHEN TrainingPeriod = 'After'
            THEN TotalAudits END) AS AuditsAfter,

        MAX(CASE WHEN TrainingPeriod = 'Before'
            THEN AvgQualityScore END) AS ScoreBefore,

        MAX(CASE WHEN TrainingPeriod = 'After'
            THEN AvgQualityScore END) AS ScoreAfter,

        MAX(CASE WHEN TrainingPeriod = 'Before'
            THEN PassRate END) AS PassRateBefore,

        MAX(CASE WHEN TrainingPeriod = 'After'
            THEN PassRate END) AS PassRateAfter

    FROM ContributorResults
    GROUP BY contributor_id
)
SELECT
    contributor_id,
    AuditsBefore,
    AuditsAfter,
    CAST(ScoreBefore AS DECIMAL(5,2)) AS ScoreBefore,
    CAST(ScoreAfter AS DECIMAL(5,2)) AS ScoreAfter,
    CAST(ScoreAfter - ScoreBefore AS DECIMAL(5,2))
        AS ScoreChange,
    CAST(PassRateBefore AS DECIMAL(5,2)) AS PassRateBefore,
    CAST(PassRateAfter AS DECIMAL(5,2)) AS PassRateAfter,
    CAST(PassRateAfter - PassRateBefore AS DECIMAL(5,2))
        AS PassRateChange
FROM PairedResults
WHERE
    ScoreBefore IS NOT NULL
    AND ScoreAfter IS NOT NULL
ORDER BY PassRateChange DESC;
GO