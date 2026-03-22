-- Environmental Monitoring System Database Schema
-- Database: sensor_monitoring
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
    location_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    building VARCHAR(50),
    floor VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_location (name, building, floor)
);

-- ============================================================
-- TABLE: sensor
-- Description: Physical sensor devices
-- ============================================================
CREATE TABLE sensor (
    sensor_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    location_id INTEGER NOT NULL,
    sensor_type VARCHAR(50) NOT NULL,
    model VARCHAR(50),
    unit_of_measurement VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    installed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_maintenance TIMESTAMP NULL,
    FOREIGN KEY (location_id) REFERENCES location(location_id) ON DELETE CASCADE,
    INDEX idx_sensor_location (location_id),
    INDEX idx_sensor_type (sensor_type),
    INDEX idx_sensor_active (is_active)
);

-- ============================================================
-- TABLE: reading
-- Description: Time-series measurements from sensors
-- ============================================================
CREATE TABLE reading (
    reading_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    sensor_id INTEGER NOT NULL,
    value DECIMAL(10, 2) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'normal',
    FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id) ON DELETE CASCADE,
    INDEX idx_reading_sensor (sensor_id),
    INDEX idx_reading_timestamp (timestamp),
    INDEX idx_reading_sensor_timestamp (sensor_id, timestamp)
);

-- ============================================================
-- TABLE: alert_rule
-- Description: Configured thresholds for alerts
-- ============================================================
CREATE TABLE alert_rule (
    rule_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    sensor_id INTEGER NOT NULL,
    min_threshold DECIMAL(10, 2),
    max_threshold DECIMAL(10, 2),
    severity VARCHAR(20) DEFAULT 'warning',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id) ON DELETE CASCADE,
    INDEX idx_rule_sensor (sensor_id),
    INDEX idx_rule_active (is_active),
    CHECK (severity IN ('info', 'warning', 'critical'))
);

-- ============================================================
-- TABLE: alert
-- Description: Triggered alerts when readings violate rules
-- ============================================================
CREATE TABLE alert (
    alert_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    reading_id BIGINT NOT NULL,
    rule_id INTEGER NOT NULL,
    alert_type VARCHAR(50) NOT NULL,
    message TEXT,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (reading_id) REFERENCES reading(reading_id) ON DELETE CASCADE,
    FOREIGN KEY (rule_id) REFERENCES alert_rule(rule_id) ON DELETE CASCADE,
    INDEX idx_alert_reading (reading_id),
    INDEX idx_alert_rule (rule_id),
    INDEX idx_alert_triggered (triggered_at),
    INDEX idx_alert_resolved (is_resolved)
);

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
(1, 'temperature', 'DHT22', '°C', TRUE),
(1, 'humidity', 'DHT22', '%', TRUE),
(2, 'temperature', 'DHT22', '°C', TRUE),
(2, 'humidity', 'DHT22', '%', TRUE),
(4, 'temperature', 'DHT22', '°C', TRUE),
(4, 'humidity', 'DHT22', '%', TRUE);

-- Insert sample alert rules
-- Temperature alerts
INSERT INTO alert_rule (sensor_id, min_threshold, max_threshold, severity, is_active) VALUES
(1, 15.0, 28.0, 'warning', TRUE),   -- Living room temperature
(3, 16.0, 26.0, 'warning', TRUE),   -- Bedroom temperature
(5, 10.0, 35.0, 'critical', TRUE);  -- Greenhouse temperature

-- Humidity alerts
INSERT INTO alert_rule (sensor_id, min_threshold, max_threshold, severity, is_active) VALUES
(2, 30.0, 70.0, 'warning', TRUE),   -- Living room humidity
(4, 30.0, 70.0, 'warning', TRUE),   -- Bedroom humidity
(6, 40.0, 90.0, 'info', TRUE);      -- Greenhouse humidity

-- ============================================================
-- USEFUL VIEWS
-- ============================================================

-- View: Latest readings per sensor
CREATE OR REPLACE VIEW latest_readings AS
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
CREATE OR REPLACE VIEW active_alerts AS
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
WHERE a.is_resolved = FALSE
ORDER BY a.triggered_at DESC;

-- View: Sensor statistics (last 24 hours)
CREATE OR REPLACE VIEW sensor_stats_24h AS
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
WHERE r.timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY s.sensor_id, l.name, s.sensor_type, s.unit_of_measurement
ORDER BY l.name, s.sensor_type;

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

-- Additional composite indexes for common queries
CREATE INDEX idx_reading_status_timestamp ON reading(status, timestamp);
CREATE INDEX idx_alert_resolved_triggered ON alert(is_resolved, triggered_at);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE location IS 'Physical locations where sensors are installed';
COMMENT ON TABLE sensor IS 'IoT sensor devices (DHT22, etc.)';
COMMENT ON TABLE reading IS 'Time-series sensor measurements';
COMMENT ON TABLE alert_rule IS 'Threshold rules for triggering alerts';
COMMENT ON TABLE alert IS 'Triggered alerts based on threshold violations';
