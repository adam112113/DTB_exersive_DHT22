/*
 * DHT22 Sensor Monitoring System
 * Raspberry Pi C++ Implementation
 * 
 * This program reads temperature and humidity from DHT22 sensor
 * and stores the data in SQLite database
 * 
 * Compile: g++ -o sensor_monitor sensor_monitor.cpp -lsqlite3 -lwiringPi -std=c++11
 * Run: sudo ./sensor_monitor
 */

#include <iostream>
#include <iomanip>
#include <string>
#include <sstream>
#include <ctime>
#include <cstdlib>
#include <sqlite3.h>
#include <wiringPi.h>
#include <unistd.h>

// DHT22 Configuration
#define DHT_PIN 4           // GPIO pin (BCM numbering) - change as needed
#define MAX_TIMINGS 85
#define DHT_TIMEOUT 100

// Database configuration - can be overridden with environment variable
// Set with: export SENSOR_DB_PATH=/path/to/database.db
const char* getDbPath() {
    const char* envPath = std::getenv("SENSOR_DB_PATH");
    if (envPath != nullptr) {
        return envPath;
    }
    
    // Try to use current user's home directory
    const char* home = std::getenv("HOME");
    if (home != nullptr) {
        static std::string dbPath = std::string(home) + "/sensor_monitoring.db";
        return dbPath.c_str();
    }
    
    // Fallback to /home/pi
    return "/home/pi/sensor_monitoring.db";
}

// Sensor IDs (must match your database)
#define TEMP_SENSOR_ID 1    // Temperature sensor ID
#define HUMID_SENSOR_ID 2   // Humidity sensor ID

class DHT22Sensor {
private:
    int pin;
    int data[5];
    
public:
    DHT22Sensor(int gpio_pin) : pin(gpio_pin) {
        data[0] = data[1] = data[2] = data[3] = data[4] = 0;
    }
    
    bool readSensor(float &temperature, float &humidity) {
        uint8_t laststate = HIGH;
        uint8_t counter = 0;
        uint8_t j = 0, i;
        
        data[0] = data[1] = data[2] = data[3] = data[4] = 0;
        
        // Send start signal
        pinMode(pin, OUTPUT);
        digitalWrite(pin, LOW);
        delay(18);  // DHT22 requires minimum 1ms, use 18ms for safety
        
        digitalWrite(pin, HIGH);
        delayMicroseconds(40);
        pinMode(pin, INPUT);
        
        // Read data
        for (i = 0; i < MAX_TIMINGS; i++) {
            counter = 0;
            while (digitalRead(pin) == laststate) {
                counter++;
                delayMicroseconds(1);
                if (counter == 255) {
                    break;
                }
            }
            laststate = digitalRead(pin);
            
            if (counter == 255) break;
            
            // Ignore first 3 transitions
            if ((i >= 4) && (i % 2 == 0)) {
                data[j / 8] <<= 1;
                if (counter > 16)
                    data[j / 8] |= 1;
                j++;
            }
        }
        
        // Check we read 40 bits (8bit x 5) and checksum
        if ((j >= 40) && (data[4] == ((data[0] + data[1] + data[2] + data[3]) & 0xFF))) {
            humidity = (float)((data[0] << 8) + data[1]) / 10.0;
            temperature = (float)(((data[2] & 0x7F) << 8) + data[3]) / 10.0;
            
            if (data[2] & 0x80) {
                temperature = -temperature;
            }
            
            return true;
        } else {
            return false;
        }
    }
};

class Database {
private:
    sqlite3 *db;
    char *errorMessage;
    
public:
    Database() : db(nullptr), errorMessage(nullptr) {}
    
    ~Database() {
        if (db) {
            sqlite3_close(db);
        }
    }
    
    bool open(const char* dbPath) {
        int rc = sqlite3_open(dbPath, &db);
        if (rc) {
            std::cerr << "Cannot open database: " << sqlite3_errmsg(db) << std::endl;
            return false;
        }
        std::cout << "Database opened successfully" << std::endl;
        return true;
    }
    
    bool insertReading(int sensorId, float value) {
        std::stringstream sql;
        sql << "INSERT INTO reading (sensor_id, value) VALUES (" 
            << sensorId << ", " << std::fixed << std::setprecision(2) << value << ");";
        
        int rc = sqlite3_exec(db, sql.str().c_str(), nullptr, 0, &errorMessage);
        if (rc != SQLITE_OK) {
            std::cerr << "SQL error: " << errorMessage << std::endl;
            sqlite3_free(errorMessage);
            return false;
        }
        
        // Get the reading ID
        sqlite3_int64 readingId = sqlite3_last_insert_rowid(db);
        
        // Check for alerts
        checkAlerts(readingId, sensorId, value);
        
        return true;
    }
    
