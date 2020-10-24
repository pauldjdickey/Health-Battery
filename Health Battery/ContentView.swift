//Last update:
//Sees the last HRV and RHR recordings during today(s) time frame and reports it in text fields. THis would glitch if there are multiple reportings in a day as it would see all recordings that day, instead of just the most recent one.

import Foundation
import HealthKit
import UIKit
import SwiftUI

let hkm = HealthKitManager()

var arrayVariability7Day2 = [Double]()
var arrayRHR7Day2 = [Double]()
var mostRecentHRV = 0.0
var mostRecentRHR = 0.0
var max7DayHRV = 0.0
var min7DayHRV = 0.0
var max7DayRHR = 0.0
var min7DayRHR = 0.0
var recoveryRHRPercentageValue = 0.0
var recoveryHRVPercentageValue = 0.0
var finalRecoveryPercentageValue = 0.0




let calendar = Calendar.current
let startDate = calendar.startOfDay(for: Date())
let yesterdayStartDate = calendar.startOfDay(for: Date.yesterday)
let weekAgoStartDate = calendar.startOfDay(for: Date.weekAgo)
let monthAgoStartDate = calendar.startOfDay(for: Date.monthAgo)

private enum HealthkitSetupError: Error {
  case notAvailableOnDevice
  case dataTypeNotAvailable
}

func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
  //1. Check to see if HealthKit Is Available on this device
  guard HKHealthStore.isHealthDataAvailable() else {
    completion(false, HealthkitSetupError.notAvailableOnDevice)
    return
  }
  //2. Prepare the data types that will interact with HealthKit
  guard   let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
          let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
          let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
          let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
          let height = HKObjectType.quantityType(forIdentifier: .height),
          let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
          let variability = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
          let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
          let stepsTest = HKObjectType.quantityType(forIdentifier: .stepCount),
          let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
          
          completion(false, HealthkitSetupError.dataTypeNotAvailable)
          return
  }
  //3. Prepare a list of types you want HealthKit to read and write
  let healthKitTypesToWrite: Set<HKSampleType> = [bodyMassIndex,
                                                  activeEnergy,
                                                  HKObjectType.workoutType()]
      
  let healthKitTypesToRead: Set<HKObjectType> = [dateOfBirth,
                                                 bloodType,
                                                 biologicalSex,
                                                 bodyMassIndex,
                                                 height,
                                                 stepsTest,
                                                 variability,
                                                 restingHR,
                                                 bodyMass,
                                                 HKObjectType.workoutType()]
  //4. Request Authorization
  HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
                                       read: healthKitTypesToRead) { (success, error) in
    completion(success, error)
  }
  
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    static var weekAgo: Date { return Date().weekAgo }
    static var monthAgo: Date { return Date().monthAgo }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var weekAgo: Date {
        return Calendar.current.date(byAdding: .day, value: -7, to: noon)!
    }
    var monthAgo: Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

// MARK: - Most Recent Variability Function

func mostRecentHRVFunction() {
    hkm.variabilityMostRecent(from: yesterdayStartDate, to: Date()) {
      (results) in
        
        var lastHRV = 0.0
        
        // results is an array of [HKQuantitySample]
      // example conversion to BPM:
      for result in results {
        lastHRV = result.quantity.doubleValue(for: .variabilityUnit)
      }
        mostRecentHRV = Double(lastHRV)
        print("Last HRV: \(mostRecentHRV)")

    }
    finalRecoveryPercentage()
}

// MARK: - Most Recent RHR Function

func mostRecentRHRFunction() {
    hkm.restingHeartRateMostRecent(from: yesterdayStartDate, to: Date()) {
      (results) in
        
        var lastRestingHR = 0.0
        // results is an array of [HKQuantitySample]
      // example conversion to BPM:
      for result in results {
        lastRestingHR = result.quantity.doubleValue(for: .heartRateUnit)
      }
        mostRecentRHR = Double(lastRestingHR)
        print("Last RHR: \(mostRecentRHR)")

    }
    finalRecoveryPercentage()
}

// MARK: - 7 Day Variability Function

func weekVariabilityArrayFunction() {
    //arrayVariability7Day2.removeAll()
    hkm.variability(from: weekAgoStartDate, to: Date()) {
      (results) in
        
        var Variability = 0.0
        
        // results is an array of [HKQuantitySample]
      // example conversion to BPM:
      for result in results {
        Variability = result.quantity.doubleValue(for: .variabilityUnit)
        //Need to run this in a main queue becuase its so much
            arrayVariability7Day2.append(Variability)

      }
        print("Array for Variability: \(arrayVariability7Day2)")
        weekHRVMax()
        weekHRVMin()
        recoveryHRVPercentage()
        finalRecoveryPercentage()
    }
}
// MARK: - 7 Day RHR Function

