# 🔌 DHT22 Wiring Guide for Raspberry Pi

## DHT22 Sensor Pinout

```
   Front View (Grid facing you)
   ┌─────────────────┐
   │  ▓▓▓▓▓▓▓▓▓▓▓▓▓  │
   │  ▓▓▓▓▓▓▓▓▓▓▓▓▓  │  ← Grid pattern
   │  ▓▓▓▓▓▓▓▓▓▓▓▓▓  │
   └─────────────────┘
     │ │ │ │
     1 2 3 4
```

### Pin Functions
- **Pin 1:** VCC (Power) - 3.3V to 5V
- **Pin 2:** DATA (Signal) - Digital I/O
- **Pin 3:** NC (Not Connected) - Leave empty
- **Pin 4:** GND (Ground)

---

## Raspberry Pi GPIO Layout

```
Raspberry Pi 40-Pin GPIO Header
================================

    3.3V [ 1] [ 2]  5V
   GPIO2 [ 3] [ 4]  5V
   GPIO3 [ 5] [ 6]  GND
   GPIO4 [ 7] [ 8]  GPIO14
     GND [ 9] [10]  GPIO15
  GPIO17 [11] [12]  GPIO18
  GPIO27 [13] [14]  GND
  GPIO22 [15] [16]  GPIO23
    3.3V [17] [18]  GPIO24
  GPIO10 [19] [20]  GND
   GPIO9 [21] [22]  GPIO25
  GPIO11 [23] [24]  GPIO8
     GND [25] [26]  GPIO7
   GPIO0 [27] [28]  GPIO1
   GPIO5 [29] [30]  GND
   GPIO6 [31] [32]  GPIO12
  GPIO13 [33] [34]  GND
  GPIO19 [35] [36]  GPIO16
  GPIO26 [37] [38]  GPIO20
     GND [39] [40]  GPIO21
```

---

## Connection Diagram

```
DHT22 Sensor                      Raspberry Pi
═══════════                       ════════════

Pin 1 (VCC)  ─────────────────────► Pin 1  (3.3V)
                    │
                   ┌┴┐  ← 10kΩ Pull-up Resistor
                   │ │
                   └┬┘
                    │
Pin 2 (DATA) ───────┴──────────────► Pin 7  (GPIO4/BCM4)

Pin 3 (NC)   ─────── X (Not connected)

Pin 4 (GND)  ─────────────────────► Pin 6  (GND)
```

---

## Step-by-Step Wiring

### What You Need
- DHT22 sensor
- 10kΩ resistor (brown-black-orange bands)
- Breadboard (optional but recommended)
- 3x Female-to-Female jumper wires
- 1x Male jumper wire (for resistor)

### Step 1: Connect Power (VCC)
```
DHT22 Pin 1 ──► Breadboard ──► Resistor ──► Raspberry Pi Pin 1 (3.3V)
```

### Step 2: Connect Data
```
DHT22 Pin 2 ──► Breadboard ──► Raspberry Pi Pin 7 (GPIO4)
                   ↑
                   └─── Resistor from VCC connects here
```

### Step 3: Connect Ground
```
DHT22 Pin 4 ──► Raspberry Pi Pin 6 (GND)
```

---

## Breadboard Layout

```
Raspberry Pi             Breadboard                  DHT22
════════════             ══════════                  ═════

Pin 1 (3.3V) ───────► [+] Rail ───┐
                                   │
                              [10kΩ Resistor]
                                   │
                                   ├──────────────► Pin 2 (DATA)
Pin 7 (GPIO4) ──────► Row 5 ───────┘
                                   └──────────────► Pin 1 (VCC)

Pin 6 (GND)  ───────► [-] Rail ────────────────► Pin 4 (GND)

                      Pin 3 (NC) ── X (not connected)
```

---

## Visual ASCII Diagram

```
                        10kΩ
     3.3V ──────────────/\/\/\────┐
      │                           │
      │                           │
      │                      ┌────┴────┐
      └──────────────────────┤ DHT22   │
                             │  Pin 1  │
                             └─────────┘
                             ┌─────────┐
     GPIO4 ──────────────────┤ DHT22   │
                             │  Pin 2  │
                             └─────────┘
                             ┌─────────┐
                        X ───┤ DHT22   │
                             │  Pin 3  │
                             └─────────┘
                             ┌─────────┐
     GND ────────────────────┤ DHT22   │
                             │  Pin 4  │
                             └─────────┘
```

