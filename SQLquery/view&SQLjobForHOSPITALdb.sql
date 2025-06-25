--////////////////////// Trigger //////////////////////////

-- After Insert on Appointments → Auto-log in MedicalRecords
CREATE TRIGGER trg_AfterInsert_Appointment_MedicalLog
ON Appointments
AFTER INSERT
AS
BEGIN
    INSERT INTO MedicalRecords (PatientID, DoctorID, Diagnosis, TreatmentPlan, VisitDate)
    SELECT 
        i.PatientID,
        i.DoctorID,
        'Auto-generated entry',   -- default diagnosis
        'Initial consultation',   -- default treatment
        CAST(i.AppointmentDate AS DATE)
    FROM inserted i;
END;
GO

-- Before Delete on Patients → Prevent deletion if pending bills exist
CREATE TRIGGER trg_PreventPatientDelete_IfBillsExist
ON Patients
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Billing b
        INNER JOIN deleted d ON b.PatientID = d.PatientID
    )
    BEGIN
        RAISERROR ('Cannot delete patient with pending billing records.', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        DELETE FROM Patients
        WHERE PatientID IN (SELECT PatientID FROM deleted);
    END
END;
GO

-- After update on Rooms → Ensure no two patients occupy the same room
CREATE TRIGGER trg_ValidateRoomAssignment
ON Admissions
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT RoomNumber
        FROM Admissions
        GROUP BY RoomNumber, DateIn, DateOut
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR ('Two patients cannot occupy the same room at the same time.', 16, 1);
        ROLLBACK;
    END
END;
GO

-- //////////////////////// Security (DCL) ////////////////// 

-- Create user-defined database roles
CREATE ROLE DoctorUser;
CREATE ROLE AdminUser;

-- GRANT SELECT on Patients and Appointments to DoctorUser
GRANT SELECT ON Patients TO DoctorUser;
GRANT SELECT ON Appointments TO DoctorUser;


-- GRANT INSERT, UPDATE to AdminUser on all tables
GRANT INSERT, UPDATE ON Patients TO AdminUser;
GRANT INSERT, UPDATE ON Doctors TO AdminUser;
GRANT INSERT, UPDATE ON Departments TO AdminUser;
GRANT INSERT, UPDATE ON Staff TO AdminUser;
GRANT INSERT, UPDATE ON Appointments TO AdminUser;
GRANT INSERT, UPDATE ON Admissions TO AdminUser;
GRANT INSERT, UPDATE ON Rooms TO AdminUser;
GRANT INSERT, UPDATE ON MedicalRecords TO AdminUser;
GRANT INSERT, UPDATE ON Billing TO AdminUser;
GRANT INSERT, UPDATE ON Users TO AdminUser;


-- REVOKE DELETE on Doctors from Everyone (or a role/user)
REVOKE DELETE ON Doctors FROM AdminUser;
REVOKE DELETE ON Doctors FROM DoctorUser;


--//////////////////// TCL transaction //////////////////////

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @PatientID INT = 1004;
    DECLARE @RoomNumber INT = 801;
    DECLARE @AdmissionID INT;
    DECLARE @DateIn DATE = GETDATE();
    DECLARE @DateOut DATE = DATEADD(DAY, 3, GETDATE());

    -- 1. Insert into Admissions
    INSERT INTO Admissions (PatientID, RoomNumber, DateIn, DateOut)
    VALUES (@PatientID, @RoomNumber, @DateIn, @DateOut);

    -- 2. Update room availability
    UPDATE Rooms
    SET IsAvailable = 0
    WHERE RoomNumber = @RoomNumber;

    -- 3. Create billing
    INSERT INTO Billing (PatientID, TotalCost, Services, BillDate)
    VALUES (@PatientID, 120.00, 'Admission + Room Charges', GETDATE());

    -- 4. Commit if all succeed
    COMMIT;
    PRINT 'Patient admitted, room updated, and billing created successfully.';

END TRY
BEGIN CATCH
    -- Rollback if any error occurs
    ROLLBACK;
    PRINT 'Transaction failed: ' + ERROR_MESSAGE();
END CATCH;




--/////////////////// view //////////////////

-- Upcoming appointments per doctor

CREATE VIEW vw_DoctorSchedule AS
SELECT 
    d.DoctorID,
    d.FullName AS DoctorName,
    a.AppointmentDate,
    p.FullName AS PatientName
FROM Appointments a
JOIN Doctors d ON a.DoctorID = d.DoctorID
JOIN Patients p ON a.PatientID = p.PatientID
WHERE a.AppointmentDate > GETDATE();


-- Patient info with their latest visit

CREATE VIEW vw_PatientSummary AS
SELECT 
    p.PatientID,
    p.FullName,
    p.DOB,
    p.Gender,
    mr.VisitDate,
    mr.Diagnosis,
    mr.TreatmentPlan
FROM Patients p
OUTER APPLY (
    SELECT TOP 1 *
    FROM MedicalRecords mr
    WHERE mr.PatientID = p.PatientID
    ORDER BY mr.VisitDate DESC
) mr;


-- Number of doctors and patients per department

CREATE VIEW vw_DepartmentStats AS
SELECT 
    d.DepartmentID,
    d.DeptName,
    COUNT(DISTINCT doc.DoctorID) AS TotalDoctors,
    COUNT(DISTINCT ap.PatientID) AS TotalPatients
FROM Departments d
LEFT JOIN Doctors doc ON doc.DepartmentID = d.DepartmentID
LEFT JOIN Appointments ap ON ap.DoctorID = doc.DoctorID
GROUP BY d.DepartmentID, d.DeptName;



--///////////////// SQL Server Job (SQL Agent Job) ///////////////

CREATE TABLE DoctorDailyScheduleLog (
    LogID INT IDENTITY PRIMARY KEY,
    DoctorID INT,
    DoctorName VARCHAR(100),
    AppointmentDate DATETIME,
    PatientName VARCHAR(100),
    LoggedAt DATETIME DEFAULT GETDATE()
);


CREATE PROCEDURE sp_LogDoctorDailySchedule
AS
BEGIN
    INSERT INTO DoctorDailyScheduleLog (DoctorID, DoctorName, AppointmentDate, PatientName)
    SELECT 
        d.DoctorID,
        d.FullName,
        a.AppointmentDate,
        p.FullName
    FROM Appointments a
    JOIN Doctors d ON a.DoctorID = d.DoctorID
    JOIN Patients p ON a.PatientID = p.PatientID
    WHERE CONVERT(DATE, a.AppointmentDate) = CONVERT(DATE, GETDATE());
END;

go


-- Create the Job
EXEC sp_add_job 
    @job_name = N'Doctor_Daily_Schedule_Report';

-- Add a Job Step to run the stored procedure
EXEC sp_add_jobstep 
    @job_name = N'Doctor_Daily_Schedule_Report',
    @step_name = N'Log Daily Schedule',
    @subsystem = N'TSQL',
    @command = N'EXEC HospitalSystem.dbo.sp_LogDoctorDailySchedule;',
    @database_name = N'HospitalSystem';

-- Create a Schedule: every day at 7:00 AM
EXEC sp_add_schedule 
    @schedule_name = N'Daily_7AM_Schedule',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @active_start_time = 070000; -- 7:00 AM

-- Attach schedule to job
EXEC sp_attach_schedule 
    @job_name = N'Doctor_Daily_Schedule_Report',
    @schedule_name = N'Daily_7AM_Schedule';

-- Add the job to SQL Agent
EXEC sp_add_jobserver 
    @job_name = N'Doctor_Daily_Schedule_Report';


EXEC sp_LogDoctorDailySchedule;  -- test manually

SELECT * FROM DoctorDailyScheduleLog ORDER BY LoggedAt DESC;


-- /////////////// Bouns ////////////////

-- 1. Email Alert: More Than 10 Appointments Per Day
CREATE PROCEDURE sp_CheckDoctorAppointments
AS
BEGIN
    DECLARE @DoctorList NVARCHAR(MAX) = ''
    
    SELECT @DoctorList = STRING_AGG(CONCAT('DoctorID: ', DoctorID, ', Date: ', CAST(AppointmentDate AS DATE), ', Count: ', COUNT(*)), CHAR(13) + CHAR(10))
    FROM Appointments
    GROUP BY DoctorID, CAST(AppointmentDate AS DATE)
    HAVING COUNT(*) > 10;

    IF @DoctorList IS NOT NULL
    BEGIN
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'HospitalMailProfile', -- Replace with your mail profile
            @recipients = 'admin@example.com',
            @subject = 'Doctor Appointment Alert',
            @body = 'The following doctors have more than 10 appointments today:' + CHAR(13) + CHAR(10) + @DoctorList;
    END
END;