func weekRHRArrayFunction() {
    //arrayRHR7Day2.removeAll()
    hkm.restingHeartRate(from: weekAgoStartDate, to: Date()) {
      (results) in
        
        var RHR = 0.0
        
        // results is an array of [HKQuantitySample]
      // example conversion to BPM:
      for result in results {
        RHR = result.quantity.doubleValue(for: .heartRateUnit)
        //Need to run this in a main queue becuase its so much
            arrayRHR7Day2.append(RHR)

      }
        print("Array for RHR: \(arrayRHR7Day2)")
        weekRHRMax()
        weekRHRMin()
        recoveryRHRPercentage()
        finalRecoveryPercentage()
    }
}

// MARK: - 7 Day Max HRV Function
func weekHRVMax() {
    max7DayHRV = arrayVariability7Day2.max() ?? 0
    print("Max 7 Day HRV:\(max7DayHRV)")
}


// MARK: - 7 Day Min HRV Function
func weekHRVMin() {
    min7DayHRV = arrayVariability7Day2.min() ?? 0
    print("Min 7 Day HRV:\(min7DayHRV)")
}

// MARK: - 7 Day Max RHR Function
func weekRHRMax() {
    max7DayRHR = arrayRHR7Day2.max() ?? 0
    print("Max 7 Day RHR:\(max7DayRHR)")
}

// MARK: - 7 Day Min RHR Function
func weekRHRMin() {
    min7DayRHR = arrayRHR7Day2.min() ?? 0
    print("Min 7 day RHR:\(min7DayRHR)")
}

// MARK: - HRV Calculate Rating per Min/Max
func recoveryHRVPercentage() {
    recoveryHRVPercentageValue = ((mostRecentHRV - min7DayHRV) / (max7DayHRV - min7DayHRV))*100
    print("Recovery HRV %: \(recoveryHRVPercentageValue)")
}

// MARK: - RHR Calculate Rating per Min/Max
func recoveryRHRPercentage() {
    recoveryRHRPercentageValue = (1-((mostRecentRHR - min7DayRHR) / (max7DayRHR - min7DayRHR)))*100
    print("Recovery RHR %: \(recoveryRHRPercentageValue)")
}

// MARK: - 50/50 Recovery Calculation
func finalRecoveryPercentage() {
    finalRecoveryPercentageValue = (recoveryHRVPercentageValue + recoveryRHRPercentageValue) / 2
    print("Final Recovery %: \(finalRecoveryPercentageValue)")
    
}

// MARK: - Second to Last Function
func calculateScore() {
        mostRecentHRVFunction()
        mostRecentRHRFunction()
        weekVariabilityArrayFunction()
        weekRHRArrayFunction()

}

// MARK: - Final Function




//MARK: - ContentView

struct ContentView: View {
    
    @State private var lastVariabilityValue = 0
    @State private var lastHRVValue = 0
    @State private var lastRHRValue = 0
    @State private var restingHRValue = 0
    @State private var stepsExample = 0
    @State private var finalRecoveryPercentage = 0
    @State private var finalRHRPercentage = 0
    @State private var finalHRVPercentage = 0
    @State private var arrayVariability7Day = [Double]()
    @State var sliderValue: Double = 0

    var body: some View {
        NavigationView {
            VStack {
                    Text("Last RHR Value: \(lastRHRValue) BPM")
                    Text("Last HRV Value: \(lastHRVValue) MS")
                    Text("HRV Recovery: \(finalHRVPercentage) %")
                    Text("RHR Recovery: \(finalRHRPercentage) %")
                // Put calculated score below
                    Text("\(finalRecoveryPercentage)%")
                        .fontWeight(.regular)
                        .font(.system(size: 70))

                Button(action: {
                        calculateScore()
                    self.finalRecoveryPercentage = Int(finalRecoveryPercentageValue)
                    self.finalRHRPercentage = Int(recoveryRHRPercentageValue)
                    self.finalHRVPercentage = Int(recoveryHRVPercentageValue)
                    self.lastHRVValue = Int(mostRecentHRV)
                    self.lastRHRValue = Int(mostRecentRHR)
                    
                    print("@state is: \(finalRecoveryPercentage)")
                }) {
                    // How the button looks like
                    Text("Press Me Twice")
                }
                Slider(value: $sliderValue, in: 0...100)
                Text("How Recovered I Actually Feel: \(sliderValue, specifier: "%.0f")%")
            }.padding()
            }
        Button(action: {
            // What to perform
            // Need to look back to see how to accept healthkit authorizations
            authorizeHealthKit { (authorized, error) in
                  
              guard authorized else {
                    
                let baseMessage = "HealthKit Authorization Failed"
                    
                if let error = error {
                  print("\(baseMessage). Reason: \(error.localizedDescription)")
                } else {
                  print(baseMessage)
                }
                    
                return
              }
                  
              print("HealthKit Successfully Authorized.")
            }
        }) {
            // How the button looks like
            Text("Authorize HealthKit")
        }
        }
    }
