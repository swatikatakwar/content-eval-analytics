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
