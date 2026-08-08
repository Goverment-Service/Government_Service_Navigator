# Quick Start & Database Setup Guide

Follow these steps to navigate to the backend service, apply EF Core migrations, and run the project.

---

## 1. Navigate to Project Directory

Change your working directory to the backend source folder [cite: 1]:

```bash
cd backend/src
```

---

## 2. Run the Application

Start the .NET application [cite: 1]:

```bash
dotnet run
```

---

## 3. Create and Apply Database Migration

Create the database table migration for the admin table [cite: 1]:

```bash
dotnet ef migrations add Add<Add your table name>
```

Apply the migration to update the database [cite: 1]:

```bash
dotnet ef database update
```

---

## 4. Run the Application Post-Migration

Start the application again after applying the database changes [cite: 1]:

```bash
dotnet run
```
