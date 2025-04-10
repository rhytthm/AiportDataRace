import UIKit

// MARK: Question
/*
 Consider an airport with 5 airstrips used for landing and takeoff.
 Pilot requests the airport for landing/takeoff at any given time, if any airstrip is available at that time, booking is made.
 We need to design software which the pilot can use to make this request.
 Let’s assume everything to be local.
 Also, for the sake of simplicity, let’s store data in memory.
 */

// MARK: My Try
//struct Airstrip {
//    var id = UUID()
//    // Date -> Availablity(Bool)
//    var availabilityDict: [Date: Bool] = [:]
//}
//
//struct Airport {
//    var airstrips: [Airstrip] = [Airstrip()]
//}
//
//let airport = AirportManager()
//let date = Date()
//airport.getAirstrip()
//
//protocol AirportProtocol {
//    var airport: Airport { get }
//    func getAirstrip(date: Date) -> Airstrip?
//}
//
//class AirportManager: AirportExample {
//    let airport = Airport()
//    func getAirstrip(date: Date = Date()) -> Airstrip? {
//        let lock = NSLock()
//        lock.lock()
//        return airport.requestLandingOrTakeoff(time: date)
//        defer {
//            lock.unlock()
//        }
//    }
//    func requestLandingOrTakeoff(time: Date = Date()) -> Airstrip? {
//        for i in 0..<airstrips.count {
//            var airstrip = airstrips[i]
//            if airstrip.availabilityDict[time] == false || airstrip.availabilityDict[time] == nil {
//                airstrip.availabilityDict[time] = true
//                return airstrip
//            }
//        }
//        return nil
//    }
//    
//}
//
//class mumbaiAirport: AirportExample {
//    var airport: Airport
//    
//    func getAirstrip(date: Date) -> Airstrip? {
//        <#code#>
//    }
//    
//    
//}

/*
 airport, airstips -> Entity Module
 
 < AirportProtocol > -> Abstraction
 
 AirportManager -> Main core logic
 
 Entity Module <- AirportManager -> Abstraction <- Main Implentation
 */

// MARK: - Entities

class Airstrip {
    let id = UUID()
    var availabilityDict: [Date: Bool] = [:]
}

struct Airport {
    var airstrips: [Airstrip]
}

// MARK: - Protocol

protocol AirportProtocol {
    func getAirstrip(for date: Date) -> Airstrip?
}

// MARK: - NSLock Manager

class AirportManager: AirportProtocol {
    private var airport: Airport
    private let lock = NSLock()

    init() {
        let airstrips = Array(repeating: Airstrip(), count: 5)
        self.airport = Airport(airstrips: airstrips)
    }

    func getAirstrip(for date: Date = Date()) -> Airstrip? {
        lock.lock()
        defer { lock.unlock() }

        for airstrip in airport.airstrips {
            if airstrip.availabilityDict[date] != true {
                airstrip.availabilityDict[date] = true
                return airstrip
            }
        }

        return nil
    }
}

// MARK: - Dispatch Barrier Manager

class BarrierAirportManager: AirportProtocol {
    private var airport: Airport
    private let barrier = DispatchQueue(label: "com.example.barrierQueue", attributes: .concurrent)

    init() {
        let airstrips = Array(repeating: Airstrip(), count: 5)
        self.airport = Airport(airstrips: airstrips)
    }

    func getAirstrip(for date: Date = Date()) -> Airstrip? {
        return barrier.sync(flags: .barrier) {
            for airstrip in airport.airstrips {
                if airstrip.availabilityDict[date] != true {
                    airstrip.availabilityDict[date] = true
                    return airstrip
                }
            }
            return nil
        }
    }
}

// MARK: - Semaphore Manager

class SemaphoreAirportManager: AirportProtocol {
    private var airport: Airport
    private let semaphore = DispatchSemaphore(value: 1)

    init() {
        let airstrips = Array(repeating: Airstrip(), count: 5)
        self.airport = Airport(airstrips: airstrips)
    }

    func getAirstrip(for date: Date = Date()) -> Airstrip? {
        semaphore.wait()
        defer { semaphore.signal() }

        for airstrip in airport.airstrips {
            if airstrip.availabilityDict[date] != true {
                airstrip.availabilityDict[date] = true
                return airstrip
            }
        }

        return nil
    }
}

// MARK: Dependency Graph for the Module
/*
 ┌────────────────────┐
 │    Airstrip        │◄────────────┐
 └────────────────────┘             │
                                    │
 ┌────────────────────┐             ▼
 │     Airport        │────────► Airstrip[]
 └────────────────────┘
         ▲
         │
 ┌────────────────────┐
 │  AirportProtocol   │◄──────────────┐
 └────────────────────┘               │
         ▲                            │
         │                            │
 ┌────────────────────┐               ▼
 │  AirportManager    │────────► Airport
 └────────────────────┘
         ▲
         │
 ┌────────────────────┐
 │  Consumer Module   │ (UI, CLI, Test)
 └────────────────────┘
 
 AirportModule/
 ├── Entities/
 │   ├── Airstrip.swift
 │   └── Airport.swift
 │
 ├── Protocols/
 │   └── AirportProtocol.swift
 │
 ├── Managers/
 │   └── AirportManager.swift
 │
 └── Consumer/
     └── Consumer.swift
 
 */

// MARK: Testing
// Same Date
func testSame(manager: AirportProtocol, label: String) {
    print("🧪 Testing Same Date: \(label)")
    
    let date = Date()
    var bookedAirstrips: [UUID] = []
    let lock = NSLock() // To safely append to results array

    let group = DispatchGroup()

    for _ in 0..<10 {
        DispatchQueue.global().async(group: group) {
            if let strip = manager.getAirstrip(for: date) {
                lock.lock()
                bookedAirstrips.append(strip.id)
                lock.unlock()
            }
        }
    }

    group.wait()

    print("✅ Booked airstrips: \(bookedAirstrips.count)")
    print("🆔 Unique IDs: \(Set(bookedAirstrips).count)")
    print("-----")
}

// Different Dates
func testDiff(manager: AirportProtocol, label: String) {
    print("🧪 Testing Different: \(label)")

    var bookedAirstrips: [UUID] = []
    let lock = NSLock()
    let group = DispatchGroup()
    let baseDate = Date()

    for i in 0..<10 {
        group.enter()
        DispatchQueue.global().async {
            let requestDate = baseDate.addingTimeInterval(Double(i) * 0.001) // slight difference per thread
            if let strip = manager.getAirstrip(for: requestDate) {
                lock.lock()
                bookedAirstrips.append(strip.id)
                lock.unlock()
            }
            group.leave()
        }
    }

    group.wait()

    print("✅ Booked airstrips: \(bookedAirstrips.count)")
    print("🆔 Unique IDs: \(Set(bookedAirstrips).count)")
    print("-----")
}

let nsLockManager = AirportManager()
testSame(manager: nsLockManager, label: "NSLock Manager")
testDiff(manager: nsLockManager, label: "NSLock Manager")
let barrierManager = BarrierAirportManager()
testSame(manager: barrierManager, label: "Dispatch Barrier Manager")
testDiff(manager: nsLockManager, label: "Dispatch Barrier Manager")
let semaphoreManager = SemaphoreAirportManager()
testSame(manager: semaphoreManager, label: "Semaphore Manager")
testDiff(manager: nsLockManager, label: "Semaphore Manager")
