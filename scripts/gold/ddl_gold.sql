
-- Objective: Write a SQL query to create the Silver Layer and  retrieve customer details including customer ID, key, first name, last name, marital status
/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

create view gold.dim_Customers as
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_material_status AS marital_status,
	CASE WHEN cst_gndr!='N/A' THEN cst_gndr
		 ELSE COALESCE(az12.gen,'n/a')
	END Gender,
	az12.bdate AS birth_date,
	ci.cst_create_date AS create_date,
	a101.cntry AS country
FROM SILVER.crm_cust_info ci
LEFT JOIN SILVEr.erp_cust_az12 az12
ON az12.cid = ci.cst_key
LEFT JOIN SILVER.erp_loc_a101 a101
on a101.cid = ci.cst_key

select * from gold.dim_Customers;

--crate view gold.dim_Customers from silver.crm_cust_info and silver.erp_px_cat_g1v2
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

create view gold.dim_Products as
select
	ROW_NUMBER() OVER (ORDER BY cp.prd_start_dt,cp.prd_key) AS product_key,
	cp.prd_id as prodcut_id,
	cp.prd_key as product_number,
	cp.prd_nm as product_name,
	cp.cat_id as category_id,
	pg.cat as category,
	pg.subcat as subcategory,
	cp.prd_cost as cost,
	cp.prd_line as product_line,
	cp.prd_start_dt as start_date,
	pg.maintenance
from silver.crm_cust_prd_info cp
left join silver.erp_px_cat_g1v2 pg
	on cp.cat_id = pg.id
where prd_end_dt is null;

select * from gold.dim_Products;

--created fact table in gold layer from silver.crm_sales_details, gold.dim_Customers and gold.dim_Products
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

create view gold.fact_Sales as
select
	sd.sls_ord_num as order_number,
	dc.customer_key,
	dp.product_key,
	sd.sls_prd_key as order_key,
	sls_order_dt as order_date,
	sls_ship_dt as ship_date,
	sls_due_dt as due_date,
	sls_sales as sales,
	sls_quantity as quantity,
	sls_price as price
from silver.crm_sales_details sd
left join gold.dim_Customers dc
	on sd.sls_cust_id = dc.customer_id
left join gold.dim_Products dp
	on sd.sls_prd_key = dp.product_number;


select * from gold.fact_Sales fs
inner join gold.dim_Customers dc
	on fs.customer_key = dc.customer_key
inner join gold.dim_Products dp
	on fs.product_key = dp.product_key;

