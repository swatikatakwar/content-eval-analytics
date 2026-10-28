
USE ContentEvaluationAnalytics;
GO

DROP TABLE dbo.QualityAudits;
GO

CREATE TABLE dbo.QualityAudits
(
    audit_id VARCHAR(20) NOT NULL PRIMARY KEY,
    task_id VARCHAR(20) NOT NULL,
    audit_type VARCHAR(10) NOT NULL,
    dent_points INT NOT NULL,
    score INT NOT NULL,
    result VARCHAR(10) NOT NULL,
    discrepancy_category VARCHAR(50) NULL,

    CONSTRAINT FK_QualityAudits_Tasks
        FOREIGN KEY (task_id)
        REFERENCES dbo.Tasks(task_id)
);
GO


INSERT INTO dbo.QualityAudits
(
    audit_id,
    task_id,
    audit_type,
    dent_points,
    score,
    result,
    discrepancy_category
)
SELECT
    audit_id,
    task_id,
    audit_type,
    dent_points,
    score,
    result,
    NULLIF(discrepancy_category, 'None')
FROM dbo.QualityAudits_Import;
GO
