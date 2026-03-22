-- Useful SQL Queries for Sensor Monitoring System
-- Copy these into your SQLite database to analyze your sensor data

-- ============================================================
-- BASIC QUERIES
-- ============================================================

-- View all locations
SELECT * FROM location;

-- View all active sensors
SELECT 
    s.sensor_id,
    l.name as location,
    s.sensor_type,
    s.model,
    s.is_active
FROM sensor s
JOIN location l ON s.location_id = l.location_id
WHERE s.is_active = 1;

-- Latest reading from each sensor
SELECT * FROM latest_readings;

-- Last 10 readings (all sensors)
SELECT 
    l.name as location,
    s.sensor_type,
    r.value,
    s.unit_of_measurement,
    datetime(r.timestamp, 'localtime') as time
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
ORDER BY r.timestamp DESC
LIMIT 10;

-- ============================================================
-- TEMPERATURE ANALYSIS
-- ============================================================

-- Current temperature in all locations
SELECT 
    l.name as location,
    ROUND(r.value, 1) || '°C' as temperature,
    datetime(r.timestamp, 'localtime') as last_updated
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE s.sensor_type = 'temperature'
    AND r.timestamp = (SELECT MAX(timestamp) FROM reading WHERE sensor_id = s.sensor_id);

-- Temperature statistics (last 24 hours)
SELECT 
    l.name as location,
    COUNT(r.reading_id) as readings,
    ROUND(AVG(r.value), 1) as avg_temp,
    ROUND(MIN(r.value), 1) as min_temp,
    ROUND(MAX(r.value), 1) as max_temp
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE s.sensor_type = 'temperature'
    AND r.timestamp >= datetime('now', '-24 hours')
GROUP BY l.name;

-- Temperature trend (hourly averages, last 24 hours)
SELECT 
    strftime('%Y-%m-%d %H:00', timestamp) as hour,
    ROUND(AVG(value), 1) as avg_temp
FROM reading
WHERE sensor_id = 1  -- Change to your temperature sensor ID
    AND timestamp >= datetime('now', '-24 hours')
GROUP BY hour
ORDER BY hour;

-- ============================================================
-- HUMIDITY ANALYSIS
-- ============================================================

-- Current humidity in all locations
SELECT 
    l.name as location,
    ROUND(r.value, 1) || '%' as humidity,
    datetime(r.timestamp, 'localtime') as last_updated
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE s.sensor_type = 'humidity'
    AND r.timestamp = (SELECT MAX(timestamp) FROM reading WHERE sensor_id = s.sensor_id);

-- Humidity statistics (last 24 hours)
SELECT 
    l.name as location,
    ROUND(AVG(r.value), 1) as avg_humidity,
    ROUND(MIN(r.value), 1) as min_humidity,
    ROUND(MAX(r.value), 1) as max_humidity
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE s.sensor_type = 'humidity'
    AND r.timestamp >= datetime('now', '-24 hours')
GROUP BY l.name;

-- ============================================================
-- COMBINED TEMPERATURE & HUMIDITY
-- ============================================================

-- Latest temperature and humidity per location
SELECT 
    l.name as location,
    MAX(CASE WHEN s.sensor_type = 'temperature' THEN ROUND(r.value, 1) END) as temp_c,
    MAX(CASE WHEN s.sensor_type = 'humidity' THEN ROUND(r.value, 1) END) as humidity_pct,
    MAX(datetime(r.timestamp, 'localtime')) as last_reading
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE r.timestamp >= datetime('now', '-5 minutes')
GROUP BY l.name;

-- ============================================================
-- TIME-BASED QUERIES
-- ============================================================

-- Readings in the last hour
SELECT 
    datetime(timestamp, 'localtime') as time,
    l.name as location,
    s.sensor_type,
    value,
    s.unit_of_measurement
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE timestamp >= datetime('now', '-1 hour')
ORDER BY timestamp DESC;

-- Daily summary (today)
SELECT 
    l.name as location,
    s.sensor_type,
    COUNT(r.reading_id) as count,
    ROUND(AVG(r.value), 1) as avg,
    ROUND(MIN(r.value), 1) as min,
    ROUND(MAX(r.value), 1) as max
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE DATE(r.timestamp) = DATE('now')
GROUP BY l.name, s.sensor_type;

-- Weekly averages
SELECT 
    strftime('%Y-%W', timestamp) as week,
    l.name as location,
    s.sensor_type,
    ROUND(AVG(r.value), 1) as avg_value
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE timestamp >= datetime('now', '-4 weeks')
GROUP BY week, l.name, s.sensor_type
ORDER BY week DESC, l.name;

-- ============================================================
-- ALERT QUERIES
-- ============================================================

-- All active (unresolved) alerts
SELECT * FROM active_alerts;

-- Alert count by location (last 7 days)
SELECT 
    l.name as location,
    COUNT(a.alert_id) as alert_count,
    MAX(datetime(a.triggered_at, 'localtime')) as last_alert
FROM alert a
JOIN reading r ON a.reading_id = r.reading_id
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE a.triggered_at >= datetime('now', '-7 days')
GROUP BY l.name
ORDER BY alert_count DESC;

