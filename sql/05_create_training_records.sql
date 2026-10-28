
USE ContentEvaluationAnalytics;
GO

CREATE TABLE dbo.TrainingRecords
(
    contributor_id VARCHAR(10) NOT NULL,
    module VARCHAR(50) NOT NULL,
    training_date DATE NOT NULL,

    CONSTRAINT PK_TrainingRecords
        PRIMARY KEY (contributor_id, module, training_date),

    CONSTRAINT FK_TrainingRecords_Contributors
        FOREIGN KEY (contributor_id)
        REFERENCES dbo.Contributors(contributor_id)
);
GO


INSERT INTO dbo.TrainingRecords
(
    contributor_id,
    module,
    training_date
)
SELECT
    contributor_id,
    module,
    TRY_CONVERT(DATE, training_date)
FROM dbo.TrainingRecords_Import;
GO
