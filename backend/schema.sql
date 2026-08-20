

-- Admin accounts (created manually / via seed, no self-signup)
CREATE TABLE IF NOT EXISTS admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Buses (just a label — no fixed route stored, since routes can change)
CREATE TABLE IF NOT EXISTS buses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bus_name VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Drivers (pre-created by admin, optionally assigned to a bus)
CREATE TABLE IF NOT EXISTS drivers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    bus_id INT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bus_id) REFERENCES buses(id) ON DELETE SET NULL
);

-- Live / historical driver locations
CREATE TABLE IF NOT EXISTS driver_locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
);

-- Track online/offline + "trip started" state per driver
CREATE TABLE IF NOT EXISTS driver_status (
    driver_id INT PRIMARY KEY,
    is_active TINYINT(1) DEFAULT 0,
    last_seen DATETIME NULL,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
);

CREATE INDEX idx_locations_driver_time ON driver_locations (driver_id, recorded_at);

-- ============================================
-- Default admin account
-- username: admin
-- password: admin123   <-- CHANGE THIS AFTER FIRST LOGIN
-- (hash below is bcrypt for "admin123")
-- ============================================
INSERT INTO admins (username, password_hash)
VALUES ('admin', '$2y$10$xrNy0j8Vir20Jf3tsuxbm.apBDaJWBRYxSlUOpxpqVvR/EQbwei.K')
ON DUPLICATE KEY UPDATE username = username;