    void checkAlerts(sqlite3_int64 readingId, int sensorId, float value) {
        std::stringstream sql;
        sql << "SELECT rule_id, min_threshold, max_threshold, severity "
            << "FROM alert_rule "
            << "WHERE sensor_id = " << sensorId << " AND is_active = 1;";
        
        sqlite3_stmt *stmt;
        int rc = sqlite3_prepare_v2(db, sql.str().c_str(), -1, &stmt, nullptr);
        
        if (rc != SQLITE_OK) {
            std::cerr << "Failed to prepare statement: " << sqlite3_errmsg(db) << std::endl;
            return;
        }
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            int ruleId = sqlite3_column_int(stmt, 0);
            float minThreshold = sqlite3_column_double(stmt, 1);
            float maxThreshold = sqlite3_column_double(stmt, 2);
            const char* severity = (const char*)sqlite3_column_text(stmt, 3);
            
            std::string alertType;
            std::stringstream message;
            
            if (value < minThreshold) {
                alertType = "low_value";
                message << severity << ": Value " << value << " below minimum threshold " << minThreshold;
            } else if (value > maxThreshold) {
                alertType = "high_value";
                message << severity << ": Value " << value << " above maximum threshold " << maxThreshold;
            } else {
                continue; // No alert needed
            }
            
            // Insert alert
            std::stringstream alertSql;
            alertSql << "INSERT INTO alert (reading_id, rule_id, alert_type, message) VALUES ("
                     << readingId << ", " << ruleId << ", '" << alertType << "', '" 
                     << message.str() << "');";
            
            rc = sqlite3_exec(db, alertSql.str().c_str(), nullptr, 0, &errorMessage);
            if (rc != SQLITE_OK) {
                std::cerr << "Alert SQL error: " << errorMessage << std::endl;
                sqlite3_free(errorMessage);
            } else {
                std::cout << "ALERT: " << message.str() << std::endl;
            }
        }
        
        sqlite3_finalize(stmt);
    }
    
    void displayLatestReadings() {
        const char* sql = "SELECT l.name, s.sensor_type, r.value, s.unit_of_measurement, r.timestamp "
                         "FROM reading r "
                         "JOIN sensor s ON r.sensor_id = s.sensor_id "
                         "JOIN location l ON s.location_id = l.location_id "
                         "ORDER BY r.timestamp DESC LIMIT 10;";
        
        sqlite3_stmt *stmt;
        int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
        
        if (rc != SQLITE_OK) {
            std::cerr << "Failed to query readings: " << sqlite3_errmsg(db) << std::endl;
            return;
        }
        
        std::cout << "\nLatest Readings:" << std::endl;
        std::cout << "================================================" << std::endl;
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            std::cout << sqlite3_column_text(stmt, 0) << " - "
                     << sqlite3_column_text(stmt, 1) << ": "
                     << std::fixed << std::setprecision(1) << sqlite3_column_double(stmt, 2)
                     << sqlite3_column_text(stmt, 3) << " at "
                     << sqlite3_column_text(stmt, 4) << std::endl;
        }
        
        sqlite3_finalize(stmt);
    }
};

int main(int argc, char *argv[]) {
    std::cout << "DHT22 Sensor Monitoring System" << std::endl;
    std::cout << "===================================" << std::endl;
    
    // Initialize wiringPi
    if (wiringPiSetup() == -1) {
        std::cerr << "Failed to initialize wiringPi" << std::endl;
        return 1;
    }
    
    // Open database
    const char* dbPath = getDbPath();
    std::cout << "Database path: " << dbPath << std::endl;
    
    Database db;
    if (!db.open(dbPath)) {
        std::cerr << "\n⚠️  Database file not found!" << std::endl;
        std::cerr << "Create it with: sqlite3 " << dbPath << " < schema_sqlite.sql" << std::endl;
        return 1;
    }
    
    // Initialize DHT22 sensor
    DHT22Sensor dht(DHT_PIN);
    
    // Reading interval (seconds)
    int interval = 60; // Read every 60 seconds
    if (argc > 1) {
        interval = std::atoi(argv[1]);
    }
    
    std::cout << "Reading interval: " << interval << " seconds" << std::endl;
    std::cout << "Press Ctrl+C to stop\n" << std::endl;
    
    int readingCount = 0;
    int errorCount = 0;
    
    while (true) {
        float temperature = 0.0;
        float humidity = 0.0;
        
        // Read sensor (retry up to 3 times)
        bool success = false;
        for (int attempt = 0; attempt < 3; attempt++) {
            if (dht.readSensor(temperature, humidity)) {
                success = true;
                break;
            }
            delay(2000); // Wait 2 seconds before retry
        }
        
        if (success) {
            // Get current timestamp
            std::time_t now = std::time(nullptr);
            std::cout << "\n[" << std::put_time(std::localtime(&now), "%Y-%m-%d %H:%M:%S") << "]" << std::endl;
            std::cout << "Temperature: " << std::fixed << std::setprecision(1) 
                     << temperature << "°C" << std::endl;
            std::cout << "Humidity: " << std::fixed << std::setprecision(1) 
                     << humidity << "%" << std::endl;
            
            // Insert into database
            if (db.insertReading(TEMP_SENSOR_ID, temperature)) {
                std::cout << "Temperature saved" << std::endl;
            }
            
            if (db.insertReading(HUMID_SENSOR_ID, humidity)) {
                std::cout << "Humidity saved" << std::endl;
            }
            
            readingCount++;
            
            // Display statistics every 10 readings
            if (readingCount % 10 == 0) {
                db.displayLatestReadings();
            }
            
        } else {
            errorCount++;
            std::cerr << "Failed to read sensor (attempt " << errorCount << ")" << std::endl;
            
            if (errorCount > 10) {
                std::cerr << "Too many consecutive errors. Check sensor connection!" << std::endl;
            }
        }
        
        // Wait for next reading
        sleep(interval);
    }
    
    return 0;
}
