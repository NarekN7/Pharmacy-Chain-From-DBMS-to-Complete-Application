-- Check Medication Availability +(WORKING)
SELECT Inventory.StockLevel
FROM Inventory
JOIN Medication ON Inventory.MedicationID = Medication.MedicationID
WHERE Medication.Name = 'MedicationName' AND Inventory.PharmacyID = PharmacyID;

-- Record New Medication Shipment +(WORKING)
UPDATE Inventory
SET StockLevel = StockLevel + ReceivedQuantity
WHERE PharmacyID = PharmacyID AND MedicationID = MedicationID;

-- Process a Sale Transaction +(WORKING)
CREATE OR REPLACE FUNCTION process_sale_transaction(
    IN sold_quantity INTEGER,
    IN branch_id INTEGER,
    IN medication_id INTEGER,
    IN customer_id INTEGER,
    IN employee_id INTEGER
) RETURNS VOID AS $$
DECLARE
    total_price DECIMAL(10, 2);
    customer_discount DECIMAL(5, 2);
    transaction_id INTEGER;
BEGIN
    SELECT Discount INTO customer_discount
    FROM Customer
    WHERE CustomerID = customer_id;

    UPDATE Inventory
    SET StockLevel = StockLevel - sold_quantity
    WHERE PharmacyID = branch_id AND MedicationID = medication_id;

    SELECT m.Price * sold_quantity INTO total_price
    FROM Medication m
    WHERE m.MedicationID = medication_id;

    SELECT COALESCE(MAX(TransactionID), 0) + 1 INTO transaction_id
    FROM Transaction;

    INSERT INTO Transaction (TransactionID, TotalPrice, Date, CustomerID, EmployeeID)
    VALUES (transaction_id, total_price, CURRENT_DATE, customer_id, employee_id);

    INSERT INTO TransactionDetails (TransactionDetailsID, Quantity, Discount, FinalPrice, TransactionID, MedicationID)
    VALUES (transaction_id, sold_quantity, customer_discount, total_price * (1 - customer_discount), transaction_id, medication_id);
END;
$$ LANGUAGE plpgsql;
-- SELECT process_sale_transaction(3, 1, 1, 1, 1);


-- Manage Customer Information +(WORKING)
CREATE OR REPLACE FUNCTION add_customer(
    IN customer_name VARCHAR(255),
    IN contact_info VARCHAR(255),
    IN loyalty_points INTEGER,
    IN discount DECIMAL(5, 2)
) RETURNS VOID AS $$
DECLARE
    new_customer_index INTEGER;
BEGIN
    SELECT COUNT(*) INTO new_customer_index
    FROM Customer;

    new_customer_index := new_customer_index + 1;

    INSERT INTO Customer (CustomerID, Name, ContactInfo, LoyaltyPoints, Discount)
    VALUES (new_customer_index, customer_name, contact_info, loyalty_points, discount);
END;
$$ LANGUAGE plpgsql;

-- Example
SELECT add_customer('Name' , 'Description', 50, 0.02);

UPDATE Customer
SET ContactInfo = ContactInfo,
    LoyaltyPoints = LoyaltyPoints,
    Discount = Discount
WHERE CustomerID = CustomerID;


-- Medication Reorder Notification +(WORKING)
CREATE OR REPLACE FUNCTION check_stock_level(threshold_value INTEGER, pharmacy_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    low_stock_detected BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM Inventory
        JOIN Medication ON Inventory.MedicationID = Medication.MedicationID
        WHERE Inventory.StockLevel < threshold_value AND Inventory.PharmacyID = pharmacy_id
    ) INTO low_stock_detected;

    IF low_stock_detected THEN
        RETURN 'Low level detected';
    ELSE
        RETURN 'No shortage detected';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- SELECT check_stock_level(1, 2);


