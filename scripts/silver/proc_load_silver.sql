/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_data 
AS
BEGIN
DECLARE @start_time datetime,@end_time datetime, @batch_start_time datetime, @batch_end_time datetime
    BEGIN TRY
        PRINT'===========================';
        PRINT 'lOADING SILVER LAYER';
        PRINT'===========================';

        PRINT'---------------------------';
        PRINT'LOADING CRM TABLE';
        PRINT'---------------------------';
        -- removing duplicate cst_id AND inserting the data in silver.crm_cust_info
    
        SET @batch_start_time=GETDATE();

        PRINT'>>Truncating the table bronze.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info

        SET @start_time=GETDATE();
        PRINT'>> Inserting data into: silver.crm_cust_info '
        INSERT INTO silver.crm_cust_info
        (   
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_material_status,
            cst_gndr,
            cst_create_date
        )
        SELECT cst_id,
               cst_key,
               Trim(cst_firstname) AS cst_firstname,
               Trim(cst_lastname)  AS cst_lastname,
               CASE
                 WHEN Upper(Trim(cst_gndr)) = 'M' THEN 'Married'
                 WHEN Upper(Trim(cst_gndr)) = 'F' THEN 'Single'
                 ELSE 'N/A' -- 
               END                 AS cst_material_status,     --- Normalize the Material Status data to readable format
               CASE
                 WHEN Upper(Trim(cst_gndr)) = 'M' THEN 'Male'
                 WHEN Upper(Trim(cst_gndr)) = 'F' THEN 'Female'
                 ELSE 'N/A'
               END                 AS cst_gndr,                --- Normalize the gender data to readable format
               cst_create_date
        FROM   (SELECT *,
                       Row_number()
                         OVER (
                           partition BY cst_id
                           ORDER BY cst_create_date) AS Flag
                FROM   bronze.crm_cust_info
                WHERE cst_id is not null)t
        WHERE  flag = 1                         -- select most recent recod per customer
        SET @end_time=GETDATE();
            PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
            PRINT'------------------------------------------------------'

        --Cleaning and Inserting the silver.crm_cust_prd_info

        TRUNCATE TABLE silver.crm_cust_info
        PRINT'>> Inserting data into: silver.crm_cust_prd_info '
        SET @start_time=GETDATE();
        insert into silver.crm_cust_prd_info
        ( 
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        select 
            prd_id,
            REPLACE((SUBSTRING(prd_key,1,5)),'-','_') AS cat_id,
            SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key,
            prd_nm,
            coalesce(prd_cost,0) as prd_cost,
            CASE
                    WHEN Upper(Trim(prd_line)) = 'M' THEN 'Mountain'
                    WHEN Upper(Trim(prd_line)) = 'S' THEN 'Other Sales'
                    WHEN Upper(Trim(prd_line)) = 'R' THEN 'Road'
                    WHEN Upper(Trim(prd_line)) = 'T' THEN 'Touring'
                    ELSE 'N/A'
            END  as prd_line,
            CAST(prd_start_dt AS DATE) as prd_start_dt ,
            CAST(DATEADD(DAY,-1,LEAD(prd_start_dt) over(partition by prd_key order by prd_id))AS DATE) as prd_end_dt
        from bronze.crm_cust_prd_info
        SET @end_time=GETDATE();
            PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
            PRINT'------------------------------------------------------'


        --Cleaning and Inserting the silver_srm_sales_details

        TRUNCATE TABLE silver.crm_cust_info
        PRINT'>> Inserting data into: silver.crm_sales_details '
        SET @start_time=GETDATE();
        INSERT INTO silver.crm_sales_details
        (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        select 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE
                WHEN sls_order_dt<=0 OR LEN(sls_order_dt)!=8 THEN  NULL
                ELSE CAST(CAST(sls_order_dt AS nvarchar) AS DATE)
            END AS sls_order_dt,

            CASE
                WHEN sls_ship_dt<=0 OR LEN(sls_ship_dt)!=8 THEN  NULL
                ELSE CAST(CAST(sls_ship_dt AS nvarchar) AS DATE)
            END AS sls_ship_dt,

            CASE
                WHEN sls_due_dt<=0 OR LEN(sls_due_dt)!=8 THEN  NULL
                ELSE CAST(CAST(sls_due_dt AS nvarchar) AS DATE)
            END AS sls_due_dt,

            CASE WHEN sls_sales IS NULL OR sls_sales<=0 or sls_sales!=sls_quantity * ABS(sls_price)
				        THEN sls_quantity * ABS(sls_price)
				        ELSE sls_sales
		         END sls_sales,
            sls_quantity,

            CASE WHEN sls_price is null or sls_price<=0 
				        THEN sls_sales / NULLIF(sls_quantity, 0)
			         ELSE sls_price
		         END sls_price
        from bronze.crm_sales_details
        SET @end_time=GETDATE();
            PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
            PRINT'------------------------------------------------------'


        PRINT'---------------------------'
        PRINT'LOADING ERP LAYER';
        PRINT'---------------------------'

        --Cleaning and Inserting the data in silver.erp_cust_az12

        TRUNCATE TABLE silver.crm_cust_info
        PRINT'>> Inserting data into: silver.erp_cust_az12'

        SET @start_time=GETDATE();
        INSERT INTO silver.erp_cust_az12 
        (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE WHEN cid like 'NAS%' 
                 THEN SUBSTRING(cid,4,LEN(cid))
                 ELSE cid
            end cid,
            CASE WHEN bdate<'1924-01-01' OR bdate>GETDATE() 
                 THEN NULL
                 ELSE bdate
            END bdate,
            CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
                 WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
                 ELSE 'n/a'
            END gen
        from
        bronze.erp_cust_az12
        SET @end_time=GETDATE();
            PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
            PRINT'------------------------------------------------------'

        --Creating , Inserting and Cleaning the data in silver.erp_loc_a101

        TRUNCATE TABLE silver.crm_cust_info
        PRINT'>> Inserting data into: silver.erp_loc_a101 '

        SET @start_time=GETDATE();
        INSERT INTO silver.erp_loc_a101
        ( 
            cid,
            cntry
        )
        select
            REPLACE(cid,'-','') as cid,
            CASE WHEN UPPER (TRIM(cntry)) IN ('USA','US') THEN 'United States'
                 WHEN UPPER(TRIM(cntry)) IN ('DE') THEN 'Germany'
                 WHEN cntry IS NULL OR cntry='' THEN 'N/A'
                 ELSE cntry
            END cntry
        from bronze.erp_loc_a101
        SET @end_time=GETDATE();
            PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
            PRINT'------------------------------------------------------'


        --Inserting and Cleaning the data in silver.erp_loc_a101

        TRUNCATE TABLE silver.crm_cust_info
        PRINT'>> Inserting data into: silver.erp_px_cat_g1v2 '

        SET @start_time=GETDATE();
        INSERT INTO silver.erp_px_cat_g1v2
        (
            id,
            cat,
            subcat,
            maintenance
        )
        select 
            id,
            cat,
            subcat,
            maintenance
        from bronze.erp_px_cat_g1v2
        SET @end_time=GETDATE();
            PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
            PRINT'------------------------------------------------------'

        SET @batch_end_time=GETDATE();

        PRINT'=====================================';
        PRINT'LOADING BRONZE LAYER IS COMPLETED';
        PRINT'BRONZE LAYER LOADING TIME IS :' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) as NVARCHAR)+ 'Seconds';
        PRINT'=====================================';
    END TRY

    BEGIN CATCH
        PRINT'=====================================';
        PRINT'GETTING ERROR ON LOADING BRONZE LAYER';
        PRINT'=====================================';
        PRINT'ERROR MESSAGE' + ERROR_MESSAGE();
        PRINT'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
    END CATCH
END;
