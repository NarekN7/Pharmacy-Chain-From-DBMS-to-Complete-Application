-- Check Medication AvailabilitySELECT Inventory.StockLevel
FROM InventoryJOIN Medication ON Inventory.MedicationID = Medication.MedicationID
WHERE Medication.Name = 'Aspirin' AND Inventory.PharmacyID = 1;

-- Record New Medication ShipmentUPDATE Inventory
SET StockLevel = StockLevel + InventoryTransfer.Quantity FROM InventoryTransferWHERE PharmacyID = 2 AND InventoryTransfer.MedicationID = Inventory.MedicationID;

-- Process a Sale Transaction
UPDATE InventorySET StockLevel = StockLevel - InventoryTransfer.Quantity FROM InventoryTransfer
WHERE PharmacyID = 5 AND InventoryTransfer.MedicationID = Inventory.MedicationID;
INSERT INTO Transaction (TotalPrice, Date, CustomerID, EmployeeID)VALUES (200, '2024-03-28', 25, 5);
INSERT INTO TransactionDetails (Quantity, Discount, FinalPrice, TransactionID, MedicationID)
VALUES (5, 0.07, 2555.6, 125, 6);
UPDATE Customer
SET Name = 'Avetiq', ContactInfo = '+37499858907'WHERE CustomerID = 42;

-- Medication Reorder NotificationSELECT Medication.Name, Inventory.StockLevel
FROM InventoryJOIN Medication ON Inventory.MedicationID = Medication.MedicationID
WHERE Inventory.StockLevel < 40 AND Inventory.PharmacyID = 5;

-- Generate Sales Report
SELECT Transaction.Date, SUM(TransactionDetails.FinalPrice) AS TotalSales
FROM Transaction
JOIN TransactionDetails ON Transaction.TransactionID = TransactionDetails.TransactionID
WHERE Transaction.Date BETWEEN '2023-07-18' AND '2024-03-28'
GROUP BY Transaction.Date;

-- Update Medication InformationUPDATE Medication
SET Name = 'Nurofen', Price = 534.1, Description = 'Painkiller and from high teperature, for adults'WHERE MedicationID = 24;

-- Print Customer Receipt
SELECT Medication.Name, TransactionDetails.Quantity, TransactionDetails.FinalPrice
FROM TransactionDetails
JOIN Medication ON TransactionDetails.MedicationID = Medication.MedicationID
WHERE TransactionDetails.TransactionID = 12;

-- Schedule Employee ShiftsUPDATE Employee
SET Schedule = 'Mon Wen Tue 00:00-09:00'
WHERE EmployeeID = 13;

-- Most Prescribed Medication Report for December 2023
SELECT Medication.Name, COUNT(TransactionDetails.MedicationID) AS NumberOfTimesPrescribed
FROM TransactionDetails
JOIN Medication ON TransactionDetails.MedicationID = Medication.MedicationID
JOIN Transaction ON Transaction.TransactionID = TransactionDetails.TransactionID
WHERE Transaction.Date BETWEEN '2023-12-01' AND '2023-12-31'
GROUP BY Medication.Name
ORDER BY NumberOfTimesPrescribed DESC;

-- Customer Loyalty Points Ranking
SELECT Name, LoyaltyPoints
FROM Customer
ORDER BY LoyaltyPoints DESC;

-- Revenue Report by Medication Type for 2023
SELECT Medication.Name, SUM(TransactionDetails.FinalPrice) AS TotalRevenue
FROM TransactionDetails
JOIN Medication ON TransactionDetails.MedicationID = Medication.MedicationID
GROUP BY Medication.Name;

-- Employee Performance Evaluation for Employee ID 5
SELECT Employee.Name, COUNT(Transaction.EmployeeID) AS NumberOfTransactions, SUM(Transaction.TotalPrice) AS TotalTransactionValue
FROM Transaction
JOIN Employee ON Transaction.EmployeeID = Employee.EmployeeID
WHERE Employee.EmployeeID = 5
GROUP BY Employee.Name;

-- Expired Medication Report: List all medications expiring next month
SELECT Medication.Name, Medication.ExpirationDate
FROM Medication
WHERE ExpirationDate BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '1 month';

-- Medication Restocking Operation: Alert for low stock of 'Aspirin' at Pharmacy 1
SELECT Medication.Name, Inventory.StockLevel
FROM Inventory
JOIN Medication ON Inventory.MedicationID = Medication.MedicationID
WHERE Inventory.StockLevel < 10 AND Inventory.PharmacyID = 1;

-- Balancing Medication Quantities Between Branches: Example for transferring 'Aspirin' from Pharmacy 1 to Pharmacy 2
-- Stock Level Assessment
SELECT PharmacyID, MedicationID, StockLevel
FROM Inventory
WHERE MedicationID = 2 AND (StockLevel > 50 OR StockLevel < 5);

-- Transfer Initiation from Pharmacy 1 to Pharmacy 2 for 20 units of 'Aspirin'
INSERT INTO InventoryTransfer (Quantity, TransferDate, MedicationID, SourcePharmacyID, DestPharmacyID)
VALUES (20, CURRENT_DATE, 101, 1, 2);

-- Stock Transfer Execution: Reduce stock at source Pharmacy 1
UPDATE Inventory
SET StockLevel = StockLevel - 20
WHERE PharmacyID = 1 AND MedicationID = 11;

-- Increase stock at destination Pharmacy 2
UPDATE Inventory
SET StockLevel = StockLevel + 20
WHERE PharmacyID = 2 AND MedicationID = 11;

-- Transfer Confirmation: Check details of the transfer
SELECT * FROM InventoryTransfer
WHERE MedicationID = 11 AND SourcePharmacyID = 1 AND DestPharmacyID = 2;