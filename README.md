# ✈️ AirportDataRace

This is a Swift Playground project simulating a **concurrent airport airstrip booking system**. It tests thread-safe data structures by simulating multiple pilots requesting landing/takeoff slots at the same time.

## 🧠 Problem Statement

> An airport has 5 airstrips.  
> At any given moment, a pilot requests the airport for landing or takeoff.  
> If any airstrip is available at the requested time, booking is granted.  
> All data is stored in memory and the system is accessed concurrently.  

---

## 🏗️ Architecture Overview
Airstrip          <- Entity
Airport           <- Holds array of Airstrips
AirportProtocol   <- Abstraction
AirportManager    <- Core logic (with concurrency control)
Test Module       <- Simulates concurrent booking scenarios

Managers Implemented:
- ✅ `AirportManager` (with `NSLock`)
- ✅ `BarrierAirportManager` (with `DispatchQueue + .barrier`)
- ✅ `SemaphoreAirportManager` (with `DispatchSemaphore`)


## 🚀 Features

- In-memory airstrip booking
- Thread-safe booking logic using 3 different approaches
- Stress tests using concurrent threads
- Booking tests for:
  - Same `Date()` used across threads (high contention)
  - Slightly offset dates (more distributed load)

---

## 🔬 Test Examples

Tests simulate 10 concurrent pilots requesting a booking:

- **`testSame()`** – All threads request the *exact same date*
- **`testDiff()`** – Threads request slightly *offset dates* (1ms apart)

Each test logs:
- Total successful bookings
- Unique airstrips assigned
