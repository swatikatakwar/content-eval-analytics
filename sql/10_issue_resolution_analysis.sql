-- Calculate overall issue-resolution KPIs

USE ContentEvaluationAnalytics;
GO

SELECT
    COUNT(*) AS TotalDefects,

    COUNT(DISTINCT contributor_id)
        AS ContributorsWithDefects,

    CAST(
        AVG(CAST(resolution_min AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageResolutionMinutes,

    CAST(
        AVG(CAST(resolution_min AS DECIMAL(10,2))) / 60.0
        AS DECIMAL(10,2)
    ) AS AverageResolutionHours,

    SUM(resolution_min) AS TotalResolutionMinutes,

    SUM(CASE
        WHEN watchlist_added = 1 THEN 1
        ELSE 0
    END) AS WatchlistedDefects,

    CAST(
        100.0 * SUM(CASE
            WHEN watchlist_added = 1 THEN 1
            ELSE 0
        END) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS WatchlistedPercent

FROM dbo.Defects;
GO


-- Compare defect types

SELECT
    defect_type,
    COUNT(*) AS DefectCount,

    CAST(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS PercentageOfDefects,

    CAST(
        AVG(CAST(resolution_min AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageResolutionMinutes,

    CAST(
        MAX(resolution_min)
        AS INT
    ) AS MaximumResolutionMinutes

FROM dbo.Defects
GROUP BY defect_type
ORDER BY DefectCount DESC;
GO

-- Compare resolution time by bucket tier

SELECT
    bucket_tier,
    COUNT(*) AS DefectCount,

    CAST(
        AVG(CAST(resolution_min AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageResolutionMinutes,

    CAST(
        100.0 * SUM(CASE
            WHEN watchlist_added = 1 THEN 1
            ELSE 0
        END) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS WatchlistedPercent

FROM dbo.Defects
GROUP BY bucket_tier
ORDER BY AverageResolutionMinutes DESC;
GO
