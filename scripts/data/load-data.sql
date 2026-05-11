DROP DATABASE IF EXISTS otus;
CREATE DATABASE otus;
USE otus;

CREATE TABLE customers (
  id INT PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  email VARCHAR(128) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE orders (
  id INT PRIMARY KEY,
  customer_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status ENUM('new', 'paid', 'shipped') NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB;

CREATE TABLE route_probe (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  client_name VARCHAR(64) NOT NULL,
  target_host VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO customers(id, name, email) VALUES
  (1, 'Customer 01', 'customer01@example.local'),
  (2, 'Customer 02', 'customer02@example.local'),
  (3, 'Customer 03', 'customer03@example.local'),
  (4, 'Customer 04', 'customer04@example.local'),
  (5, 'Customer 05', 'customer05@example.local'),
  (6, 'Customer 06', 'customer06@example.local'),
  (7, 'Customer 07', 'customer07@example.local'),
  (8, 'Customer 08', 'customer08@example.local'),
  (9, 'Customer 09', 'customer09@example.local'),
  (10, 'Customer 10', 'customer10@example.local');

INSERT INTO orders(id, customer_id, amount, status) VALUES
  (1, 1, 120.10, 'new'),
  (2, 2, 98.40, 'paid'),
  (3, 3, 180.00, 'shipped'),
  (4, 4, 74.20, 'paid'),
  (5, 5, 33.50, 'new'),
  (6, 6, 410.00, 'paid'),
  (7, 7, 58.90, 'new'),
  (8, 8, 99.99, 'shipped'),
  (9, 9, 15.70, 'paid'),
  (10, 10, 260.30, 'new'),
  (11, 1, 45.00, 'paid'),
  (12, 2, 63.25, 'paid'),
  (13, 3, 82.10, 'new'),
  (14, 4, 144.80, 'shipped'),
  (15, 5, 220.00, 'paid'),
  (16, 6, 17.35, 'new'),
  (17, 7, 305.99, 'paid'),
  (18, 8, 27.45, 'new'),
  (19, 9, 88.88, 'shipped'),
  (20, 10, 199.90, 'paid');

SELECT 'otus data loaded' AS result;
SHOW TABLES;
SELECT COUNT(*) AS orders_count FROM orders;

