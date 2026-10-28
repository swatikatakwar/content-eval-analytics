-- Run the row-count validation query
USE ContentEvaluationAnalytics;
GO

SELECT 'Contributors' AS TableName, COUNT_BIG(*) AS TotalRows
FROM dbo.Contributors

UNION ALL
SELECT 'Attendance', COUNT_BIG(*)
FROM dbo.Attendance

UNION ALL
SELECT 'Tasks', COUNT_BIG(*)
FROM dbo.Tasks

UNION ALL
SELECT 'QualityAudits', COUNT_BIG(*)
FROM dbo.QualityAudits

UNION ALL
SELECT 'TrainingRecords', COUNT_BIG(*)
FROM dbo.TrainingRecords

UNION ALL
SELECT 'Defects', COUNT_BIG(*)
FROM dbo.Defects;
GO

-- Check the relationships between tables

-- Tasks referencing unknown contributors
SELECT COUNT(*) AS TasksWithUnknownContributors
FROM dbo.Tasks t
LEFT JOIN dbo.Contributors c
    ON t.contributor_id = c.contributor_id
WHERE c.contributor_id IS NULL;

-- Audits referencing unknown tasks
SELECT COUNT(*) AS AuditsWithUnknownTasks
FROM dbo.QualityAudits qa
LEFT JOIN dbo.Tasks t
    ON qa.task_id = t.task_id
WHERE t.task_id IS NULL;

-- Training records referencing unknown contributors
SELECT COUNT(*) AS TrainingWithUnknownContributors
FROM dbo.TrainingRecords tr
LEFT JOIN dbo.Contributors c
    ON tr.contributor_id = c.contributor_id
WHERE c.contributor_id IS NULL;

-- Defects referencing unknown contributors
SELECT COUNT(*) AS DefectsWithUnknownContributors
FROM dbo.Defects d
LEFT JOIN dbo.Contributors c
    ON d.contributor_id = c.contributor_id
WHERE c.contributor_id IS NULL;

-- Attendance records referencing unknown contributors
SELECT COUNT(*) AS AttendanceWithUnknownContributors
FROM dbo.Attendance a
LEFT JOIN dbo.Contributors c
    ON a.contributor_id = c.contributor_id
WHERE c.contributor_id IS NULL;
GO

-- Check key business rules

-- Check that score equals 100 minus dent points
SELECT COUNT(*) AS IncorrectScores
FROM dbo.QualityAudits
WHERE score <> 100 - dent_points;

-- Check that Pass/Fail matches the score rule
SELECT COUNT(*) AS IncorrectResults
FROM dbo.QualityAudits
WHERE (score < 90 AND result <> 'Fail')
   OR (score >= 90 AND result <> 'Pass');

-- Check that failed audits have a discrepancy category
SELECT COUNT(*) AS FailedAuditsMissingCategory
FROM dbo.QualityAudits
WHERE result = 'Fail'
  AND discrepancy_category IS NULL;

-- Check invalid task durations
SELECT COUNT(*) AS InvalidTaskDurations
FROM dbo.Tasks
WHERE duration_min <= 0
   OR end_ts < start_ts;

-- Check invalid defect resolution durations
SELECT COUNT(*) AS InvalidDefectDurations
FROM dbo.Defects
WHERE resolution_min < 0
   OR resolved_ts < opened_ts;
GO