---

## Important Notes

### ⚠️ Critical: Pull-up Resistor
**The 10kΩ resistor is REQUIRED!** It pulls the DATA line high.

```
Without resistor: ❌ Unreliable readings, frequent errors
With resistor:    ✅ Stable, consistent readings
```

### Power Options
- **3.3V (Pin 1):** ✅ Recommended - safer, works perfectly
- **5V (Pins 2/4):** ⚠️ Works but higher power consumption

### GPIO Pin Options
We use **GPIO4 (Physical Pin 7)** but you can use any GPIO pin:
- GPIO17 (Pin 11)
- GPIO27 (Pin 13)
- GPIO22 (Pin 15)
- etc.

**If changing:** Update in `sensor_monitor.cpp`:
```cpp
#define DHT_PIN 4   // Change to your GPIO number (BCM)
```

---

## Cable Color Convention (Typical)

```
Red    → VCC (3.3V)    → DHT22 Pin 1
Yellow → DATA (GPIO4)  → DHT22 Pin 2
Black  → GND           → DHT22 Pin 4
```

---

## Common Wiring Mistakes

### ❌ Wrong
```
1. No pull-up resistor
2. Using wrong GPIO pin number (mixing BCM vs Physical)
3. Loose connections
4. Reversed VCC and GND
```

### ✅ Correct
```
1. 10kΩ resistor between VCC and DATA
2. GPIO4 (BCM) = Physical Pin 7
3. Secure, tight connections
4. VCC to 3.3V, GND to GND
```

---

## Testing Your Wiring

### Visual Check
1. Count pins carefully (1-2-3-4 from left when facing grid)
2. Verify resistor is connected (should be visible)
3. Check all connections are secure

### Software Test
```bash
# Compile test program
g++ -o test_dht22 test_dht22.cpp -lwiringPi -std=c++11

# Run test (requires sudo for GPIO access)
sudo ./test_dht22
```

### Expected Output
```
✓ Reading #1
  🌡️  Temperature: 22.3°C
  💧 Humidity: 45.2%
```

### If Errors Occur
- Check resistor is present
- Verify pin numbers (Physical 7 = BCM GPIO4)
- Try reseating connections
- Test with multimeter (VCC should show ~3.3V)

---

## Troubleshooting Voltage Check

```bash
# Check GPIO voltage (requires wiringPi)
gpio -v
gpio readall
```

Expected output for Pin 7 (GPIO4):
```
 +-----+-----+---------+------+---+---Pi 4---+---+------+---------+-----+-----+
 | BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
 +-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
 |     |     |    3.3v |      |   |  1 || 2  |   |      | 5v      |     |     |
 |   2 |   8 |   SDA.1 |   IN | 1 |  3 || 4  |   |      | 5v      |     |     |
 |   3 |   9 |   SCL.1 |   IN | 1 |  5 || 6  |   |      | 0v      |     |     |
 |   4 |   7 | GPIO. 7 |   IN | 1 |  7 || 8  | 1 | IN   | TxD     | 15  | 14  |
       ↑           ↑                  ↑
      BCM       Name              Physical Pin
```

---

## Advanced: Module vs Bare Sensor

### DHT22 Module (with built-in resistor)
```
Has 3 pins, resistor already included
Just connect: VCC, DATA, GND
```

### DHT22 Bare Sensor (4 pins)
```
Has 4 pins, YOU must add resistor
Connect as shown in this guide
```

---

## Photo Checklist

Before powering on:
- [ ] DHT22 Pin 1 connected to Raspberry Pi Pin 1 (3.3V)
- [ ] DHT22 Pin 2 connected to Raspberry Pi Pin 7 (GPIO4)
- [ ] DHT22 Pin 4 connected to Raspberry Pi Pin 6 (GND)
- [ ] 10kΩ resistor between VCC (Pin 1) and DATA (Pin 2)
- [ ] All connections secure
- [ ] No short circuits visible

---

## Need Help?

1. Double-check pin numbers using `gpio readall`
2. Use multimeter to verify 3.3V on VCC
3. Check resistor value (brown-black-orange = 10kΩ)
4. Try the test program first before the main application

---

**Once wired correctly, the sensor should work reliably!** 🌡️💧
