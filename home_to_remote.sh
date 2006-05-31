#!/bin/sh
mysqldump -u cscourseware -pdev3005 cscourseware_dev > dump
mysql -u cscourseware -pdev3005 cscourseware_dev -h 127.0.0.1 -P 4000 < dump

