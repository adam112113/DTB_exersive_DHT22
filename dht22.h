#ifndef DHT22_H
#define DHT22_H

/*
 * DHT22 Temperature and Humidity Sensor Library
 * For Raspberry Pi using WiringPi
 * 
 * More reliable implementation with better error handling
 */

#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define MAXTIMINGS 85

class DHT22 {
private:
    int pin;
    int dht22_dat[5];

public:
    DHT22(int gpio_pin) : pin(gpio_pin) {
        dht22_dat[0] = dht22_dat[1] = dht22_dat[2] = dht22_dat[3] = dht22_dat[4] = 0;
    }

    bool read(float &temperature, float &humidity) {
        uint8_t laststate = HIGH;
        uint8_t counter = 0;
        uint8_t j = 0, i;

        dht22_dat[0] = dht22_dat[1] = dht22_dat[2] = dht22_dat[3] = dht22_dat[4] = 0;

        // Pull pin down for 18 milliseconds
        pinMode(pin, OUTPUT);
        digitalWrite(pin, LOW);
        delay(18);
        
        // Pull pin up for 40 microseconds
        digitalWrite(pin, HIGH);
        delayMicroseconds(40);
        
        // Prepare to read the pin
        pinMode(pin, INPUT);

        // Detect change and read data
        for (i = 0; i < MAXTIMINGS; i++) {
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
                // Shove each bit into the storage bytes
                dht22_dat[j / 8] <<= 1;
                if (counter > 16)
                    dht22_dat[j / 8] |= 1;
                j++;
            }
        }

        // Check we read 40 bits (8bit x 5 ) + verify checksum in the last byte
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
};

#endif // DHT22_H
