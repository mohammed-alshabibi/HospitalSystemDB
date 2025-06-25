# 📘 Hospital Management System SQL Project

## 📋 Project Overview

A full-featured SQL Server-based Hospital Management System project designed to manage healthcare operations using relational database concepts, procedural SQL, and administrative tools.

GitHub Repository: [HospitalSystemDB](https://github.com/mohammed-alshabibi/HospitalSystemDB)

---

## 🔶 1. ERD & Schema Mapping

* Designed and cleaned an Entity Relationship Diagram using draw\.io.
* Mapped entities: `Patients`, `Doctors`, `Departments`, `Staff`, `Appointments`, `Admissions`, `Rooms`, `MedicalRecords`, `Billing`, `Users`.
* Created relational schema with foreign key constraints.

## 🏗️ 2. Table Creation with Constraints

* Implemented normalized tables using:

  * ✅ Primary keys and foreign keys
  * ✅ CHECK constraints, IDENTITY columns, and UNIQUE keys
* Linked `Doctors` to `Departments` via `DepartmentID` FK.
* Extended `Users` table with `DoctorID` and `StaffID` FKs.

## 🧪 3. Sample Data

* Inserted 20+ sample rows per table.
* Arabic names written in English (e.g., `Salim Al Farsi`, `Layla Al Hinai`).
* Ensured referential integrity for FK relationships.

## 📊 4. Query Examples

* ✅ List all patients who visited a specific doctor.
* ✅ Count of appointments per department.
* ✅ Retrieve doctors with >5 appointments in a month.
* ✅ Used `JOIN`, `GROUP BY`, `HAVING`, subqueries, and `EXISTS`.

## ⚙️ 5. Stored Procedures & Functions

* `fn_CalculateAge`: Calculates patient age from DOB.
* `sp_AdmitPatient`: Admits a patient, updates room status.
* `sp_GenerateInvoice`: Creates billing record from treatment.
* `sp_AssignDoctorToDept`: Assigns doctor to department (with FK).

## 🔁 6. Triggers

* 🔄 `AFTER INSERT` on `Appointments` → logs record to `MedicalRecords`.
* 🚫 `INSTEAD OF DELETE` on `Patients` → prevents deletion if pending bills exist.
* 🛏️ `AFTER UPDATE` on `Rooms` → ensures room isn't double-assigned.

## 🔐 7. Security (DCL)

* Roles: `DoctorUser`, `AdminUser`
* GRANT SELECT on `Patients` and `Appointments` to `DoctorUser`
* GRANT INSERT, UPDATE on all tables to `AdminUser`
* REVOKE DELETE on `Doctors`

## 🔄 8. Transactions (TCL)

* Admitting a patient inside a transaction:

  * Insert into `Admissions`
  * Update `Rooms` availability
  * Insert into `Billing`
  * `TRY...CATCH` with `COMMIT` or `ROLLBACK`

## 🔎 9. Views

* `vw_DoctorSchedule`: Lists upcoming appointments per doctor
* `vw_PatientSummary`: Shows latest visit info for each patient
* `vw_DepartmentStats`: Count of doctors and patients per department

## ⏱️ 10. SQL Server Agent Jobs

### Doctor Daily Schedule Report

* Job Name: `Doctor_Daily_Schedule_Report`
* Time: 7:00 AM daily
* Procedure logs appointments to `DoctorDailyScheduleLog`

---

## 🏆 Bonus Features

### 📧 Email Alert if Doctor Has >10 Appointments/Day

* Stored procedure `sp_CheckDoctorAppointments`
* Uses `sp_send_dbmail` to send email
* Scheduled SQL Agent Job: `Doctor_Alert_Email_Job`

### 📤 Weekly Billing Export to CSV

* Uses `bcp` utility:

```bash
bcp "SELECT * FROM HospitalSystem.dbo.Billing" queryout "C:\Exports\Billing_Weekly.csv" -c -t, -T -S DESKTOP-LGMU6P8
```

* SQL Agent job scheduled weekly

---

## 🖼️ Screenshots Directory

**Located in** `/screenshots/`:

* ERD and schema mapping
* SQL scripts and triggers
* Procedure logic
* SQL Server Agent setup
* Email alert logs and CSV output preview

---


