drop table if exists iptocs;

create table IF NOT EXISTS iptocs(
 ip_from int(10) unsigned zerofill not null,
 ip_to int(10) unsigned zerofill not null,
 country_code2 char(2) not null,
 country_code3 char(3) not null,
 country_name varchar(50) not null,
 unique index(ip_from, ip_to)
);

delete from iptocs;

load data local infile 'ip-to-country.csv' 
  into table iptocs
  fields terminated by ',' enclosed by '"' 
  lines terminated by '\r\n';

alter table iptocs add column id bigint(20) NOT NULL auto_increment primary key;

alter table iptocs add unique index (id);
optimize table iptocs;
