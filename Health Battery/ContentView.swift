//Last update:
//Sees the last HRV and RHR recordings during today(s) time frame and reports it in text fields. THis would glitch if there are multiple reportings in a day as it would see all recordings that day, instead of just the most recent one.

import Foundation
import HealthKit
import UIKit
import SwiftUI

let hkm = HealthKitManager()

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



//MARK: - ContentView

struct ContentView: View {
    
    @State private var variabilityValue = 0
    @State private var restingHRValue = 0
    @State private var stepsExample = 0
    @State private var arrayPrivateTest = [Double]()

    var body: some View {
        NavigationView {
            VStack {
                    Text("Last HRV Recording is: \(variabilityValue)ms")
                    Text("Last Resting HR Recording is: \(restingHRValue)ms")
                    Text("Total Steps for Day: \(stepsExample)")

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
                    Text("Authorize")
                }
                Button(action: {
                    // What to perform
                    let calendar = Calendar.current
                    let startDate = calendar.startOfDay(for: Date())
                    hkm.variability(from: startDate, to: Date()) {
                      (results) in
                        
                        var Variability = 0.0
                        
                        // results is an array of [HKQuantitySample]
                      // example conversion to BPM:
                      for result in results {
                        Variability = result.quantity.doubleValue(for: .variabilityUnit)
                        print("\(Variability)")
                      }
                        self.variabilityValue = Int(Variability)
                    }
                }) {
                    // How the button looks like
                    Text("Get HRV")
                }
                Button(action: {
                    // What to perform - Get max HRV for day?
                    let calendar = Calendar.current
                    let startDate = calendar.startOfDay(for: Date())
                    hkm.variability(from: startDate, to: Date()) {
                      (results) in
                        
                        var Variability = 0.0
                        
                        // results is an array of [HKQuantitySample]
                      // example conversion to BPM:
                      for result in results {
                        Variability = result.quantity.doubleValue(for: .variabilityUnit)
                        print("\(Variability)")
                        //We are getting an error if we try to mutate a @State variable (arrayPrivateTest). The fix is to run the @state change (Appending) on main queue.
                        arrayPrivateTest.append(Variability)
                        print(arrayPrivateTest)
                        
                      }
                        self.variabilityValue = Int(Variability)
                    }
                }) {
                    // How the button looks like
                    Text("Append Variabilities to Array")
                }
                Button(action: {
                    // What to perform - Get max HRV for day?
                    print(arrayPrivateTest)
                }) {
                    // How the button looks like
                    Text("Print Array Externally")
                }
                Button(action: {
                    // What to perform - Get max HRV for day?
                    print(arrayPrivateTest.max()!)
                }) {
                    // How the button looks like
                    Text("Print Max Array Externally")
                }
                Button(action: {
                    // What to perform
                    // Need to look back to see how to accept healthkit authorizations
                    let calendar = Calendar.current
                    let startDate = calendar.startOfDay(for: Date())
                    hkm.restingHeartRate(from: startDate, to: Date()) {
                      (results) in
                        
                        var lastRestingHR = 0.0
                        // results is an array of [HKQuantitySample]
                      // example conversion to BPM:
                      for result in results {
                        lastRestingHR = result.quantity.doubleValue(for: .heartRateUnit)
                        print("\(lastRestingHR)")
                      }
                        self.restingHRValue = Int(lastRestingHR)
                    }
                }) {
                    // How the button looks like
                    Text("Get Resting Heart Rate")
                }
                }
            }
        }
    }
