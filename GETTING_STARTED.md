# 🚀 Getting Started - Step-by-Step Guide

**Complete chronological guide to get your sensor monitoring system running**

---

## ⏱️ Estimated Time: 45 minutes total

---

## 📋 BEFORE YOU START

### What You Need:

**Hardware:**
- [ ] Raspberry Pi (any model with GPIO pins)
- [ ] MicroSD card (8GB+) with Raspberry Pi OS installed
- [ ] DHT22 sensor (~€5-10)
- [ ] 10kΩ resistor (brown-black-orange color bands)
- [ ] Breadboard (optional but helpful)
- [ ] 3-4 jumper wires (female-to-female or male-to-female)

**Do you have all this?** If not, order the DHT22 sensor kit online first!

---

## STEP 1: Set Up Hardware (15 minutes)

### 1.1 Connect the DHT22 Sensor

**Important:** Make sure your Raspberry Pi is POWERED OFF before wiring!

```
DHT22 Sensor → Raspberry Pi Connection
═══════════════════════════════════════

Pin 1 (VCC)  → Connect to Pin 1 (3.3V)
Pin 2 (DATA) → Connect to Pin 7 (GPIO4)
Pin 3 (NC)   → Leave unconnected
Pin 4 (GND)  → Connect to Pin 6 (GND)
```

### 1.2 Add the Pull-up Resistor

**Critical:** Connect a 10kΩ resistor between:
- DHT22 Pin 1 (VCC) and Pin 2 (DATA)

```
Visual:
             10kΩ
   VCC ────/\/\/\──── DATA
    │                  │
    └──── to Pi 3.3V   └──── to Pi GPIO4
```

**Check:** 
- [ ] VCC connected to Raspberry Pi Pin 1
- [ ] DATA connected to Raspberry Pi Pin 7  
- [ ] GND connected to Raspberry Pi Pin 6
- [ ] 10kΩ resistor between VCC and DATA

**Now you can power ON your Raspberry Pi!**

For detailed wiring diagrams, see: [WIRING_GUIDE.md](WIRING_GUIDE.md)

---

## STEP 2: Copy Files to Raspberry Pi (5 minutes)

### 2.1 Get the Files onto Your Pi

**Option A: Use a USB Drive**
1. Copy all files from this folder to a USB drive
2. Insert USB into Raspberry Pi
3. Open File Manager and copy files to `/home/pi/sensor_project/`

**Option B: Use Network Transfer (if Pi is on network)**
```bash
# On your Windows PC (in PowerShell):
scp *.cpp *.h *.sql *.sh *.txt Makefile pi@raspberrypi.local:/home/pi/sensor_project/

# Password is usually: raspberry (or what you set)
```

**Option C: Download from GitHub** (if you uploaded there)
```bash
# On Raspberry Pi:
cd ~
git clone https://github.com/yourusername/sensor-project.git sensor_project
```

### 2.2 Verify Files Are There

On your Raspberry Pi, open Terminal and type:
```bash
cd ~/sensor_project
ls -la
```

You should see these files:
- sensor_monitor.cpp
- dht22.h
- test_dht22.cpp
- schema_sqlite.sql
- setup.sh
- Makefile
- CMakeLists.txt
- README.md
- (and other documentation files)

---

## STEP 3: Run the Automated Setup (10 minutes)

### 3.1 Make Setup Script Executable

In Raspberry Pi Terminal:
```bash
cd ~/sensor_project
chmod +x setup.sh
```

### 3.2 Run the Setup Script

```bash
./setup.sh
```

**What this does:**
- Installs required software (SQLite, WiringPi, compiler)
- Creates the database
- Compiles the C++ programs
- Sets up sample data
- Optionally creates a systemd service

**During setup:**
- It will ask for sudo password (usually: `raspberry`)
- It may ask "Continue anyway?" → Type `y` and press Enter
- It may ask "Overwrite database?" → Type `y` if first install
- It may ask "Create systemd service?" → Type `y` for automatic startup

**This takes about 5-10 minutes. Wait for it to complete!**

---

## STEP 4: Test the Sensor (5 minutes)

### 4.1 Compile Test Program (if not already done)

```bash
cd ~/sensor_project
g++ -o test_dht22 test_dht22.cpp -lwiringPi -std=c++11
```

