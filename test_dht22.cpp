/*
 * Simple DHT22 Test Program
 * Use this to verify your sensor is working before running the full monitoring system
 * 
 * Compile: g++ -o test_dht22 test_dht22.cpp -lwiringPi -std=c++11
 * Run: sudo ./test_dht22
 */

#include <iostream>
#include <iomanip>
#include <wiringPi.h>
#include <unistd.h>

#define DHT_PIN 4       // GPIO pin (BCM numbering)
#define MAX_TIMINGS 85

int dht22_dat[5] = {0, 0, 0, 0, 0};

bool readDHT22(float &temperature, float &humidity) {
    uint8_t laststate = HIGH;
    uint8_t counter = 0;
    uint8_t j = 0, i;

    dht22_dat[0] = dht22_dat[1] = dht22_dat[2] = dht22_dat[3] = dht22_dat[4] = 0;

    // Pull pin down for 18 milliseconds
    pinMode(DHT_PIN, OUTPUT);
    digitalWrite(DHT_PIN, LOW);
    delay(18);
    
    // Pull pin up for 40 microseconds
    digitalWrite(DHT_PIN, HIGH);
    delayMicroseconds(40);
    
    // Prepare to read the pin
    pinMode(DHT_PIN, INPUT);

    // Detect change and read data
    for (i = 0; i < MAX_TIMINGS; i++) {
        counter = 0;
        while (digitalRead(DHT_PIN) == laststate) {
            counter++;
            delayMicroseconds(1);
            if (counter == 255) {
                break;
            }
        }
        laststate = digitalRead(DHT_PIN);

        if (counter == 255) break;

        // Ignore first 3 transitions
        if ((i >= 4) && (i % 2 == 0)) {
            dht22_dat[j / 8] <<= 1;
            if (counter > 16)
                dht22_dat[j / 8] |= 1;
            j++;
        }
    }

    // Check we read 40 bits and verify checksum
    if ((j >= 40) && (dht22_dat[4] == ((dht22_dat[0] + dht22_dat[1] + dht22_dat[2] + dht22_dat[3]) & 0xFF))) {
        float h = (float)((dht22_dat[0] << 8) + dht22_dat[1]) / 10.0;
        float t = (float)(((dht22_dat[2] & 0x7F) << 8) + dht22_dat[3]) / 10.0;
        
        if (dht22_dat[2] & 0x80) {
            t = -t;
        }
        
        // Sanity check
        if (h >= 0.0 && h <= 100.0 && t >= -40.0 && t <= 80.0) {
            temperature = t;
            humidity = h;
            return true;
        }
    }

    return false;
}

int main() {
    std::cout << "DHT22 Sensor Test Program" << std::endl;
    std::cout << "=============================" << std::endl;
    std::cout << "GPIO Pin: " << DHT_PIN << " (BCM numbering)" << std::endl;
    std::cout << "Reading every 3 seconds..." << std::endl;
    std::cout << "Press Ctrl+C to stop\n" << std::endl;
    
    if (wiringPiSetup() == -1) {
        std::cerr << "Failed to initialize wiringPi" << std::endl;
        std::cerr << "Make sure you run this with: sudo ./test_dht22" << std::endl;
        return 1;
    }
    
    int successCount = 0;
    int errorCount = 0;
    
    while (true) {
        float temperature = 0.0;
        float humidity = 0.0;
        
        if (readDHT22(temperature, humidity)) {
            successCount++;
            std::cout << "Reading #" << successCount << std::endl;
            std::cout << "Temperature: " << std::fixed << std::setprecision(1) 
                     << temperature << "°C" << std::endl;
            std::cout << "Humidity: " << std::fixed << std::setprecision(1) 
                     << humidity << "%" << std::endl;
            std::cout << std::endl;
            errorCount = 0; // Reset error counter on success
        } else {
            errorCount++;
            std::cout << "Failed to read sensor (error #" << errorCount << ")" << std::endl;
            
            if (errorCount == 1) {
                std::cout << "   Tip: DHT22 can be temperamental. Trying again..." << std::endl;
            } else if (errorCount == 5) {
                std::cout << "   Multiple failures detected!" << std::endl;
                std::cout << "   Check your wiring:" << std::endl;
                std::cout << "   - DHT22 Pin 1 (VCC)  → Raspberry Pi 3.3V" << std::endl;
                std::cout << "   - DHT22 Pin 2 (DATA) → Raspberry Pi GPIO4" << std::endl;
                std::cout << "   - DHT22 Pin 4 (GND)  → Raspberry Pi GND" << std::endl;
                std::cout << "   - 10kΩ resistor between VCC and DATA" << std::endl;
            } else if (errorCount > 10) {
                std::cout << " Too many errors. Sensor may be faulty or incorrectly wired." << std::endl;
                return 1;
            }
        }
        
        // DHT22 requires at least 2 seconds between readings
        sleep(3);
    }
    
    return 0;
}