-- Alert history with details
SELECT 
    datetime(a.triggered_at, 'localtime') as time,
    l.name as location,
    s.sensor_type,
    a.alert_type,
    r.value as measured_value,
    ar.min_threshold,
    ar.max_threshold,
    ar.severity,
    a.is_resolved
FROM alert a
JOIN reading r ON a.reading_id = r.reading_id
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
JOIN alert_rule ar ON a.rule_id = ar.rule_id
ORDER BY a.triggered_at DESC
LIMIT 20;

-- Alerts by severity (last 30 days)
SELECT 
    ar.severity,
    COUNT(*) as count
FROM alert a
JOIN alert_rule ar ON a.rule_id = ar.rule_id
WHERE a.triggered_at >= datetime('now', '-30 days')
GROUP BY ar.severity;

-- ============================================================
-- PERFORMANCE & STATISTICS
-- ============================================================

-- Total readings per sensor
SELECT 
    l.name as location,
    s.sensor_type,
    COUNT(r.reading_id) as total_readings,
    MIN(datetime(r.timestamp, 'localtime')) as first_reading,
    MAX(datetime(r.timestamp, 'localtime')) as last_reading
FROM sensor s
JOIN location l ON s.location_id = l.location_id
LEFT JOIN reading r ON s.sensor_id = r.sensor_id
GROUP BY s.sensor_id, l.name, s.sensor_type;

-- Database size and row counts
SELECT 
    'location' as table_name, COUNT(*) as rows FROM location
UNION ALL SELECT 'sensor', COUNT(*) FROM sensor
UNION ALL SELECT 'reading', COUNT(*) FROM reading
UNION ALL SELECT 'alert_rule', COUNT(*) FROM alert_rule
UNION ALL SELECT 'alert', COUNT(*) FROM alert;

-- Readings per day (last 30 days)
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as readings
FROM reading
WHERE timestamp >= datetime('now', '-30 days')
GROUP BY date
ORDER BY date DESC;

-- ============================================================
-- DATA QUALITY
-- ============================================================

-- Check for missing data (gaps > 5 minutes)
SELECT 
    s.sensor_id,
    l.name as location,
    s.sensor_type,
    datetime(r1.timestamp, 'localtime') as reading_time,
    datetime(r2.timestamp, 'localtime') as next_reading,
    ROUND((julianday(r2.timestamp) - julianday(r1.timestamp)) * 24 * 60, 1) as gap_minutes
FROM reading r1
JOIN reading r2 ON r1.sensor_id = r2.sensor_id 
    AND r2.reading_id = (
        SELECT MIN(reading_id) 
        FROM reading 
        WHERE sensor_id = r1.sensor_id 
        AND timestamp > r1.timestamp
    )
JOIN sensor s ON r1.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE (julianday(r2.timestamp) - julianday(r1.timestamp)) * 24 * 60 > 5
ORDER BY gap_minutes DESC
LIMIT 20;

-- Sensors with no recent data (>1 hour)
SELECT 
    s.sensor_id,
    l.name as location,
    s.sensor_type,
    MAX(datetime(r.timestamp, 'localtime')) as last_reading,
    ROUND((julianday('now') - julianday(MAX(r.timestamp))) * 24 * 60, 1) as minutes_ago
FROM sensor s
JOIN location l ON s.location_id = l.location_id
LEFT JOIN reading r ON s.sensor_id = r.sensor_id
WHERE s.is_active = 1
GROUP BY s.sensor_id
HAVING minutes_ago > 60 OR last_reading IS NULL;

-- ============================================================
-- EXPORT QUERIES
-- ============================================================

-- Export all data for analysis (CSV format)
-- Run with: sqlite3 -header -csv sensor_monitoring.db < this_query > export.csv
SELECT 
    datetime(r.timestamp, 'localtime') as timestamp,
    l.name as location,
    l.building,
    l.floor,
    s.sensor_type,
    s.model,
    r.value,
    s.unit_of_measurement,
    r.status
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
ORDER BY r.timestamp DESC;

-- ============================================================
-- MAINTENANCE QUERIES
-- ============================================================

-- Delete readings older than 90 days
-- DELETE FROM reading WHERE timestamp < datetime('now', '-90 days');

-- Vacuum database (reclaim space after deletes)
-- VACUUM;

-- Analyze database (optimize queries)
-- ANALYZE;

-- ============================================================
-- ADVANCED ANALYTICS
-- ============================================================

-- Comfort index (temperature + humidity correlation)
SELECT 
    l.name as location,
    ROUND(AVG(CASE WHEN s.sensor_type = 'temperature' THEN r.value END), 1) as avg_temp,
    ROUND(AVG(CASE WHEN s.sensor_type = 'humidity' THEN r.value END), 1) as avg_humidity,
    CASE 
        WHEN AVG(CASE WHEN s.sensor_type = 'temperature' THEN r.value END) BETWEEN 20 AND 24
         AND AVG(CASE WHEN s.sensor_type = 'humidity' THEN r.value END) BETWEEN 40 AND 60
        THEN 'Comfortable'
        ELSE 'Suboptimal'
    END as comfort_level
FROM reading r
JOIN sensor s ON r.sensor_id = s.sensor_id
JOIN location l ON s.location_id = l.location_id
WHERE r.timestamp >= datetime('now', '-1 hour')
GROUP BY l.name;
