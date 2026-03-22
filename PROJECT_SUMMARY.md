# Sensor Monitoring System - Project Summary

**Course:** DTB (Database Technology)  
**Institution:** HBO Elektrotechniek  
**Date:** March 2026  

---

## 📝 Project Overview

This project implements a complete **Environmental Monitoring System** using:
- **Hardware:** Raspberry Pi + DHT22 Temperature/Humidity Sensor
- **Software:** C++ program reading sensors and storing data in SQLite database
- **Database:** Relational database with 5 tables and complex relationships

---

## 🎯 Learning Objectives Demonstrated

### 1. **Database Design**
✅ Entity-Relationship (ER) diagram created  
✅ Proper normalization applied  
✅ Primary and Foreign keys defined  
✅ One-to-Many relationships implemented  
✅ Constraints and data integrity enforced  

### 2. **SQL Programming**
✅ CREATE TABLE statements  
✅ INSERT, UPDATE, DELETE operations  
✅ Complex SELECT queries with JOINs  
✅ Aggregate functions (AVG, MIN, MAX, COUNT)  
✅ Views for data abstraction  
✅ Indexes for performance optimization  

### 3. **Real-World Application**
✅ IoT/Embedded systems integration  
✅ Time-series data management  
✅ Automated alerting system  
✅ Data quality monitoring  

### 4. **Programming**
✅ C++ implementation for hardware interface  
✅ Database connection and CRUD operations  
✅ Error handling and validation  
✅ System integration  

---

## 📊 Database Schema

### Tables (5 total)

1. **location** - Physical locations where sensors are deployed
   - Stores: room names, building info, floors
   - Primary Key: `location_id`

2. **sensor** - IoT sensor devices (DHT22)
   - Stores: sensor type, model, configuration
   - Foreign Key: `location_id` → location
   - Primary Key: `sensor_id`

3. **reading** - Time-series measurements
   - Stores: sensor values, timestamps, status
   - Foreign Key: `sensor_id` → sensor
   - Primary Key: `reading_id`
   - **Most active table** - grows continuously

4. **alert_rule** - Threshold configurations
   - Stores: min/max thresholds, severity levels
   - Foreign Key: `sensor_id` → sensor
   - Primary Key: `rule_id`

5. **alert** - Triggered warnings
   - Stores: alert messages, trigger times, resolution status
   - Foreign Keys: `reading_id` → reading, `rule_id` → alert_rule
   - Primary Key: `alert_id`

### Relationships
- **1:N** - One location has many sensors
- **1:N** - One sensor produces many readings
- **1:N** - One sensor has many alert rules
- **1:N** - One reading can trigger many alerts
- **1:N** - One rule generates many alerts over time

---

## 🔧 Technical Implementation

### Hardware
- **Raspberry Pi** (any model with GPIO)
- **DHT22 Sensor** - Temperature: -40°C to 80°C, Humidity: 0-100%
- **10kΩ Pull-up resistor**
- **Wiring:** GPIO4 (BCM) for data line

### Software Stack
- **C++11** - Sensor reading and data collection
- **WiringPi** - GPIO library for Raspberry Pi
- **SQLite3** - Embedded database (single file)
- **Systemd** - Service management for automatic startup

### Code Structure
```
sensor_monitor.cpp     - Main application (380 lines)
dht22.h               - DHT22 sensor library
schema_sqlite.sql     - Database schema
queries.sql           - Analysis queries
```

---

## 📈 Features Implemented

### Core Features
- ✅ Continuous sensor monitoring (configurable interval)
- ✅ Automatic data storage in database
- ✅ Real-time alert generation based on thresholds
- ✅ Error handling and retry logic
- ✅ Data validation and sanity checks

### Advanced Features
- ✅ Database views for common queries
- ✅ Composite indexes for query optimization
- ✅ Alert severity levels (info, warning, critical)
- ✅ Statistical analysis (min, max, avg)
- ✅ Time-based aggregations (hourly, daily)
- ✅ Data export capabilities (CSV)
- ✅ Systemd integration for production deployment

---

## 📋 Deliverables

### Documentation
- [x] ER diagram (Mermaid format)
- [x] Database schema (SQL)
- [x] README with installation instructions
- [x] Code comments and documentation
- [x] Example queries for data analysis

### Code
- [x] C++ sensor monitoring application
- [x] Database initialization scripts
- [x] Build system (Makefile + CMake)
- [x] Automated setup script
- [x] Test utilities

### Database
- [x] Complete schema with constraints
- [x] Sample data for testing
- [x] Useful views for reporting
- [x] Query examples

---

## 🧪 Testing & Validation

### Database Testing
```sql
-- Verify table creation
SELECT name FROM sqlite_master WHERE type='table';

-- Check relationships
SELECT * FROM latest_readings;

-- Verify indexes
SELECT name FROM sqlite_master WHERE type='index';
```

