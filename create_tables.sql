DROP TABLE IF EXISTS TransactionDetails, Transaction, OrderDetails, Orders, InventoryTransfer, Inventory, Medication, Employee, Customer, Supplier, Pharmacy, Locations CASCADE;

CREATE TABLE Locations (
    LocationID SERIAL PRIMARY KEY,
    Address VARCHAR(255),
    Region VARCHAR(100),
    PostalCode VARCHAR(10)
);

CREATE TABLE Pharmacy (
    PharmacyID SERIAL PRIMARY KEY,
    Phone VARCHAR(15),
    OpeningHours TIME,
    ClosingHours TIME,
    LicenseNumber VARCHAR(50),
    LocationID INT,
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID)
);

CREATE TABLE Employee (
    EmployeeID SERIAL PRIMARY KEY,
    Name VARCHAR(100),
    Position VARCHAR(100),
    Schedule TEXT,
    PhoneNumber VARCHAR(15),
    HireDate DATE,
    Email VARCHAR(100),
    PharmacyID INT,
    FOREIGN KEY (PharmacyID) REFERENCES Pharmacy(PharmacyID)
);

CREATE TABLE Supplier (
    SupplierID SERIAL PRIMARY KEY,
    CompanyName VARCHAR(100),
    ContactNumber VARCHAR(15),
    Email VARCHAR(100),
    ContactName VARCHAR(100),
    Address VARCHAR(255)
);

CREATE TABLE Medication (
    MedicationID SERIAL PRIMARY KEY,
    Name VARCHAR(100),
    Description TEXT,
    ExpirationDate DATE,
    Price DECIMAL(10,1),
    ProductionDate DATE,
    Country VARCHAR(100)
);

CREATE TABLE Inventory (
    StockLevel INT,
    PharmacyID INT,
    MedicationID  INT,
    FOREIGN KEY (PharmacyID) REFERENCES Pharmacy(PharmacyID)
);

CREATE TABLE Customer (
    CustomerID SERIAL PRIMARY KEY,
    Name VARCHAR(100),
    ContactInfo VARCHAR(100),
    LoyaltyPoints INT,
    Discount DECIMAL(5,2)
);

CREATE TABLE Orders (
    OrderID SERIAL PRIMARY KEY,
    Date DATE,
    OrderStatus VARCHAR(50),
    EstimatedDeliveryDate DATE,
    SupplierID INT,
    FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

CREATE TABLE OrderDetails (
    OrderDetailsID SERIAL PRIMARY KEY,
    Quantity INT,
    Price DECIMAL(10,2),
    OrderID INT,
    MedicationID INT,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (MedicationID) REFERENCES Medication(MedicationID)
);

CREATE TABLE Transaction (
    TransactionID SERIAL PRIMARY KEY,
    TotalPrice DECIMAL(10,2),
    Date DATE,
    CustomerID INT,
    EmployeeID INT,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

CREATE TABLE TransactionDetails (
    TransactionDetailsID SERIAL PRIMARY KEY,
    Quantity INT,
    Discount DECIMAL(5,2),
    FinalPrice DECIMAL(10,2),
    TransactionID INT,
    MedicationID INT,
    FOREIGN KEY (TransactionID) REFERENCES Transaction(TransactionID),
    FOREIGN KEY (MedicationID) REFERENCES Medication(MedicationID)
);

CREATE TABLE InventoryTransfer (
    TransferID SERIAL PRIMARY KEY,
    Quantity INT,
    TransferDate DATE,
    MedicationID INT,
    SourcePharmacyID INT,
    DestPharmacyID INT,
    FOREIGN KEY (MedicationID) REFERENCES Medication(MedicationID),
    FOREIGN KEY (SourcePharmacyID) REFERENCES Pharmacy(PharmacyID),
    FOREIGN KEY (DestPharmacyID) REFERENCES Pharmacy(PharmacyID)
);