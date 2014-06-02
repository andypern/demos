CREATE EXTERNAL TABLE users
        (id BIGINT, name STRING,
        gender STRING,
        address STRING,
        first_visit DATE)
        ROW FORMAT DELIMITED FIELDS TERMINATED BY ","
        STORED AS TEXTFILE LOCATION "/drill/HIVE/users";



