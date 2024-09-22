-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

WITH vendor_products AS
	(
	SELECT vi.vendor_id,v.vendor_name, vi.product_id,p.product_name, MAX(vi.original_price) AS price
	FROM vendor_inventory vi
	JOIN vendor v ON vi.vendor_id = v.vendor_id
	JOIN product p ON vi.product_id = p.product_id
	GROUP BY vi.product_id
	ORDER BY vi.vendor_id
	)
	
SELECT vendor_name,product_name,SUM(price*5) AS total 
FROM vendor_products
CROSS JOIN customer
GROUP BY vendor_name, product_name;

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;

CREATE TABLE product_units AS
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

--For inserting a new row in the product_units table with product name 'Apple Pie', and current timestamp. Also assumed that product_id 50 is available
INSERT INTO product_units (
    product_id, 
    product_name, 
    product_size, 
    product_category_id, 
    product_qty_type, 
    snapshot_timestamp
)
VALUES (50,'Apple Pie','10"',3,'unit',CURRENT_TIMESTAMP);


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE product_name = 'Apple Pie'
AND snapshot_timestamp = (
		SELECT MIN(snapshot_timestamp) FROM product_units 
		WHERE product_name = 'Apple Pie'); 
-- MIN(snapshot_timestamp) will return the earliest timestamp


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


--Last known quantity in vendor_invertory, grouped by vendor & product
WITH inventory_last_quantity AS
	(
		SELECT MAX(market_date), product_id, quantity  FROM vendor_inventory
		GROUP BY vendor_id, product_id ORDER BY product_id
	),
	updated_qty AS
	(
		SELECT p.product_id, COALESCE(i.quantity,0.0) AS qty
		FROM inventory_last_quantity i
		Right JOIN  product p ON i.product_id = p.product_id		
	)
--Update the quantities in the above query

--Final query to update product_units
UPDATE product_units
SET current_quantity = (SELECT qty FROM updated_qty uq  WHERE product_units.product_id = uq.product_id);

