-- Calculate overall productivity KPIs
USE ContentEvaluationAnalytics;
GO

SELECT
    COUNT(*) AS TotalTasksRecorded,

    COUNT(DISTINCT contributor_id)
        AS ContributorsWithTasks,

    CAST(
        AVG(CAST(duration_min AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageTaskDurationMin,

    SUM(duration_min) AS TotalTaskMinutes,

    CAST(
        SUM(duration_min) / 60.0
        AS DECIMAL(12,2)
    ) AS TotalTaskHours,

    MIN(task_date) AS FirstTaskDate,

    MAX(task_date) AS LastTaskDate

FROM dbo.Tasks;
GO

-- Compare productivity across task categories
SELECT
    category,
    COUNT(*) AS TasksRecorded,

    CAST(
        AVG(CAST(duration_min AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageDurationMin,

    SUM(duration_min) AS TotalMinutes,

    CAST(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS PercentageOfTasks

FROM dbo.Tasks
GROUP BY category
ORDER BY TasksRecorded DESC;
GO
