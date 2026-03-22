-- Environmental Monitoring System Database Schema
-- Database Type: SQLite (for Raspberry Pi embedded use)
-- Created: 2026-03-08

-- Drop tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS alert;
DROP TABLE IF EXISTS alert_rule;
DROP TABLE IF EXISTS reading;
DROP TABLE IF EXISTS sensor;
DROP TABLE IF EXISTS location;

-- ============================================================
-- TABLE: location
-- Description: Physical locations where sensors are deployed
-- ============================================================
CREATE TABLE location (
    location_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    building TEXT,
    floor TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (name, building, floor)
);

-- ============================================================
-- TABLE: sensor
-- Description: Physical sensor devices
-- ============================================================
CREATE TABLE sensor (
    sensor_id INTEGER PRIMARY KEY AUTOINCREMENT,
    location_id INTEGER NOT NULL,
    sensor_type TEXT NOT NULL,
    model TEXT,
    unit_of_measurement TEXT,
    is_active INTEGER DEFAULT 1,
    installed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_maintenance TIMESTAMP,
    FOREIGN KEY (location_id) REFERENCES location(location_id) ON DELETE CASCADE
);

CREATE INDEX idx_sensor_location ON sensor(location_id);
CREATE INDEX idx_sensor_type ON sensor(sensor_type);
CREATE INDEX idx_sensor_active ON sensor(is_active);

-- ============================================================
-- TABLE: reading
-- Description: Time-series measurements from sensors
-- ============================================================
CREATE TABLE reading (
    reading_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sensor_id INTEGER NOT NULL,
    value REAL NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'normal',
    FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id) ON DELETE CASCADE
);

CREATE INDEX idx_reading_sensor ON reading(sensor_id);
CREATE INDEX idx_reading_timestamp ON reading(timestamp);
CREATE INDEX idx_reading_sensor_timestamp ON reading(sensor_id, timestamp);

-- ============================================================
-- TABLE: alert_rule
-- Description: Configured thresholds for alerts
-- ============================================================
CREATE TABLE alert_rule (
    rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sensor_id INTEGER NOT NULL,
    min_threshold REAL,
    max_threshold REAL,
    severity TEXT DEFAULT 'warning',
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id) ON DELETE CASCADE,
    CHECK (severity IN ('info', 'warning', 'critical'))
);

CREATE INDEX idx_rule_sensor ON alert_rule(sensor_id);
CREATE INDEX idx_rule_active ON alert_rule(is_active);

-- ============================================================
-- TABLE: alert
-- Description: Triggered alerts when readings violate rules
-- ============================================================
CREATE TABLE alert (
    alert_id INTEGER PRIMARY KEY AUTOINCREMENT,
    reading_id INTEGER NOT NULL,
    rule_id INTEGER NOT NULL,
    alert_type TEXT NOT NULL,
    message TEXT,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_resolved INTEGER DEFAULT 0,
    resolved_at TIMESTAMP,
    FOREIGN KEY (reading_id) REFERENCES reading(reading_id) ON DELETE CASCADE,
    FOREIGN KEY (rule_id) REFERENCES alert_rule(rule_id) ON DELETE CASCADE
);

CREATE INDEX idx_alert_reading ON alert(reading_id);
CREATE INDEX idx_alert_rule ON alert(rule_id);
CREATE INDEX idx_alert_triggered ON alert(triggered_at);
CREATE INDEX idx_alert_resolved ON alert(is_resolved);

-- ============================================================
-- SAMPLE DATA
-- ============================================================

-- Insert sample locations
INSERT INTO location (name, description, building, floor) VALUES
('Living Room', 'Main living area', 'Home', 'Ground Floor'),
('Bedroom', 'Master bedroom', 'Home', 'First Floor'),
('Kitchen', 'Cooking area', 'Home', 'Ground Floor'),
('Greenhouse', 'Plant growing area', 'Garden', 'Outdoor');

-- Insert sample sensors (DHT22 provides both temp and humidity)
INSERT INTO sensor (location_id, sensor_type, model, unit_of_measurement, is_active) VALUES
(1, 'temperature', 'DHT22', '°C', 1),
(1, 'humidity', 'DHT22', '%', 1),
(2, 'temperature', 'DHT22', '°C', 1),
(2, 'humidity', 'DHT22', '%', 1),
(4, 'temperature', 'DHT22', '°C', 1),
(4, 'humidity', 'DHT22', '%', 1);

-- Insert sample alert rules
-- Temperature alerts
INSERT INTO alert_rule (sensor_id, min_threshold, max_threshold, severity, is_active) VALUES
(1, 15.0, 28.0, 'warning', 1),   -- Living room temperature
(3, 16.0, 26.0, 'warning', 1),   -- Bedroom temperature
(5, 10.0, 35.0, 'critical', 1);  -- Greenhouse temperature

-- Humidity alerts
INSERT INTO alert_rule (sensor_id, min_threshold, max_threshold, severity, is_active) VALUES
(2, 30.0, 70.0, 'warning', 1),   -- Living room humidity
(4, 30.0, 70.0, 'warning', 1),   -- Bedroom humidity
(6, 40.0, 90.0, 'info', 1);      -- Greenhouse humidity

-- ============================================================
-- USEFUL VIEWS
-- ============================================================

-- View: Latest readings per sensor
CREATE VIEW IF NOT EXISTS latest_readings AS
SELECT 
    s.sensor_id,
    s.sensor_type,
    s.model,
    s.unit_of_measurement,
    l.name AS location_name,
    r.value,
    r.timestamp,
    r.status
FROM sensor s
JOIN location l ON s.location_id = l.location_id
LEFT JOIN reading r ON s.sensor_id = r.sensor_id
WHERE r.timestamp = (
    SELECT MAX(timestamp) 
    FROM reading 
    WHERE sensor_id = s.sensor_id
)
ORDER BY l.name, s.sensor_type;

-- View: Active unresolved alerts
CREATE VIEW IF NOT EXISTS active_alerts AS
SELECT 
    a.alert_id,
    a.alert_type,
    a.message,
    a.triggered_at,
    l.name AS location_name,
    s.sensor_type,
    r.value,
    ar.min_threshold,
    ar.max_threshold,
    ar.severity
FROM alert a
JOIN reading r ON a.reading_id = r.reading_id
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
JOIN alert_rule ar ON a.rule_id = ar.rule_id
WHERE a.is_resolved = 0
ORDER BY a.triggered_at DESC;

-- View: Sensor statistics (last 24 hours)
CREATE VIEW IF NOT EXISTS sensor_stats_24h AS
SELECT 
    s.sensor_id,
    l.name AS location_name,
    s.sensor_type,
    s.unit_of_measurement,
    COUNT(r.reading_id) AS reading_count,
    ROUND(AVG(r.value), 2) AS avg_value,
    ROUND(MIN(r.value), 2) AS min_value,
    ROUND(MAX(r.value), 2) AS max_value,
    MAX(r.timestamp) AS last_reading
FROM sensor s
JOIN location l ON s.location_id = l.location_id
LEFT JOIN reading r ON s.sensor_id = r.sensor_id
WHERE r.timestamp >= datetime('now', '-24 hours')
GROUP BY s.sensor_id, l.name, s.sensor_type, s.unit_of_measurement
ORDER BY l.name, s.sensor_type;
