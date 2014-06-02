CREATE EXTERNAL TABLE users
        (id INT, name STRING,
        gender STRING,
        address STRING,
        first_visit DATE)
        ROW FORMAT DELIMITED FIELDS TERMINATED BY ","
        STORED AS TEXTFILE LOCATION "/drill/HIVE/users";



