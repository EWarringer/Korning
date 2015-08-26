-- DEFINE YOUR DATABASE SCHEMA HERE

CREATE TABLE account_no(id SERIAL PRIMARY KEY, customer varchar(100), account_no varchar(100));

CREATE TABLE invoice_frequency(id SERIAL PRIMARY KEY, invoice_frequency varchar(100));

CREATE TABLE employee(id SERIAL PRIMARY KEY, employee varchar(100), email varchar(100), product_name varchar(100));

CREATE TABLE invoice_no(id SERIAL PRIMARY KEY, employee_id int REFERENCES employee(id), account_no_id int REFERENCES account_no(id), sale_date date, sale_amount money, units_sold int, invoice_no int, invoice_frequency_id int REFERENCES invoice_frequency(id));
