# Makefile for Sensor Monitoring System
# Simple compilation without CMake

CXX = g++
CXXFLAGS = -Wall -std=c++11
LIBS = -lsqlite3 -lwiringPi -lpthread
TARGET = sensor_monitor
SOURCES = sensor_monitor.cpp
DB_FILE = $(HOME)/sensor_monitoring.db

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SOURCES) $(LIBS)

install: $(TARGET)
	sudo cp $(TARGET) /usr/local/bin/

database:
	sqlite3 $(DB_FILE) < schema_sqlite.sql
	@echo "Database created at $(DB_FILE)"

clean:
	rm -f $(TARGET)

run: $(TARGET)
	sudo ./$(TARGET) 60

test: $(TARGET)
	sudo ./$(TARGET) 5

.PHONY: all install database clean run test
