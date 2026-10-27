-- Project: Content Evaluation Analytics
-- Purpose: Create tables for synthetic portfolio data.
-- Data is synthetic and intended for portfolio use.

USE ContentEvaluationAnalytics;
GO

-- 1. Contributors
CREATE TABLE dbo.Contributors
(
    contributor_id VARCHAR(10) NOT NULL PRIMARY KEY,
    [group]        VARCHAR(10) NOT NULL,
    join_date      DATE NOT NULL
);
GO

-- 2. Attendance
CREATE TABLE dbo.Attendance
(
    contributor_id   VARCHAR(10) NOT NULL,
    [date]           DATE NOT NULL,
    status           VARCHAR(10) NOT NULL,
    leave_applied    BIT NOT NULL,
    timesheet_filled BIT NOT NULL,

    CONSTRAINT PK_Attendance
        PRIMARY KEY (contributor_id, [date]),

    CONSTRAINT FK_Attendance_Contributors
        FOREIGN KEY (contributor_id)
        REFERENCES dbo.Contributors(contributor_id)
);
GO