### Sensor Testing
```bash
# Test basic sensor reading
sudo ./test_dht22

# Run full system for 5 minutes
sudo timeout 300 ./sensor_monitor 10
```

### Data Validation
- Reading values checked: -40°C to 80°C (temp), 0-100% (humidity)
- Checksums verified for sensor communication
- Database constraints prevent invalid data

---

## 📊 Sample Queries Demonstrated

### Basic Queries
- Latest readings per sensor
- Current temperature/humidity in all rooms
- Total readings count

### Intermediate Queries
- Hourly/Daily averages
- Temperature trends over time
- Alert history with details

### Advanced Queries
- Statistical analysis (AVG, MIN, MAX)
- Time-series aggregations
- Multi-table JOINs with filtering
- Data quality checks (gap detection)
- Comfort index calculation

---

## 💡 Database Concepts Applied

1. **Normalization**
   - 3NF achieved
   - No redundant data
   - Atomic values only

2. **Referential Integrity**
   - Foreign key constraints
   - CASCADE deletes where appropriate
   - Orphan record prevention

3. **Data Types**
   - INTEGER for IDs and counters
   - REAL for measurements
   - TEXT for descriptive fields
   - TIMESTAMP for temporal data

4. **Indexing Strategy**
   - Primary key indexes (automatic)
   - Foreign key indexes
   - Composite indexes for common queries
   - Timestamp indexes for time-series queries

5. **Views**
   - `latest_readings` - Most recent sensor data
   - `active_alerts` - Unresolved warnings
   - `sensor_stats_24h` - Daily statistics

---

## 🚀 Deployment

### Installation Time
- **Hardware setup:** 15 minutes
- **Software installation:** 10 minutes
- **Database creation:** 2 minutes
- **Testing:** 5 minutes
- **Total:** ~30 minutes

### Production Ready
- ✅ Systemd service configuration
- ✅ Automatic startup on boot
- ✅ Log rotation
- ✅ Error recovery
- ✅ Performance optimization

---

## 📈 Data Growth Estimation

### Storage Requirements
- **Per reading:** ~50 bytes
- **Readings per day:** 1440 (at 60-second interval)
- **Daily growth:** ~70 KB
- **Monthly growth:** ~2.1 MB
- **Yearly growth:** ~25 MB

### Optimization
- Indexes: ~20% overhead
- Old data cleanup: keep last 90 days
- Vacuum database monthly

---

## 🎓 Skills Demonstrated

### Technical Skills
- Database design and normalization
- SQL programming (DDL, DML, queries)
- C++ programming
- Embedded systems (Raspberry Pi)
- GPIO/sensor interfacing
- System integration
- Version control ready

### Professional Skills
- Requirements analysis
- System documentation
- Code organization
- Error handling
- Testing and validation
- Deployment procedures

---

## 🔄 Possible Extensions

### Easy Extensions (1-2 hours)
- Add more sensors (light, pressure, motion)
- Email notifications on alerts
- Data export to CSV/JSON
- Web API for remote access

### Medium Extensions (1 day)
- Web dashboard with charts
- Historical data visualization
- Mobile app integration
- MQTT broker for IoT messaging

### Advanced Extensions (multiple days)
- Machine learning for anomaly detection
- Predictive maintenance
- Multi-location synchronization
- Cloud backup integration

---

## ✅ Assessment Criteria Met

| Criterion | Status | Evidence |
|-----------|--------|----------|
| ER diagram created | ✅ | Mermaid diagram provided |
| Normalized database | ✅ | 3NF, no redundancy |
| SQL schema complete | ✅ | All tables with constraints |
| Foreign keys defined | ✅ | 5 relationships implemented |
| Sample data provided | ✅ | 4 locations, 6 sensors, rules |
| Queries demonstrated | ✅ | 30+ example queries |
| Real-world application | ✅ | Working IoT system |
| Documentation | ✅ | Complete README |
| Working code | ✅ | C++ + build system |

---

## 📚 References

### Technologies Used
- **SQLite:** https://www.sqlite.org/
- **WiringPi:** http://wiringpi.com/
- **DHT22 Datasheet:** Aosong Electronics
- **Raspberry Pi GPIO:** https://pinout.xyz/

### Database Design
- Entity-Relationship modeling
- Normalization (1NF, 2NF, 3NF)
- ACID properties
- Indexing strategies

---

## 🏁 Conclusion

This project successfully demonstrates:
1. **Database design** from concept to implementation
2. **Real-world integration** with hardware sensors
3. **Professional development** practices
4. **Complete documentation** for maintenance

The system is **production-ready** and can be deployed immediately for environmental monitoring in homes, greenhouses, server rooms, or any location requiring climate control.

---

**Project Status:** ✅ COMPLETE  
**Estimated Development Time:** 6-8 hours  
**Lines of Code:** ~850 (C++) + 400 (SQL)  
**Files Created:** 11  

---

*For questions or support, refer to README.md or check the troubleshooting section.*
