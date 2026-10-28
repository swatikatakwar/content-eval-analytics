-- Run the overall quality KPI query
USE ContentEvaluationAnalytics;
GO

SELECT
    COUNT(*) AS TotalAudits,

    SUM(CASE
        WHEN result = 'Pass' THEN 1
        ELSE 0
    END) AS PassedAudits,

    SUM(CASE
        WHEN result = 'Fail' THEN 1
        ELSE 0
    END) AS FailedAudits,

    CAST(
        100.0 * SUM(CASE WHEN result = 'Pass' THEN 1 ELSE 0 END)
        / COUNT(*) AS DECIMAL(5,2)
    ) AS PassRatePercent,

    CAST(
        100.0 * SUM(CASE WHEN result = 'Fail' THEN 1 ELSE 0 END)
        / COUNT(*) AS DECIMAL(5,2)
    ) AS FailRatePercent,

    CAST(AVG(CAST(score AS DECIMAL(5,2))) AS DECIMAL(5,2))
        AS AverageQualityScore

FROM dbo.QualityAudits;
GO

-- Find the most common failure categories
SELECT
    discrepancy_category,
    COUNT(*) AS FailedAuditCount,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS PercentageOfFailures

FROM dbo.QualityAudits
WHERE result = 'Fail'
GROUP BY discrepancy_category
ORDER BY FailedAuditCount DESC;
GO