### 4.2 Run the Test

```bash
sudo ./test_dht22
```

**Expected Output:**
```
🧪 DHT22 Sensor Test Program
=============================
GPIO Pin: 4 (BCM numbering)
Reading every 3 seconds...

✓ Reading #1
  🌡️  Temperature: 22.3°C
  💧 Humidity: 45.8%

✓ Reading #2
  🌡️  Temperature: 22.4°C
  💧 Humidity: 45.7%
```

**If you see this:** ✅ Your sensor works! Press Ctrl+C to stop.

**If you see errors:**
- ❌ "Failed to read sensor" → Check wiring and resistor
- ❌ "Failed to initialize wiringPi" → Did you use `sudo`?
- See [README.md](README.md) troubleshooting section

---

## STEP 5: Check Database is Ready (2 minutes)

### 5.1 Verify Database Exists

```bash
ls -l ~/sensor_monitoring.db
```

Should show a file (might be small, like 20-40 KB)

### 5.2 Check Database Contents

```bash
sqlite3 ~/sensor_monitoring.db "SELECT * FROM location;"
```

**Expected Output:**
```
1|Living Room|Main living area|Home|Ground Floor|2026-03-25...
2|Bedroom|Master bedroom|Home|First Floor|2026-03-25...
3|Kitchen|Cooking area|Home|Ground Floor|2026-03-25...
4|Greenhouse|Plant growing area|Garden|Outdoor|2026-03-25...
```

**If you see this:** ✅ Database is ready!

---

## STEP 6: Run the Monitoring System (2 minutes)

### 6.1 Start the Monitor

```bash
cd ~/sensor_project
sudo ./sensor_monitor 60
```

**What "60" means:** Read sensor every 60 seconds

**Expected Output:**
```
🌡️  DHT22 Sensor Monitoring System
===================================
Database opened successfully
Reading interval: 60 seconds
Press Ctrl+C to stop

[2026-03-25 14:30:00]
🌡️  Temperature: 22.5°C
💧 Humidity: 46.2%
✓ Temperature saved
✓ Humidity saved
```

**If you see this:** 🎉 **SUCCESS! Your system is working!**

### 6.2 Let It Run

Leave it running for a few minutes to collect some data.
Press **Ctrl+C** when you want to stop.

---

## STEP 7: View Your Data (5 minutes)

### 7.1 View Latest Readings

```bash
sqlite3 ~/sensor_monitoring.db "SELECT * FROM latest_readings;"
```

### 7.2 View Statistics

```bash
sqlite3 ~/sensor_monitoring.db "SELECT * FROM sensor_stats_24h;"
```

### 7.3 Count Total Readings

```bash
sqlite3 ~/sensor_monitoring.db "SELECT COUNT(*) as total_readings FROM reading;"
```

### 7.4 Interactive Database Exploration

```bash
sqlite3 ~/sensor_monitoring.db
```

Then try these commands:
```sql
.tables                           -- Show all tables
.schema sensor                    -- Show table structure
SELECT * FROM reading LIMIT 10;   -- Show last 10 readings
.quit                             -- Exit SQLite
```

---

## STEP 8 (OPTIONAL): Run as Background Service

If you want the system to run automatically at boot:

### 8.1 Enable the Service

```bash
sudo systemctl enable sensor-monitor
sudo systemctl start sensor-monitor
```

### 8.2 Check Service Status

```bash
sudo systemctl status sensor-monitor
```

### 8.3 View Live Logs

```bash
sudo journalctl -u sensor-monitor -f
```

Press Ctrl+C to stop viewing logs.

### 8.4 Stop the Service (if needed)

```bash
sudo systemctl stop sensor-monitor
```

---

## 🎯 VERIFICATION CHECKLIST

After completing all steps, verify:

- [ ] ✅ Sensor connected and working (`test_dht22` shows readings)
- [ ] ✅ Database created (`~/sensor_monitoring.db` exists)
- [ ] ✅ Tables exist (can query `location`, `sensor`, `reading`)
- [ ] ✅ Main program runs (`sensor_monitor` collects data)
- [ ] ✅ Data is being saved (query shows growing readings)

**All checked?** You're done! 🎉

---

## 📊 WHAT'S HAPPENING NOW

