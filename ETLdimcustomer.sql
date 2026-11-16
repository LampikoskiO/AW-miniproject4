-- Use the RentalDB database for the customer dimension ETL process.
use RentalDB;

-- Load only new customer records into the customer dimension.
-- This prevents duplicate rows by checking whether the source customer_id already exists.
INSERT INTO DimCustomer
(
    customer_id,
    first_name,
    last_name,
    address,
    email,
    phone_number,
    city,
    country
)
SELECT
    cr.customer_id,
    cr.first_name,
    cr.last_name,
    cr.address,
    cr.email,
    cr.phone_number,
    cr.city,
    COALESCE(cr.country, 'Unknown')
FROM RentalDB.dbo.Customer AS cr
WHERE NOT EXISTS
(
    SELECT 1
    FROM DimCustomer AS c
    WHERE c.customer_id = cr.customer_id
);

-- Display the current contents of the customer dimension for verification.
SELECT * from dimcustomer