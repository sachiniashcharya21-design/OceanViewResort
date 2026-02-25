CREATE DATABASE IF NOT EXISTS ocean_view_resort
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ocean_view_resort;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS activity_log;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS room_types;
DROP TABLE IF EXISTS guests;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS staff;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NULL,
  password_hash VARCHAR(255) NULL,
  role ENUM('ADMIN', 'STAFF') NOT NULL DEFAULT 'STAFF',
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(120) NULL,
  phone VARCHAR(30) NULL,
  address TEXT NULL,
  hire_date DATE NULL,
  profile_picture VARCHAR(255) NULL,
  status ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE guests (
  guest_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  nic_passport VARCHAR(80) NULL UNIQUE,
  email VARCHAR(120) NULL,
  phone VARCHAR(30) NULL,
  address TEXT NULL,
  nationality VARCHAR(80) NULL,
  date_of_birth DATE NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE room_types (
  room_type_id INT AUTO_INCREMENT PRIMARY KEY,
  type_id INT NULL UNIQUE,
  type_name VARCHAR(80) NOT NULL UNIQUE,
  description TEXT NULL,
  rate_per_night DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  max_occupancy INT NOT NULL DEFAULT 1,
  amenities TEXT NULL,
  status ENUM('AVAILABLE', 'UNAVAILABLE', 'DISCONTINUED') NOT NULL DEFAULT 'AVAILABLE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rooms (
  room_id INT AUTO_INCREMENT PRIMARY KEY,
  room_number VARCHAR(20) NOT NULL UNIQUE,
  room_type_id INT NOT NULL,
  floor_number INT NOT NULL DEFAULT 1,
  floor INT GENERATED ALWAYS AS (floor_number) STORED,
  status ENUM('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'RESERVED') NOT NULL DEFAULT 'AVAILABLE',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rooms_room_type FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id)
);

CREATE TABLE reservations (
  reservation_id INT AUTO_INCREMENT PRIMARY KEY,
  reservation_number VARCHAR(30) NOT NULL UNIQUE,
  guest_id INT NOT NULL,
  room_id INT NOT NULL,
  check_in_date DATE NOT NULL,
  check_out_date DATE NOT NULL,
  number_of_guests INT NOT NULL DEFAULT 1,
  special_requests TEXT NULL,
  status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED') NOT NULL DEFAULT 'CONFIRMED',
  created_by INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_res_guest FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
  CONSTRAINT fk_res_room FOREIGN KEY (room_id) REFERENCES rooms(room_id),
  CONSTRAINT fk_res_user FOREIGN KEY (created_by) REFERENCES users(user_id)
);

CREATE TABLE bills (
  bill_id INT AUTO_INCREMENT PRIMARY KEY,
  bill_number VARCHAR(30) NOT NULL UNIQUE,
  reservation_id INT NOT NULL UNIQUE,
  number_of_nights INT NOT NULL DEFAULT 1,
  room_rate DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  room_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  service_charge DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  additional_charges DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  discount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(12,2) GENERATED ALWAYS AS (discount) STORED,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  payment_status ENUM('PENDING', 'PAID', 'PARTIAL') NOT NULL DEFAULT 'PENDING',
  payment_method ENUM('CASH', 'CARD', 'BANK_TRANSFER', 'ONLINE', 'MOBILE_PAYMENT') NOT NULL DEFAULT 'CASH',
  generated_by INT NULL,
  generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  paid_at TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_bill_res FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
  CONSTRAINT fk_bill_user FOREIGN KEY (generated_by) REFERENCES users(user_id)
);

CREATE TABLE activity_log (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  action VARCHAR(100) NOT NULL,
  description TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_activity_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE staff (
  staff_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  phone VARCHAR(30) NULL,
  position VARCHAR(80) NULL,
  department VARCHAR(80) NULL,
  salary DECIMAL(12,2) NULL,
  hire_date DATE NULL,
  status ENUM('ACTIVE', 'ON_LEAVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  address TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_room_types_status ON room_types(status);
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_reservations_dates ON reservations(check_in_date, check_out_date);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_bills_status ON bills(payment_status);
CREATE INDEX idx_bills_paid_at ON bills(paid_at);

DELIMITER //
DROP TRIGGER IF EXISTS trg_room_types_set_type_id//
DELIMITER ;

INSERT INTO users (username, password, password_hash, role, full_name, email, phone, address, hire_date, status)
VALUES
('admin', 'admin123', SHA2('admin123', 256), 'ADMIN', 'System Administrator', 'admin@oceanview.local', '+94 91 000 0001', 'Ocean View Resort, Galle', '2024-01-01', 'ACTIVE'),
('staff', 'staff123', SHA2('staff123', 256), 'STAFF', 'Front Desk Staff', 'staff@oceanview.local', '+94 91 000 0002', 'Ocean View Resort, Galle', '2024-01-15', 'ACTIVE');

INSERT INTO room_types (room_type_id, type_id, type_name, description, rate_per_night, max_occupancy, amenities, status) VALUES
(1, 1, 'STANDARD', 'Comfortable standard room', 12000.00, 2, 'AC, WiFi, TV', 'AVAILABLE'),
(2, 2, 'DELUXE', 'Spacious deluxe room with sea view', 18000.00, 3, 'AC, WiFi, TV, Mini Bar', 'AVAILABLE'),
(3, 3, 'SUITE', 'Luxury suite room', 28000.00, 4, 'AC, WiFi, TV, Mini Bar, Living Area', 'AVAILABLE');

INSERT INTO rooms (room_number, room_type_id, floor_number, status, notes) VALUES
('101', 1, 1, 'AVAILABLE', 'Near lobby'),
('102', 1, 1, 'AVAILABLE', NULL),
('201', 2, 2, 'AVAILABLE', 'Sea side'),
('202', 2, 2, 'MAINTENANCE', 'AC service pending'),
('301', 3, 3, 'AVAILABLE', 'Premium suite');

INSERT INTO guests (full_name, nic_passport, email, phone, address, nationality, date_of_birth) VALUES
('Kasun Perera', '901234567V', 'kasun@example.com', '+94 77 111 2222', 'Colombo, Sri Lanka', 'Sri Lankan', '1990-05-14'),
('Nimali Fernando', 'N1234567', 'nimali@example.com', '+94 77 333 4444', 'Kandy, Sri Lanka', 'Sri Lankan', '1988-11-02');

INSERT INTO reservations (reservation_number, guest_id, room_id, check_in_date, check_out_date, number_of_guests, special_requests, status, created_by)
VALUES
('RES2026020001', 1, 1, '2026-02-27', '2026-03-01', 2, 'Late check-in', 'CONFIRMED', 2),
('RES2026020002', 2, 3, '2026-02-25', '2026-02-28', 2, '', 'CHECKED_IN', 2);

INSERT INTO bills (bill_number, reservation_id, number_of_nights, room_rate, room_total, service_charge, tax_amount, additional_charges, discount, total_amount, payment_status, payment_method, generated_by, paid_at)
VALUES
('BILL2026020001', 2, 3, 18000.00, 54000.00, 5400.00, 2970.00, 0.00, 0.00, 62370.00, 'PENDING', 'CASH', 2, NULL);

INSERT INTO staff (first_name, last_name, email, phone, position, department, salary, hire_date, status, address)
VALUES
('Nuwan', 'Silva', 'nuwan.silva@oceanview.local', '+94 77 555 1234', 'Receptionist', 'Front Office', 85000.00, '2024-03-01', 'ACTIVE', 'Galle');
