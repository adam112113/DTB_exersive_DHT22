#!/bin/bash

# Sensor Monitoring System - Build and Setup Script
# Run this on your Raspberry Pi

echo "🔧 Sensor Monitoring System - Setup Script"
echo "==========================================="

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  Warning: This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update package list
echo "📦 Updating package list..."
sudo apt-get update

# Install required packages
echo "📥 Installing dependencies..."
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    sqlite3 \
    libsqlite3-dev \
    wiringpi

# Check if WiringPi is installed correctly
if ! command -v gpio &> /dev/null; then
    echo "⚠️  WiringPi not found. Installing from source..."
    cd /tmp
    git clone https://github.com/WiringPi/WiringPi.git
    cd WiringPi
    ./build
    cd -
fi

# Test GPIO
echo "🔌 Testing GPIO access..."
gpio -v
if [ $? -ne 0 ]; then
    echo "❌ GPIO test failed. Please check your setup."
    exit 1
fi

# Create database directory
echo "📁 Creating database directory..."
DB_DIR="$HOME"
DB_FILE="$DB_DIR/sensor_monitoring.db"

# Initialize database
echo "🗄️  Initializing database..."
if [ -f "$DB_FILE" ]; then
    echo "⚠️  Database already exists at $DB_FILE"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$DB_FILE"
    else
        echo "Keeping existing database"
    fi
fi

# Create database from schema
sqlite3 "$DB_FILE" < schema_sqlite.sql
if [ $? -eq 0 ]; then
    echo "✓ Database created successfully at $DB_FILE"
else
    echo "❌ Failed to create database"
    exit 1
fi

# Build the C++ program
echo "🔨 Building sensor monitoring program..."

# Method 1: Using CMake (preferred)
if command -v cmake &> /dev/null; then
    mkdir -p build
    cd build
    cmake ..
    make
    if [ $? -eq 0 ]; then
        echo "✓ Build successful (CMake)"
        sudo make install
        cd ..
    else
        echo "❌ CMake build failed"
        cd ..
    fi
else
    # Method 2: Direct compilation
    echo "CMake not found, using direct compilation..."
    g++ -o sensor_monitor sensor_monitor.cpp -lsqlite3 -lwiringPi -lpthread -std=c++11
    if [ $? -eq 0 ]; then
        echo "✓ Build successful (g++)"
        sudo cp sensor_monitor /usr/local/bin/
    else
        echo "❌ Compilation failed"
        exit 1
    fi
fi

# Create systemd service (optional)
echo ""
read -p "📋 Create systemd service to run at boot? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SERVICE_FILE="/etc/systemd/system/sensor-monitor.service"
    
    sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=DHT22 Sensor Monitoring Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=$HOME
ExecStart=/usr/local/bin/sensor_monitor 60
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable sensor-monitor.service
    echo "✓ Systemd service created"
    echo "  Start with: sudo systemctl start sensor-monitor"
    echo "  Stop with:  sudo systemctl stop sensor-monitor"
    echo "  Status:     sudo systemctl status sensor-monitor"
    echo "  Logs:       sudo journalctl -u sensor-monitor -f"
fi

# Display wiring instructions
echo ""
echo "🔌 DHT22 Sensor Wiring Instructions"
echo "===================================="
echo "Connect your DHT22 sensor as follows:"
echo ""
echo "  DHT22 Pin 1 (VCC)    -> Raspberry Pi 3.3V (Pin 1)"
echo "  DHT22 Pin 2 (DATA)   -> Raspberry Pi GPIO4 (Pin 7)"
echo "  DHT22 Pin 3 (NC)     -> Not connected"
echo "  DHT22 Pin 4 (GND)    -> Raspberry Pi GND (Pin 6)"
echo ""
echo "Add a 10kΩ pull-up resistor between VCC and DATA"
echo ""
echo "GPIO Pin Layout:"
echo "  Physical Pin 1:  3.3V"
echo "  Physical Pin 6:  GND"
echo "  Physical Pin 7:  GPIO4 (BCM)"
echo ""

# Test run
echo ""
read -p "🧪 Run a test? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running sensor monitor for 30 seconds..."
    echo "Make sure your DHT22 is connected!"
    sleep 2
    sudo timeout 30 ./sensor_monitor 5 || echo "Test completed"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "To run the program:"
echo "  sudo ./sensor_monitor [interval_seconds]"
echo "  Example: sudo ./sensor_monitor 60"
echo ""
echo "To view the data:"
echo "  sqlite3 $DB_FILE \"SELECT * FROM latest_readings;\""
echo ""
echo "Happy monitoring! 🌡️💧"
