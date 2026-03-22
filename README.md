# DHT22 Sensor Monitoring System
## Environmental Monitoring with Raspberry Pi

A complete IoT solution for monitoring temperature and humidity using DHT22 sensors and storing data in a SQLite database.

---

## 📋 Table of Contents
1. [Hardware Requirements](#hardware-requirements)
2. [Software Requirements](#software-requirements)
3. [Wiring Diagram](#wiring-diagram)
4. [Installation](#installation)
5. [Database Schema](#database-schema)
6. [Usage](#usage)
7. [Useful Queries](#useful-queries)
8. [Troubleshooting](#troubleshooting)

---

## 🔧 Hardware Requirements

### Required Components
- **Raspberry Pi** (any model with GPIO)
- **DHT22** Temperature & Humidity Sensor (±€5-10)
- **10kΩ Resistor** (pull-up resistor)
- **Breadboard and jumper wires**

### Optional
- Power supply for Raspberry Pi
- SD card (8GB+ recommended)
- Case for protection

---

## 💻 Software Requirements

### Operating System
- Raspberry Pi OS (Raspbian) - Latest version

### Libraries & Dependencies
- **WiringPi** - GPIO library
- **SQLite3** - Database
- **g++** - C++ compiler
- **CMake** (optional, for building)

---

## 🔌 Wiring Diagram

### DHT22 Pinout
```
Looking at DHT22 from the front (grid side):

Pin 1: VCC  (3.3V - 5V)
Pin 2: DATA (Signal)
Pin 3: NC   (Not Connected)
Pin 4: GND  (Ground)
```

### Connection to Raspberry Pi
```
DHT22          Raspberry Pi
------         -------------
Pin 1 (VCC)  → Pin 1  (3.3V)
Pin 2 (DATA) → Pin 7  (GPIO4/BCM4)
Pin 3 (NC)   → Not connected
Pin 4 (GND)  → Pin 6  (GND)

Add 10kΩ resistor between VCC (Pin 1) and DATA (Pin 2)
```

### Visual Diagram
```
Raspberry Pi GPIO (Looking at the board)
=========================================
3.3V  [ 1] [ 2]  5V
GPIO2 [ 3] [ 4]  5V
GPIO3 [ 5] [ 6]  GND  ← DHT22 GND
GPIO4 [ 7] [ 8]  GPIO14
      ↑
      └─ DHT22 DATA (with 10kΩ pull-up to 3.3V)
```

---

## 📦 Installation

### Quick Setup (Automated)

1. **Transfer files to Raspberry Pi**
   ```bash
   # On your computer, copy files to Pi
   scp *.cpp *.h *.sql setup.sh pi@raspberrypi.local:~/sensor_project/
   ```

2. **Run the setup script**
   ```bash
   cd ~/sensor_project
   chmod +x setup.sh
   ./setup.sh
   ```

### Manual Setup

1. **Update system**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade
   ```

2. **Install dependencies**
   ```bash
   sudo apt-get install -y build-essential cmake git sqlite3 libsqlite3-dev wiringpi
   ```

3. **Install WiringPi (if not available)**
   ```bash
   cd /tmp
   git clone https://github.com/WiringPi/WiringPi.git
   cd WiringPi
   ./build
   ```

4. **Create database**
   ```bash
   sqlite3 ~/sensor_monitoring.db < schema_sqlite.sql
   ```

5. **Compile the program**
   
   **Option A: Using Make**
   ```bash
   make
   sudo make install
   ```
   
   **Option B: Using CMake**
   ```bash
   mkdir build && cd build
   cmake ..
   make
   sudo make install
   ```
   
   **Option C: Direct compilation**
   ```bash
   g++ -o sensor_monitor sensor_monitor.cpp -lsqlite3 -lwiringPi -lpthread -std=c++11
   sudo cp sensor_monitor /usr/local/bin/
   ```

---

## 🗄️ Database Schema

### Tables

1. **location** - Physical locations (rooms)
2. **sensor** - Sensor devices
3. **reading** - Time-series measurements
4. **alert_rule** - Threshold configurations
5. **alert** - Triggered warnings

### ER Diagram
See [ER-diagram-sensor-monitoring.md](ER-diagram-sensor-monitoring.md) for visual representation.

---

## 🚀 Usage

### Basic Operation

**Run the program (reads every 60 seconds)**
```bash
sudo ./sensor_monitor
```

**Specify custom interval (in seconds)**
```bash
sudo ./sensor_monitor 30    # Read every 30 seconds
sudo ./sensor_monitor 300   # Read every 5 minutes
```

### Run as Background Service

**Create systemd service** (already done by setup.sh)
```bash
sudo systemctl start sensor-monitor
sudo systemctl status sensor-monitor
sudo systemctl stop sensor-monitor
```

**View logs**
```bash
sudo journalctl -u sensor-monitor -f
```

### Run at Startup

```bash
sudo systemctl enable sensor-monitor
```

---

## 📊 Useful Queries

### View Latest Readings
```bash
sqlite3 ~/sensor_monitoring.db "SELECT * FROM latest_readings;"
```

### View Last 24 Hours Statistics
```bash
sqlite3 ~/sensor_monitoring.db "SELECT * FROM sensor_stats_24h;"
```

### View Active Alerts
```bash
sqlite3 ~/sensor_monitoring.db "SELECT * FROM active_alerts;"
```

### Custom Queries

**Get temperature trend (last hour)**
```sql
SELECT 
    datetime(timestamp, 'localtime') as time,
    value as temperature
FROM reading
WHERE sensor_id = 1 
    AND timestamp >= datetime('now', '-1 hour')
ORDER BY timestamp;
```

**Average temperature by hour**
```sql
SELECT 
    strftime('%Y-%m-%d %H:00', timestamp) as hour,
    ROUND(AVG(value), 2) as avg_temp,
    ROUND(MIN(value), 2) as min_temp,
    ROUND(MAX(value), 2) as max_temp
FROM reading
WHERE sensor_id = 1
GROUP BY hour
ORDER BY hour DESC
LIMIT 24;
```

**Count alerts by severity**
```sql
SELECT 
    ar.severity,
    COUNT(*) as alert_count
FROM alert a
JOIN alert_rule ar ON a.rule_id = ar.rule_id
WHERE a.triggered_at >= datetime('now', '-24 hours')
GROUP BY ar.severity;
```

See [queries.sql](queries.sql) for more examples.

---

## 🐛 Troubleshooting

### Issue: "Failed to initialize wiringPi"
**Solution:** Run with sudo
```bash
sudo ./sensor_monitor
```

### Issue: "Failed to read sensor"
**Possible causes:**
1. **Wrong wiring** - Double-check connections
2. **Missing pull-up resistor** - Add 10kΩ between VCC and DATA
3. **Timing issues** - DHT22 needs 2 seconds between reads
4. **Faulty sensor** - Try a different DHT22

**Test sensor manually:**
```bash
gpio -v          # Check GPIO is working
gpio readall     # Show pin status
```

### Issue: "Cannot open database"
**Solution:** Check database path
```bash
ls -l ~/sensor_monitoring.db
chmod 644 ~/sensor_monitoring.db
```

### Issue: No data in database
**Check if readings are being inserted:**
```bash
sqlite3 ~/sensor_monitoring.db "SELECT COUNT(*) FROM reading;"
```

### Issue: Permission denied
**Solution:** Add user to gpio group
```bash
sudo usermod -a -G gpio pi
sudo reboot
```

---

## 📈 Data Analysis

### Export to CSV
```bash
sqlite3 -header -csv ~/sensor_monitoring.db "SELECT * FROM reading;" > data.csv
```

### Backup Database
```bash
sqlite3 ~/sensor_monitoring.db ".backup backup_$(date +%Y%m%d).db"
```

### Clean Old Data (keep last 30 days)
```sql
DELETE FROM reading 
WHERE timestamp < datetime('now', '-30 days');
```

---

## 🔄 Configuration

### Change Sensor IDs
Edit `sensor_monitor.cpp`:
```cpp
#define TEMP_SENSOR_ID 1    // Your temperature sensor ID
#define HUMID_SENSOR_ID 2   // Your humidity sensor ID
```

### Change GPIO Pin
Edit `sensor_monitor.cpp`:
```cpp
#define DHT_PIN 4           // GPIO pin (BCM numbering)
```

### Adjust Alert Thresholds
```sql
-- Temperature: Alert if outside 15-28°C
UPDATE alert_rule 
SET min_threshold = 15.0, max_threshold = 28.0 
WHERE sensor_id = 1;

-- Humidity: Alert if outside 30-70%
UPDATE alert_rule 
SET min_threshold = 30.0, max_threshold = 70.0 
WHERE sensor_id = 2;
```

---

## 📚 Project Structure

```
.
├── sensor_monitor.cpp      # Main C++ program
├── dht22.h                 # DHT22 sensor library
├── schema.sql              # MySQL/MariaDB schema
├── schema_sqlite.sql       # SQLite schema (for Pi)
├── CMakeLists.txt          # CMake build file
├── Makefile                # Make build file
├── setup.sh                # Automated setup script
├── queries.sql             # Example SQL queries
├── README.md               # This file
└── ER-diagram-sensor-monitoring.md  # Database design
```

---

## 🎯 Project Goals Achieved

✅ IoT sensor integration  
✅ Real-time data collection  
✅ Relational database design  
✅ Automated alerting system  
✅ Time-series data storage  
✅ C++ programming on embedded system  
✅ Complete documentation  

---

## 📝 License

Educational project for HBO Elektrotechniek - DTB Course

---

## 🤝 Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Verify wiring connections
3. Check sensor with multimeter
4. Review system logs: `sudo journalctl -xe`

---

## 🚀 Next Steps / Extensions

- Add more sensor types (light, motion, pressure)
- Create web dashboard for visualization
- Add email/SMS notifications
- Implement data analytics
- Add remote monitoring via MQTT
- Create mobile app

---

**Happy Monitoring! 🌡️💧**