-- Generate Sales Report +(WORKING)
CREATE OR REPLACE FUNCTION generate_sales_report(start_date DATE, end_date DATE)
RETURNS TABLE(transaction_date DATE, total_sales NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT Transaction.Date, SUM(TransactionDetails.FinalPrice) AS TotalSales
    FROM Transaction
    JOIN TransactionDetails ON Transaction.TransactionID = TransactionDetails.TransactionID
    WHERE Transaction.Date BETWEEN start_date AND end_date
    GROUP BY Transaction.Date
    ORDER BY Transaction.Date;
END;
$$ LANGUAGE plpgsql;

--SELECT * FROM generate_sales_report('2023-01-01', '2024-03-31');


-- Update Medication Information +(WORKING)
UPDATE Medication
SET Name = 'NewName', Price = NewPrice, Description = 'NewDescription'
WHERE MedicationID = MedicationID;

-- Return Medication to Inventory +(WORKING)
CREATE OR REPLACE FUNCTION return_medication_to_inventory(
    medication_id INTEGER,
    returned_quantity INTEGER,
    pharmacy_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    expiration_date DATE;
BEGIN
    -- Check if the medication is not expired
    SELECT ExpirationDate INTO expiration_date FROM Medication WHERE MedicationID = medication_id;

    IF expiration_date >= CURRENT_DATE THEN
        -- Update the inventory with the returned quantity
        UPDATE Inventory
        SET StockLevel = StockLevel + returned_quantity
        WHERE MedicationID = medication_id AND PharmacyID = pharmacy_id;
    ELSE
        RAISE EXCEPTION 'The medication is expired and cannot be returned to inventory.';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- SELECT return_medication_to_inventory(1, 10, 1);


-- Print Customer Receipt +(WORKING)
CREATE OR REPLACE FUNCTION print_customer_receipt(transaction_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    receipt TEXT;
    transaction_date DATE;
    customer_name TEXT;
    total_price NUMERIC;
    medication_name TEXT;
    quantity INTEGER;
    final_price NUMERIC;
    row RECORD;
BEGIN
    -- Initialize the receipt
    receipt := '--------------------' || E'\r\n';
    receipt := receipt || 'Pharmacy Receipt' || E'\r\n';
    receipt := receipt || '--------------------' || E'\r\n' || E'\r\n';

    -- Get transaction details
    SELECT
        Transaction.Date,
        Customer.Name,
        Transaction.TotalPrice
    INTO
        transaction_date,
        customer_name,
        total_price
    FROM
        Transaction
    JOIN
        Customer ON Transaction.CustomerID = Customer.CustomerID
    WHERE
        Transaction.TransactionID = transaction_id;

    -- Add transaction details to the receipt
    receipt := receipt || 'Date: ' || TO_CHAR(transaction_date, 'YYYY-MM-DD HH24:MI:SS') || E'\r\n';
    receipt := receipt || 'Customer: ' || customer_name || E'\r\n';
    receipt := receipt || 'Total Price: $' || total_price || E'\r\n' || E'\r\n';

    -- Add transaction details for each medication
    receipt := receipt || '--------------------' || E'\r\n';
    receipt := receipt || 'Medication' || E'\t' || 'Quantity' || E'\t' || 'Price' || E'\r\n';
    receipt := receipt || '--------------------' || E'\r\n';

    FOR row IN (
        SELECT
            Medication.Name,
            TransactionDetails.Quantity,
            TransactionDetails.FinalPrice
        FROM
            TransactionDetails
        JOIN
            Medication ON TransactionDetails.MedicationID = Medication.MedicationID
        WHERE
            TransactionDetails.TransactionID = transaction_id
    ) LOOP
        medication_name := row.Name;
        quantity := row.Quantity;
        final_price := row.FinalPrice;

        receipt := receipt || medication_name || E'\t' || quantity || E'\t' || final_price || E'\r\n';
    END LOOP;

    receipt := receipt || '--------------------' || E'\r\n';

    RETURN receipt;
END;
$$ LANGUAGE plpgsql;

SELECT print_customer_receipt(1);


-- Schedule Employee Shifts +(WORKING)
CREATE OR REPLACE FUNCTION update_employee_schedule(employee_id INTEGER, new_schedule TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE Employee
    SET Schedule = new_schedule
    WHERE EmployeeID = employee_id;
END;
$$ LANGUAGE plpgsql;

SELECT update_employee_schedule(1, 'NewScheduleText');


-- Track Expiring Medication +(WORKING)
CREATE OR REPLACE FUNCTION get_expiring_medications(days_until_expiration INTEGER)
RETURNS TABLE(medication_name TEXT, expiration_date DATE) AS $$
BEGIN
    RETURN QUERY SELECT
        Medication.Name::TEXT,
        Medication.ExpirationDate
    FROM
        Medication
    WHERE
        Medication.ExpirationDate BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '1 day' * days_until_expiration
    ORDER BY
        Medication.ExpirationDate ASC;
END;
$$ LANGUAGE plpgsql;

-- SELECT * FROM get_expiring_medications(300);


-- Customer Registration Operation +(WORKING)
ALTER TABLE Customer ALTER COLUMN LoyaltyPoints SET DEFAULT 0;
ALTER TABLE Customer ALTER COLUMN Discount SET DEFAULT 0;
	

CREATE OR REPLACE FUNCTION register_customer(
    customer_name VARCHAR(100),
    contact_details VARCHAR(255)
) RETURNS VOID AS $$
DECLARE
    new_customer_id INTEGER;
BEGIN
    SELECT COALESCE(MAX(CustomerID), 0) + 1 INTO new_customer_id FROM Customer;

    INSERT INTO Customer (CustomerID, Name, ContactInfo, LoyaltyPoints, Discount)
    VALUES (new_customer_id, customer_name, contact_details, 0, 0);
END;
$$ LANGUAGE plpgsql;

SELECT register_customer('Hovnatan', '023-456-789');


-- Madication Order Operation +(WORKING)
CREATE OR REPLACE FUNCTION check_medication_stock(
    medication_name VARCHAR(100),
    branch_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    stock_level INTEGER;
BEGIN
    SELECT Inventory.StockLevel INTO stock_level
    FROM Inventory
    JOIN Medication ON Inventory.MedicationID = Medication.MedicationID
    WHERE Medication.Name = medication_name AND Inventory.PharmacyID = branch_id;

    IF stock_level > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- SELECT check_medication_stock('Ibuprofen', 7);

-- Most Prescribed Medication Report +(WORKING)
SELECT Medication.Name, COUNT(TransactionDetails.MedicationID) AS NumberOfTimesPrescribed
FROM TransactionDetails
JOIN Medication ON TransactionDetails.MedicationID = Medication.MedicationID
JOIN Transaction ON TransactionDetails.TransactionID = Transaction.TransactionID
WHERE Transaction.Date BETWEEN '2023-01-01' and '2024-12-31'
GROUP BY Medication.Name
ORDER BY NumberOfTimesPrescribed DESC;

-- Customer Loyalty Points Ranking +(WORKING)
SELECT Name, LoyaltyPoints
FROM Customer
ORDER BY LoyaltyPoints DESC;

-- Revenue Report by Medication Type +(WORKING)
SELECT Medication.Name, SUM(TransactionDetails.FinalPrice) AS TotalRevenue
FROM TransactionDetails
JOIN Medication ON TransactionDetails.MedicationID = Medication.MedicationID
GROUP BY Medication.Name;

-- Employee Performance Evaluation +(WORKING)
SELECT Employee.Name, COUNT(Transaction.EmployeeID) AS NumberOfTransactions, SUM(Transaction.TotalPrice) AS TotalTransactionValue
FROM Transaction
JOIN Employee ON Transaction.EmployeeID = Employee.EmployeeID
GROUP BY Employee.Name;

-- Expired Medication Report +(Working)
SELECT Medication.Name, Medication.ExpirationDate
FROM Medication
WHERE ExpirationDate BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '1 month';

-- Medication Restocking Operation +(WORKING)
CREATE OR REPLACE FUNCTION check_medication_restocking() RETURNS TABLE(
    medication_name VARCHAR(100),
    current_stock INTEGER,
    minimum_threshold INTEGER
) AS $$
DECLARE
    min_threshold INTEGER;
BEGIN
    -- Set the minimum inventory threshold for restocking alerts
    min_threshold := 8;

    RETURN QUERY
    SELECT
        Medication.Name,
        Inventory.StockLevel,
        min_threshold
    FROM
        Medication
        JOIN Inventory ON Medication.MedicationID = Inventory.MedicationID
    WHERE
        Inventory.StockLevel < min_threshold;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM check_medication_restocking();

-- Stock Level Assessment
-- Balancing Medication Quantities Between Branches
SELECT PharmacyID, MedicationID, StockLevel
FROM Inventory
WHERE (StockLevel > 30 OR StockLevel < 5);

SELECT
    i1.PharmacyID AS SourcePharmacyID,
    i2.PharmacyID AS DestinationPharmacyID,
    i1.MedicationID,
    i1.StockLevel AS SourceStock,
    i2.StockLevel AS DestinationStock
FROM
    Inventory i1
JOIN
    Inventory i2 ON i1.MedicationID = i2.MedicationID
WHERE
    i1.StockLevel > 30 OR
    i2.StockLevel < 4 AND
    i1.PharmacyID != i2.PharmacyID;
    
-- Transfer Initiation   
INSERT INTO InventoryTransfer (Quantity, TransferDate, MedicationID, SourcePharmacyID, DestPharmacyID)
VALUES (20, CURRENT_DATE, 2, 1, 2);

--Transfer Execution
-- Reduce stock at the source pharmacy
UPDATE Inventory
SET StockLevel = StockLevel - 20
WHERE PharmacyID = 1 AND MedicationID = 2;

-- Increase stock at the destination pharmacy
UPDATE Inventory
SET StockLevel = StockLevel + 20
WHERE PharmacyID = 2 AND MedicationID = 2;

-- Transfer Confirmation: Check details of the transfer
SELECT * FROM InventoryTransfer
WHERE MedicationID = 2 AND SourcePharmacyID = 1 AND DestPharmacyID = 2;





