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

SELECT * from dimcustomer