Your system is:
1. Reading DHT22 sensor every 60 seconds
2. Storing temperature in database (sensor_id = 1)
3. Storing humidity in database (sensor_id = 2)
4. Checking alert rules
5. Generating alerts if thresholds exceeded

---

## 🔍 COMMON TASKS

### Change Reading Interval
```bash
sudo ./sensor_monitor 30    # Read every 30 seconds
sudo ./sensor_monitor 300   # Read every 5 minutes
```

### Export Data to CSV
```bash
sqlite3 -header -csv ~/sensor_monitoring.db \
  "SELECT * FROM reading;" > my_data.csv
```

### View Current Temperature
```bash
sqlite3 ~/sensor_monitoring.db \
  "SELECT value FROM reading WHERE sensor_id=1 ORDER BY timestamp DESC LIMIT 1;"
```

### Clear Old Data (keep last 7 days)
```bash
sqlite3 ~/sensor_monitoring.db \
  "DELETE FROM reading WHERE timestamp < datetime('now', '-7 days');"
```

---

## 📚 WHERE TO GO NEXT

### For Daily Use:
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Common commands

### For Questions:
- **[README.md](README.md)** - Complete documentation
- **[WIRING_GUIDE.md](WIRING_GUIDE.md)** - Detailed wiring help

### For Learning:
- **[queries.sql](queries.sql)** - Example SQL queries to try
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Understanding the project

### For Troubleshooting:
- **[README.md](README.md)** - Section: Troubleshooting

---

## ❌ TROUBLESHOOTING QUICK FIXES

### "Failed to read sensor"
```bash
# Check wiring
gpio readall

# Verify resistor is connected
# Try different jumper wires
# Wait 2 seconds between readings
```

### "Failed to initialize wiringPi"
```bash
# Always use sudo
sudo ./sensor_monitor 60
```

### "Cannot open database"
```bash
# Check path
ls -l ~/sensor_monitoring.db

# Recreate if needed
sqlite3 ~/sensor_monitoring.db < schema_sqlite.sql
```

### "Permission denied"
```bash
# Make sure you're using sudo
sudo ./sensor_monitor 60

# Or add to gpio group (then reboot)
sudo usermod -a -G gpio pi
sudo reboot
```

---

## 🎓 FOR YOUR ASSIGNMENT

You now have:
- ✅ Working IoT system with real sensor
- ✅ Complete database (5 tables, relationships)
- ✅ Time-series data being collected
- ✅ Automated alerts working
- ✅ ER diagram (design)
- ✅ SQL schema
- ✅ C++ implementation
- ✅ Documentation

**Everything needed for your DTB assignment!**

---

## 💡 TIPS

1. **Keep it running:** Let the monitor run overnight to collect lots of data
2. **Try queries:** Use the examples in `queries.sql` to analyze your data
3. **Watch alerts:** Breathe on the sensor to trigger temperature/humidity alerts
4. **Document it:** Take screenshots for your assignment report
5. **Experiment:** Try different reading intervals, modify thresholds

---

## ⏭️ NEXT STEPS TIMELINE

**Now → 1 hour:** Let system collect initial data  
**1 hour → 1 day:** Explore queries, understand database  
**1 day → 1 week:** Collect meaningful data for analysis  
**Before submission:** Export data, prepare documentation  

---

## 📞 STILL STUCK?

1. **Check step number** - Make sure you completed previous steps
2. **Read error message** - Often tells you what's wrong
3. **Check wiring** - 90% of sensor issues are loose connections
4. **Use sudo** - Always run with `sudo ./sensor_monitor`
5. **Verify files** - Make sure all files copied correctly

---

## ✅ SUMMARY - ABSOLUTE MINIMUM STEPS

If you just want to get it working FAST:

```bash
# 1. Copy files to ~/sensor_project
# 2. Wire sensor (VCC→Pin1, DATA→Pin7, GND→Pin6, add resistor)
# 3. Run these commands:

cd ~/sensor_project
chmod +x setup.sh
./setup.sh              # Install everything
sudo ./test_dht22       # Test sensor (Ctrl+C to stop)
sudo ./sensor_monitor 60  # Start monitoring!
```

**That's it!** 🚀

---

**Good luck! You've got everything you need!** 🌡️💧
