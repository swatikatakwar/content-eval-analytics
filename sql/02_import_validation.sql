-- Project: Content Evaluation Analytics
-- Purpose: Verify imported datasets and final table row counts.

USE ContentEvaluationAnalytics;
GO

-- Verify the staging Contributors data
SELECT COUNT(*) AS Contributors_Import_Rows
FROM dbo.Contributors_Import;
GO

-- Verify the final Contributors table
SELECT COUNT(*) AS Contributors_Final_Rows
FROM dbo.Contributors;
GO

-- Verify the staging Attendance data
SELECT COUNT(*) AS Attendance_Import_Rows
FROM dbo.Attendance_Import;
GO

-- Verify the final Attendance table
SELECT COUNT(*) AS Attendance_Final_Rows
FROM dbo.Attendance;
GO

SELECT
    status,
    COUNT(*) AS RecordCount
FROM dbo.Attendance
GROUP BY status
ORDER BY RecordCount DESC;
GO

-- Verify the final Tasks table
SELECT COUNT(*) AS TotalRows
FROM dbo.Tasks;
GO

SELECT TOP 5 *
FROM dbo.Tasks;
GO

SELECT
    COUNT(*) AS TotalTasks,
    COUNT(DISTINCT contributor_id) AS ContributorsCount,
    MIN(task_date) AS FirstTaskDate,
    MAX(task_date) AS LastTaskDate
FROM dbo.Tasks;
GO

-- Verify the final QualityAudits table
SELECT COUNT(*) AS TotalRows
FROM dbo.QualityAudits;
GO

SELECT
    result,
    COUNT(*) AS AuditCount
FROM dbo.QualityAudits
GROUP BY result;
GO

-- Verify the final TrainingRecords table
SELECT COUNT(*) AS TotalRows
FROM dbo.TrainingRecords;
GO

SELECT
    module,
    COUNT(*) AS TrainingRecordsCount
FROM dbo.TrainingRecords
GROUP BY module
ORDER BY TrainingRecordsCount DESC;
GO

SELECT TOP 10 *
FROM dbo.TrainingRecords;
GO

-- Verify the final Defects table
SELECT COUNT(*) AS TotalRows
FROM dbo.Defects;
GO

SELECT
    defect_type,
    COUNT(*) AS DefectCount,
    AVG(CAST(resolution_min AS DECIMAL(10,2)))
        AS AverageResolutionMinutes
FROM dbo.Defects
GROUP BY defect_type
ORDER BY DefectCount DESC;
GO

SELECT TOP 10 *
FROM dbo.Defects;
GO


