create database HospitalSystem;

use HospitalSystem;

CREATE TABLE Patients (
    PatientID INT CONSTRAINT PK_Patients PRIMARY KEY ,
    FullName VARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    Gender CHAR(1) CONSTRAINT CHK_Patients_Gender CHECK (Gender IN ('M','F')),
    ContactInfo VARCHAR(100)
);

CREATE TABLE Doctors (
    DoctorID INT CONSTRAINT PK_Doctors PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Specialization VARCHAR(50),
    ContactInfo VARCHAR(100),
    DepartmentID INT,
    CONSTRAINT FK_Doctors_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);


CREATE TABLE Departments (
    DepartmentID INT CONSTRAINT PK_Departments PRIMARY KEY ,
    DeptName VARCHAR(50) CONSTRAINT UQ_Departments_DeptName UNIQUE NOT NULL
);

CREATE TABLE Staff (
    StaffID INT CONSTRAINT PK_Staff PRIMARY KEY ,
    FullName VARCHAR(100),
    Role VARCHAR(50),
    Shift VARCHAR(20),
    AssignedDeptID INT,
    CONSTRAINT FK_Staff_Departments FOREIGN KEY (AssignedDeptID) REFERENCES Departments(DepartmentID)
);

CREATE TABLE Appointments (
    AppointmentID INT CONSTRAINT PK_Appointments PRIMARY KEY IDENTITY,
    PatientID INT,
    DoctorID INT,
    AppointmentDate DATETIME NOT NULL,
    CONSTRAINT FK_Appointments_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    CONSTRAINT FK_Appointments_Doctors FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID)
);

CREATE TABLE Admissions (
    AdmissionID INT CONSTRAINT PK_Admissions PRIMARY KEY IDENTITY,
    PatientID INT,
    RoomNumber INT,
    DateIn DATE,
    DateOut DATE,
    CONSTRAINT FK_Admissions_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    CONSTRAINT FK_Admissions_Rooms FOREIGN KEY (RoomNumber) REFERENCES Rooms(RoomNumber)
);

CREATE TABLE Rooms (
    RoomNumber INT CONSTRAINT PK_Rooms PRIMARY KEY,
    RoomType VARCHAR(20),
    IsAvailable BIT DEFAULT 1
);

CREATE TABLE MedicalRecords (
    RecordID INT CONSTRAINT PK_MedicalRecords PRIMARY KEY IDENTITY,
    PatientID INT,
    DoctorID INT,
    Diagnosis VARCHAR(255),
    TreatmentPlan VARCHAR(255),
    VisitDate DATE,
    CONSTRAINT FK_MedicalRecords_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    CONSTRAINT FK_MedicalRecords_Doctors FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID)
);

CREATE TABLE Billing (
    BillID INT CONSTRAINT PK_Billing PRIMARY KEY IDENTITY,
    PatientID INT,
    TotalCost DECIMAL(10,2),
    Services VARCHAR(255),
    BillDate DATE,
    CONSTRAINT FK_Billing_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);

CREATE TABLE Users (
    Username VARCHAR(50) CONSTRAINT PK_Users PRIMARY KEY,
    PasswordHash VARCHAR(255),
    Role VARCHAR(50),
    DoctorID INT NULL,
    StaffID INT NULL,
    CONSTRAINT FK_Users_Doctors FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
    CONSTRAINT FK_Users_Staff FOREIGN KEY (StaffID) REFERENCES Staff(StaffID)
);

