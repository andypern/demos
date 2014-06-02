#!/bin/bash

#if need be , blow away all tables + views

hive -e "drop table sensor;drop table pump_info; drop table maint_table; drop view pumpview;"

