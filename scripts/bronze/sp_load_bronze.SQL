/*
=======================================================================
Stored Procedure : Load Bronze Layer
=======================================================================
Script Purpose : 
  This stored procedure load the data into bronze schema from external csv files.

CREATE OR ALTER PROCEDURE bronze.load_data AS
DECLARE @start_time datetime,@end_time datetime, @batch_start_time datetime, @batch_end_time datetime
This perfrom 2 actions
  1. first truncate bronze tables 
  2. Loading the data in Bronze tables using 'BULK INSERT'
  3. Also estimating the time of loading the data for each table
  */
-- SQL LOAD SCRIPT
GO

BEGIN
    BEGIN TRY
        PRINT'===========================';
        PRINT 'lOADING BRONZE LAYER';
        PRINT'===========================';

        PRINT'---------------------------';
        PRINT'LOADING CRM TABLE';
        PRINT'---------------------------';

        SET @batch_start_time=GETDATE();

        PRINT'>>Truncating the table bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        SET @start_time=GETDATE();
        PRINT'>>Inserting the data in bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        from 'D:\sql\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        with (
            FIRSTROW=2,
            FIELDTERMINATOR=',',
            TABLOCK    
        )
        SET @end_time=GETDATE();
        PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
        PRINT'------------------------------------------------------'

        PRINT'>>Truncating the table bronze.crm_cust_prd_info';
        TRUNCATE TABLE bronze.crm_cust_prd_info;

        SET @start_time=GETDATE();
        PRINT'>>Inserting the data in bronze.crm_cust_prd_info';
        BULK INSERT bronze.crm_cust_prd_info
        from 'D:\sql\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        with (
            FIRSTROW=2,
            FIELDTERMINATOR=',',
            TABLOCK    
        )
        SET @end_time=GETDATE();
        PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
        PRINT'------------------------------------------------------'

        PRINT'>>Truncating the table bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        SET @start_time=GETDATE();
        PRINT'>>Inserting the data in bronze.crm_sales_details'
        BULK INSERT bronze.crm_sales_details
        from 'D:\sql\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        with (
            FIRSTROW=2,
            FIELDTERMINATOR=',',
            TABLOCK    
        )
        SET @end_time=GETDATE();
        PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
        PRINT'------------------------------------------------------'

        PRINT'---------------------------'
        PRINT'LOADING ERP LAYER';
        PRINT'---------------------------'

        PRINT'>>Truncating the table bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        SET @start_time=GETDATE();
        PRINT'>>Inserting the data in bronze.erp_cust_az12'
        BULK INSERT bronze.erp_cust_az12
        from 'D:\sql\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        with (
            FIRSTROW=2,
            FIELDTERMINATOR=',',
            TABLOCK    
        )
        SET @end_time=GETDATE();
        PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
        PRINT'------------------------------------------------------'

        PRINT'>>Truncating the table bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        SET @start_time=GETDATE();
        PRINT'>>Inserting the data in bronze.erp_loc_a101'
        BULK INSERT bronze.erp_loc_a101
        from 'D:\sql\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        with (
            FIRSTROW=2,
            FIELDTERMINATOR=',',
            TABLOCK    
        );
        SET @end_time=GETDATE();
        PRINT'LOADING TIME' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds';
        PRINT'------------------------------------------------------'

        PRINT'>>Truncating the table bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        SET @start_time=GETDATE();
        PRINT'>>Inserting the data in bronze.erp_px_cat_g1v2'
        BULK INSERT bronze.erp_px_cat_g1v2
        from 'D:\sql\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        with (
            FIRSTROW=2,
            FIELDTERMINATOR=',',
            TABLOCK    
        );
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
END


exec bronze.load_data
