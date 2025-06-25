--//////////////////// Queries to Test (DQL) ////////////////////////////
-- ist all patients who visited a certain doctor, based on the Appointments table
SELECT 
    P.PatientID,
    P.FullName,
    P.ContactInfo,
    A.AppointmentDate,
    D.FullName AS DoctorName
FROM 
    Appointments A
JOIN 
    Patients P ON A.PatientID = P.PatientID
JOIN 
    Doctors D ON A.DoctorID = D.DoctorID
WHERE 
    D.DoctorID = 200; -- Change this ID to the doctor you want to filter

--Count of Appointments Per Department (by Specialization)
SELECT 
    Doc.Specialization AS Department,
    COUNT(A.AppointmentID) AS AppointmentCount
FROM 
    Appointments A
JOIN 
    Doctors Doc ON A.DoctorID = Doc.DoctorID
GROUP BY 
    Doc.Specialization;


-- retrieve doctors who have more than 5 appointments in a month
SELECT 
    D.DoctorID,
    D.FullName,
    D.Specialization,
    COUNT(A.AppointmentID) AS AppointmentCount,
    MONTH(A.AppointmentDate) AS Month,
    YEAR(A.AppointmentDate) AS Year
FROM 
    Appointments A
JOIN 
    Doctors D ON A.DoctorID = D.DoctorID
GROUP BY 
    D.DoctorID, D.FullName, D.Specialization, MONTH(A.AppointmentDate), YEAR(A.AppointmentDate)
HAVING 
    COUNT(A.AppointmentID) > 0;-- there are no doctor that have greater than one appointments


-- JOINs across 3 existing tables (Appointments, Patients, and Doctors)
SELECT 
    A.AppointmentID,
    A.AppointmentDate,
    P.FullName AS PatientName,
    D.FullName AS DoctorName,
    D.Specialization As DoctorSpecialization
FROM 
    Appointments A
JOIN 
    Patients P ON A.PatientID = P.PatientID
JOIN 
    Doctors D ON A.DoctorID = D.DoctorID
ORDER BY 
    A.AppointmentDate DESC;


-- Count Appointments Per Doctor (only if more than 1) using Group by, having and aggregation
	SELECT 
    D.DoctorID,
    D.FullName as DocrotName,
    COUNT(A.AppointmentID) AS TotalAppointments
FROM 
    Appointments A
JOIN 
    Doctors D ON A.DoctorID = D.DoctorID
GROUP BY 
    D.DoctorID, D.FullName
HAVING 
    COUNT(A.AppointmentID) > 1;

	--Using a SUBQUERY
	SELECT 
    FullName, PatientID
FROM 
    Patients
WHERE 
    PatientID IN (
        SELECT 
            PatientID
        FROM 
            Appointments
        GROUP BY 
            PatientID
        HAVING 
            COUNT(AppointmentID) > 1
    );

-- Using EXISTS
SELECT 
    DoctorID, FullName, Specialization
FROM 
    Doctors D
WHERE 
    EXISTS (
        SELECT 1 
        FROM Appointments A 
        WHERE A.DoctorID = D.DoctorID
    );

-- ///////////////////////// Functions & Stored Procedures /////////////////////

-- 1. Scalar Function: Calculate age from DOB
CREATE FUNCTION dbo.fn_CalculateAge (@DOB DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @DOB, GETDATE()) - 
           CASE WHEN MONTH(@DOB) > MONTH(GETDATE()) 
                 OR (MONTH(@DOB) = MONTH(GETDATE()) AND DAY(@DOB) > DAY(GETDATE()))
                THEN 1 ELSE 0 END
END;
GO


-- 2. Procedure to admit a patient (insert into Admissions, update room availability)
CREATE PROCEDURE sp_AdmitPatient
    @PatientID INT,
    @RoomNumber INT,
    @DateIn DATE,
    @DateOut DATE
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO Admissions (PatientID, RoomNumber, DateIn, DateOut)
        VALUES (@PatientID, @RoomNumber, @DateIn, @DateOut);

        UPDATE Rooms
        SET IsAvailable = 0
        WHERE RoomNumber = @RoomNumber;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO


-- 3. Procedure to generate invoice (insert into Billing)
CREATE PROCEDURE sp_GenerateInvoice
    @PatientID INT,
    @TotalCost DECIMAL(10,2),
    @Services VARCHAR(255)
AS
BEGIN
    INSERT INTO Billing (PatientID, TotalCost, Services, BillDate)
    VALUES (@PatientID, @TotalCost, @Services, GETDATE());
END;
GO


-- 4. Procedure to assign doctor to a department and shift


CREATE PROCEDURE sp_AssignDoctorToDept
    @DoctorID INT,
    @DepartmentID INT
AS
BEGIN
    UPDATE Doctors
    SET DepartmentID = @DepartmentID
    WHERE DoctorID = @DoctorID;
END;
GO


