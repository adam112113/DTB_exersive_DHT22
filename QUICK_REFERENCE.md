# Sensor Monitoring System - Quick Reference

## 🚀 Quick Start Commands

### Setup (First Time)
```bash
chmod +x setup.sh
./setup.sh
```

### Compile
```bash
make                    # Compile with Make
# OR
g++ -o sensor_monitor sensor_monitor.cpp -lsqlite3 -lwiringPi -lpthread -std=c++11
```

### Run
```bash
sudo ./sensor_monitor              # Read every 60 seconds (default)
sudo ./sensor_monitor 30           # Read every 30 seconds
```

### Test Hardware
```bash
g++ -o test_dht22 test_dht22.cpp -lwiringPi -std=c++11
sudo ./test_dht22
```

---

## 🔌 Wiring (DHT22 to Raspberry Pi)

```
DHT22 Pin 1 (VCC)  → Raspberry Pi Pin 1  (3.3V)
DHT22 Pin 2 (DATA) → Raspberry Pi Pin 7  (GPIO4)
DHT22 Pin 4 (GND)  → Raspberry Pi Pin 6  (GND)

⚠️ Add 10kΩ resistor between VCC and DATA!
```

---

## 🗄️ Database Commands

### Initialize Database
```bash
sqlite3 ~/sensor_monitoring.db < schema_sqlite.sql
```

### Query Database
```bash
# Interactive mode
sqlite3 ~/sensor_monitoring.db

# Single query
sqlite3 ~/sensor_monitoring.db "SELECT * FROM latest_readings;"
```

### Common Queries
```sql
-- Latest readings
SELECT * FROM latest_readings;

-- 24-hour stats
SELECT * FROM sensor_stats_24h;

-- Active alerts
SELECT * FROM active_alerts;

-- Last 10 readings
SELECT l.name, s.sensor_type, r.value, r.timestamp 
FROM reading r 
JOIN sensor s ON r.sensor_id = s.sensor_id 
JOIN location l ON s.location_id = l.location_id 
ORDER BY r.timestamp DESC LIMIT 10;
```

---

## 🔧 Systemd Service

### Start/Stop Service
```bash
sudo systemctl start sensor-monitor
sudo systemctl stop sensor-monitor
sudo systemctl restart sensor-monitor
```

### Check Status
```bash
sudo systemctl status sensor-monitor
```

### View Logs
```bash
sudo journalctl -u sensor-monitor -f      # Follow logs
sudo journalctl -u sensor-monitor -n 50   # Last 50 lines
```

### Enable at Boot
```bash
sudo systemctl enable sensor-monitor
```

---

## 📊 Data Export

### Export to CSV
```bash
sqlite3 -header -csv ~/sensor_monitoring.db \
  "SELECT * FROM reading;" > readings.csv
```

### Backup Database
```bash
sqlite3 ~/sensor_monitoring.db ".backup backup_$(date +%Y%m%d).db"
```

---

## 🛠️ Troubleshooting

### Sensor Not Reading
```bash
# Check GPIO
gpio readall

# Test sensor
sudo ./test_dht22

# Check wiring (especially pull-up resistor!)
```

### Database Issues
```bash
# Check if database exists
ls -l ~/sensor_monitoring.db

# Verify tables
sqlite3 ~/sensor_monitoring.db ".tables"

# Check permissions
chmod 644 ~/sensor_monitoring.db
```

### Permission Denied
```bash
# Run with sudo
sudo ./sensor_monitor

# Or add user to gpio group
sudo usermod -a -G gpio $USER
sudo reboot
```

---

## 📝 Configuration

### Change Reading Interval
Edit command line argument:
```bash
sudo ./sensor_monitor 60   # 60 seconds
sudo ./sensor_monitor 300  # 5 minutes
```

### Change GPIO Pin
Edit `sensor_monitor.cpp`:
```cpp
#define DHT_PIN 4   // Change to your GPIO pin
```

### Change Sensor IDs
Edit `sensor_monitor.cpp`:
```cpp
#define TEMP_SENSOR_ID 1    // Your temp sensor ID
#define HUMID_SENSOR_ID 2   // Your humidity sensor ID
```

### Adjust Alert Thresholds
```sql
UPDATE alert_rule 
SET min_threshold = 15.0, max_threshold = 30.0 
WHERE sensor_id = 1;
```

---

## 📈 Maintenance

### Clean Old Data (keep 30 days)
```sql
DELETE FROM reading WHERE timestamp < datetime('now', '-30 days');
VACUUM;
```

### Optimize Database
```sql
ANALYZE;
VACUUM;
```

### View Database Size
```bash
du -h ~/sensor_monitoring.db
```

---

## 🔍 Useful One-Liners

```bash
# Current temperature
sqlite3 ~/sensor_monitoring.db "SELECT l.name, r.value FROM reading r JOIN sensor s ON r.sensor_id=s.sensor_id JOIN location l ON s.location_id=l.location_id WHERE s.sensor_type='temperature' ORDER BY r.timestamp DESC LIMIT 1;"

# Reading count
sqlite3 ~/sensor_monitoring.db "SELECT COUNT(*) FROM reading;"

# Latest alert
sqlite3 ~/sensor_monitoring.db "SELECT * FROM active_alerts ORDER BY triggered_at DESC LIMIT 1;"

# Average temp last hour
sqlite3 ~/sensor_monitoring.db "SELECT ROUND(AVG(value),1) FROM reading WHERE sensor_id=1 AND timestamp >= datetime('now','-1 hour');"
```

---

## 📞 Support Resources

- **README.md** - Full documentation
- **queries.sql** - Example queries
- **PROJECT_SUMMARY.md** - Project overview
- **GPIO Pinout:** https://pinout.xyz/

---

## ⚡ GPIO Pin Reference

```
Raspberry Pi GPIO (Physical Pin Numbers)
========================================
Pin 1:  3.3V     Pin 2:  5V
Pin 3:  GPIO2    Pin 4:  5V
Pin 5:  GPIO3    Pin 6:  GND
Pin 7:  GPIO4    Pin 8:  GPIO14   ← We use GPIO4 (Pin 7)
Pin 9:  GND      Pin 10: GPIO15
...
```

---

**Quick Help:** For detailed info, see README.md or PROJECT_SUMMARY.md
