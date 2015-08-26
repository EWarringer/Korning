# Use this file to import the sales information into the database.
require "pg"
require "csv"
require "pry"

def db_connection
  begin
    connection = PG.connect(dbname: "korning")
    yield(connection)
  ensure
    connection.close
  end
end

# Class that turns the CSV rows into objects. It parses the data that is not already in the correct format
class Invoice
  attr_reader :product_name, :sale_date, :sale_amount, :units_sold, :invoice_no, :invoice_frequency
  def initialize(row)
    @employee = row[:employee]
    @email = row[:employee]
    @customer = row[:customer_and_account_no]
    @account_no = row[:customer_and_account_no]
    @product_name = row[:product_name]
    @sale_amount = row[:sale_amount]
    @sale_date = row[:sale_date]
    @units_sold = row[:units_sold]
    @invoice_no = row[:invoice_no]
    @invoice_frequency = row[:invoice_frequency]
  end

  def employee
    @employee.split(" (")[0]
  end

  def email
    @email.split(" (")[1].gsub(')', '')
  end

  def customer
    @customer.split(" (")[0]
  end

  def account_no
    @account_no.split(" (")[1].gsub(')', '')
  end
end


sales = CSV.readlines('sales.csv', headers: true, header_converters: :symbol)

# Take each row of the CSV file, and pass them through the Invoice class.
clean_array = []
sales.each do |row|
  clean_array << Invoice.new(row)
end


# Loop through the objects in the clean_array array and insert them into the korning database
db_connection do |conn|
  invoice_numbers_check = []
  account_array = []
  freq_array = []
  employee_array = []

  clean_array.each do |row|
    # EXTRA CHALLENGE: If invoice number is already in the database, the row is not added.
    unless invoice_numbers_check.include?(row.invoice_no)

      unless account_array.include?(row.account_no)
        conn.exec_params('INSERT INTO account_no (customer, account_no) VALUES ($1, $2)', [row.customer, row.account_no])
      end

      unless freq_array.include?(row.invoice_frequency)
        conn.exec_params('INSERT INTO invoice_frequency (invoice_frequency) VALUES ($1)', [row.invoice_frequency])
      end

      unless employee_array.include?(row.employee)
        conn.exec_params('INSERT INTO employee (employee, email, product_name) VALUES ($1, $2, $3)', [row.employee, row.email, row.product_name])
      end

      # Match the value of the ID in the employee, account_no_id, and invoice_frequency_id tables
      # and insert them into their respective columns in the invoice_no table
      employee_id = conn.exec("SELECT id FROM employee WHERE employee = '#{row.employee}'")[0]["id"]
      account_no_id = conn.exec("SELECT id FROM account_no WHERE account_no = '#{row.account_no}'")[0]["id"]
      invoice_frequency_id = conn.exec("SELECT id FROM invoice_frequency WHERE invoice_frequency = '#{row.invoice_frequency}'")[0]["id"]

      conn.exec_params('INSERT INTO invoice_no (employee_id, account_no_id, sale_date, sale_amount, units_sold, invoice_no, invoice_frequency_id) VALUES ($1, $2, $3, $4, $5, $6, $7)', [employee_id, account_no_id, row.sale_date, row.sale_amount, row.units_sold, row.invoice_no, invoice_frequency_id])

      account_array << row.account_no
      freq_array << row.invoice_frequency
      employee_array << row.employee
      invoice_numbers_check << row.invoice_no

    end
  end
end
