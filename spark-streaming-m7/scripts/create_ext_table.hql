CREATE EXTERNAL TABLE sensor
        (key STRING, custID int, actualDate STRING,
        daily_usage FLOAT,
        temp_avg FLOAT,
        temp_max FLOAT,
        temp_min FLOAT
        )
        STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
        WITH SERDEPROPERTIES (
        "hbase.columns.mapping" =
        ":key,cf1:custID,cf1:actualDate,cf1:daily_usage,cf1:temp_avg,
        cf1:temp_max,cf1:temp_min"
        )

TBLPROPERTIES("hbase.table.name" = "/tables/sensortable");
