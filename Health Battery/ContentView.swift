//Last update:
//Sees the last HRV and RHR recordings during today(s) time frame and reports it in text fields. THis would glitch if there are multiple reportings in a day as it would see all recordings that day, instead of just the most recent one.

import Foundation
import HealthKit
import UIKit
import SwiftUI
import CoreData
import Dispatch

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


    //Array
var arrayHRV = [Double]()
var arrayRHR = [Double]()
var arrayNumbers = [NSManagedObject]()
    //Recent
var recentHRV = 0.0
var recentRHR = 0.0
var arrayHRVDone = false
var arrayRHRDone = false
    // Min/Max
var maxHRV = 0.0
var minHRV = 0.0
var maxRHR = 0.0
var minRHR = 0.0
var minHRVDone = false
var maxHRVDone = false
var minRHRDone = false
var maxRHRDone = false
    // HRV/RHR Calculation
var hrvRecoveryPercentage = 0.0
var rhrRecoveryPercentage = 0.0
var hrvPercentageDone = false
var rhrPercentageDone = false
    // Final Calculation
var finalRecoveryPercentage2 = 0.0
var finalRecoveryIndicator = false


typealias FinishedGettingHealthData = () -> ()



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

// MARK: - Model Manipulation Methods

//func saveItems() {
//    do {
//        try context.save()
//    } catch {
//        print("Error saving context \(error)")
//    }
//}

// MARK: - Most Recent Variability Function

func mostRecentHRVFunction(_ completion : @escaping()->()) {
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
        print("first")
        completion()
        
    }
}

// MARK: - Most Recent RHR Function

func mostRecentRHRFunction(_ completion : @escaping()->()) {
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
        print("second")
        completion()

    }
}

// MARK: - 7 Day Variability Function

func weekVariabilityArrayFunction(_ completion : @escaping()->()) {
    //arrayVariability7Day2.removeAll()
    hkm.variability(from: weekAgoStartDate, to: Date()) {
        (results) in
        
        arrayVariability7Day2.removeAll()
        var Variability = 0.0
        
        // results is an array of [HKQuantitySample]
        // example conversion to BPM:
        for result in results {
            Variability = result.quantity.doubleValue(for: .variabilityUnit)
            //Need to run this in a main queue becuase its so much
            arrayVariability7Day2.append(Variability)
            
        }
        print("Array for Variability: \(arrayVariability7Day2)")
        print("third")
        completion()

    }
}
// MARK: - 7 Day RHR Function

func weekRHRArrayFunction(_ completion : @escaping()->()) {
    //arrayRHR7Day2.removeAll()
    hkm.restingHeartRate(from: weekAgoStartDate, to: Date()) {
        (results) in
        arrayRHR7Day2.removeAll()
        var RHR = 0.0
        
        // results is an array of [HKQuantitySample]
        // example conversion to BPM:
        for result in results {
            RHR = result.quantity.doubleValue(for: .heartRateUnit)
            //Need to run this in a main queue becuase its so much
            arrayRHR7Day2.append(RHR)
            
        }
        print("Array for RHR: \(arrayRHR7Day2)")
        print("fourth")
        completion()

//        weekRHRMax()
//        weekRHRMin()
//        recoveryRHRPercentage()
//        finalRecoveryPercentage()
    }
}

// MARK: - 7 Day Max HRV Function
func weekHRVMax(_ completion : @escaping()->()) {
    max7DayHRV = arrayVariability7Day2.max() ?? 0
    print("Max 7 Day HRV:\(max7DayHRV)")
    print("fifth")
    completion()

}


// MARK: - 7 Day Min HRV Function
func weekHRVMin(_ completion : @escaping()->()) {
    min7DayHRV = arrayVariability7Day2.min() ?? 0
    print("Min 7 Day HRV:\(min7DayHRV)")
    print("sixth")
    completion()

}

// MARK: - 7 Day Max RHR Function
func weekRHRMax(_ completion : @escaping()->()) {
    max7DayRHR = arrayRHR7Day2.max() ?? 0
    print("Max 7 Day RHR:\(max7DayRHR)")
    print("seventh")
    completion()

}

// MARK: - 7 Day Min RHR Function
func weekRHRMin(_ completion : @escaping()->()) {
    min7DayRHR = arrayRHR7Day2.min() ?? 0
    print("Min 7 day RHR:\(min7DayRHR)")
    print("eighth")
    completion()

}

// MARK: - HRV Calculate Rating per Min/Max
func recoveryHRVPercentage(_ completion : @escaping()->()) {
    recoveryHRVPercentageValue = ((mostRecentHRV - min7DayHRV) / (max7DayHRV - min7DayHRV))*100
    print("Recovery HRV %: \(recoveryHRVPercentageValue)")
    print("nineth")
    completion()

}

// MARK: - RHR Calculate Rating per Min/Max
func recoveryRHRPercentage(_ completion : @escaping()->()) {
    // 1- is becuase RHR is better the lower it is.
    recoveryRHRPercentageValue = (1-((mostRecentRHR - min7DayRHR) / (max7DayRHR - min7DayRHR)))*100
    print("Recovery RHR %: \(recoveryRHRPercentageValue)")
    print("tenth")
    completion()

}

// MARK: - 50/50 Recovery Calculation
func finalRecoveryPercentageFunction() {
    finalRecoveryPercentageValue = (recoveryHRVPercentageValue + recoveryRHRPercentageValue) / 2
    print("Final Recovery %: \(finalRecoveryPercentageValue)")
    print("last")

    
}

// MARK: - Calculate Score Function
//func calculateScore() {
//
//        mostRecentHRVFunction()
//        mostRecentRHRFunction()
//        weekVariabilityArrayFunction()
//        weekRHRArrayFunction()
//}


//THIS IS WORKING
func first(_ completion : @escaping()->()){
    hkm.restingHeartRate(from: weekAgoStartDate, to: Date()) {
        (results) in
        arrayRHR7Day2.removeAll()
        var RHR = 0.0
        
        // results is an array of [HKQuantitySample]
        // example conversion to BPM:
        for result in results {
            RHR = result.quantity.doubleValue(for: .heartRateUnit)
            //Need to run this in a main queue becuase its so much
            arrayRHR7Day2.append(RHR)
            
        }
        print("Array for RHR: \(arrayRHR7Day2)")
//        weekRHRMax()
//        weekRHRMin()
//        recoveryRHRPercentage()
//        finalRecoveryPercentage()
        print("first")
        completion()
    }
   
}

func second(_ completion : @escaping()->()){
    finalRecoveryPercentageValue = (recoveryHRVPercentageValue + recoveryRHRPercentageValue) / 2
    print("Final Recovery %: \(finalRecoveryPercentageValue)")
    print("second")
    completion()
}

func third(){
    hkm.variability(from: weekAgoStartDate, to: Date()) {
        (results) in
        
        arrayVariability7Day2.removeAll()
        var Variability = 0.0
        
        // results is an array of [HKQuantitySample]
        // example conversion to BPM:
        for result in results {
            Variability = result.quantity.doubleValue(for: .variabilityUnit)
            //Need to run this in a main queue becuase its so much
            arrayVariability7Day2.append(Variability)
            
        }
        print("Array for Variability: \(arrayVariability7Day2)")
        print("third")
    }
   
}


func testFunction() {
    first{
         second{
              third()
         }

       }
    
}





//MARK: - ContentView

struct ContentView: View {
    
    //Core Data SwiftUI Object Management + Filepath Location
    @Environment(\.managedObjectContext) var managedObjectContext
    
    //So this should be working...
    @FetchRequest(
    entity: Array30Day.entity(),
        sortDescriptors: []
        ) var variableArray30Day: FetchedResults<Array30Day>
    
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
                    finalFunction()
                }) {
                    // How the button looks like
                    Text("Calculate Recovery")
                                //.frame(minWidth: 0, maxWidth: .infinity)
                                .fontWeight(.bold)
                                .font(.system(size: 18))
                                .padding()
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 3)
                                )
                }
                Slider(value: $sliderValue, in: 0...100)
                Text("How Recovered I Actually Feel: \(sliderValue, specifier: "%.0f")%")
                }.padding()
            }
        }
    
    func finalFunctionTest() {
        //IT WORKS! Now take these functions and change them to my new ones
        //1 - Create new functions
        //2 - Replace these
        mostRecentHRVFunction {
            mostRecentRHRFunction {
                weekVariabilityArrayFunction {
                    weekRHRArrayFunction {
                        weekHRVMax {
                            weekHRVMin {
                                weekRHRMax {
                                    weekRHRMin {
                                        recoveryHRVPercentage {
                                            recoveryRHRPercentage {
                                                finalRecoveryPercentageFunction()
                                                self.finalRecoveryPercentage = Int(finalRecoveryPercentageValue)
                                                self.finalRHRPercentage = Int(recoveryRHRPercentageValue)
                                                self.finalHRVPercentage = Int(recoveryHRVPercentageValue)
                                                self.lastHRVValue = Int(mostRecentHRV)
                                                self.lastRHRValue = Int(mostRecentRHR)
                                                print("Final @state is: \(finalRecoveryPercentage)")

                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
        // MARK: - CRUD Functions
        
        //This is just a test. This is a type of function I could use to write data to my DB
        
        
        //Saves whatever we are working with
        func saveContext() {
            do {
                try managedObjectContext.save()
            } catch {
                print("Error saving managed object context: \(error)")
            }
        }
        
        func writeDataTest() {
            let newTest = Test(context: managedObjectContext)
            newTest.date = Date()
            saveContext()
        }
        
        //Searches for and loads today's recovery % Data from Model
        func todaysRecoveryRequest () {
            
        }
        
        // MARK: - New Recovery Calculation Functions
        // MARK: - New Recovery Calculation Variables
        
        // Array
//    var arrayHRV = [Double]()
//    var arrayRHR = [Double]()
//    var recentHRV = 0.0
//    var recentRHR = 0.0
//    var arrayHRVDone = false
//    var arrayRHRDone = false
//        // Min/Max
//    var maxHRV = 0.0
//    var minHRV = 0.0
//    var maxRHR = 0.0
//    var minRHR = 0.0
//    var minHRVDone = false
//    var maxHRVDone = false
//    var minRHRDone = false
//    var maxRHRDone = false
//        // HRV/RHR Calculation
//    var hrvRecoveryPercentage = 0.0
//    var rhrRecoveryPercentage = 0.0
//    var hrvPercentageDone = false
//    var rhrPercentageDone = false
//        // Final Calculation
//    var finalRecoveryPercentage2 = 0.0
//    var finalRecoveryIndicator = false
    
  
    
    //The Final function that takes everything into account and calls other functions in a sync manor
    func finalFunction() {
        writeHRVRecentDatatoCD {
            writeRHRRecentDatatoCD {
                saveBothRecents {
                    getHRVArrayfromCD {
                        getRHRArrayfromCD {
                            findMinMaxHRV {
                                findMinMaxRHR {
                                    hrvRecoveryCalculation {
                                        rhrRecoveryCalculation {
                                            calculateFinalRecovery()
                                            self.finalRecoveryPercentage = Int(finalRecoveryPercentage2)
                                            self.finalRHRPercentage = Int(rhrRecoveryPercentage)
                                            self.finalHRVPercentage = Int(hrvRecoveryPercentage)
                                            self.lastHRVValue = Int(recentHRV)
                                            self.lastRHRValue = Int(recentRHR)
                                            print("Final @state is: \(finalRecoveryPercentage2)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
        // MARK: - Take recent data from healthkit and put into an array in CoreData
        // Goal of this is to take the most recent HRV and RHR data and append it to our 30 day array in core data
    
        // Let's us conditional statements to check if the array has 30 points, if so then run the code that removes the oldest point and adds a new one, if not, itll run another code that takes the last x amount of days to populate it
        // Then we can create a conditional statement that runs code (not here) that calculates % and using the conditional statement to make sure things are run before it calculates so we only have to press one time.

        //Takes the most recent HRV recording from yesterday until today and appends it to CoreData
        func writeHRVRecentDatatoCD(_ completion : @escaping()->()) {
            //1 - Access most recent hrv value between midnight yesterday and right this second
            hkm.variabilityMostRecent(from: yesterdayStartDate, to: Date()) {
                (results) in
                
                var lastHRV = 0.0
                // results is an array of [HKQuantitySample]
                // example conversion to BPM:
                for result in results {
                    lastHRV = result.quantity.doubleValue(for: .variabilityUnit)
                }
                recentHRV = Double(lastHRV)
                print("Last HRV: \(recentHRV)")
                
                //2 - Append most recent hrv value to 30 day core data array
//                let newHRVWriteData = Array30Day(context: managedObjectContext)
//                newHRVWriteData.hrv = recentHRV
                
                //This is also saving 2 contexts when i have it in both, and not together. I want them to be saved together after both run... May need to use conditional.
                //saveContext()
                //3 - Get data from core data and put into variable array
                
                //5 - Change HRVdone to true
                arrayHRVDone = true
                print("HRV Done = \(arrayHRVDone)")
                completion()
            }
        }
        
        //Takes most recent RHR recording from yesterday until today and appends it to CoreData
        func writeRHRRecentDatatoCD(_ completion : @escaping()->()) {
            //1 - Access most recent rhr value between midnight yesterday and right this second
            hkm.restingHeartRateMostRecent(from: yesterdayStartDate, to: Date()) {
                (results) in
                
                var lastRHR = 0.0
                // results is an array of [HKQuantitySample]
                // example conversion to BPM:
                for result in results {
                    lastRHR = result.quantity.doubleValue(for: .heartRateUnit)
                }
                recentRHR = Double(lastRHR)
                print("Last RHR: \(recentRHR)")
                
                //2 - Append most recent rhr value to 30 day core data array
//                let newRHRWriteData = Array30Day(context: managedObjectContext)
//                newRHRWriteData.rhr = recentRHR
                
                //saveContext()
                
                //3 - Get data from core data and put into variable array
                
                //5 - Change RHRdone to true
                arrayRHRDone = true
                print("RHR Done = \(arrayRHRDone)")
                completion()
            }
            //3 - Check how big array is, add or remove as necessary
        }
    
    func saveBothRecents(_ completion : @escaping()->()) {
        let newWriteData = Array30Day(context: managedObjectContext)
        newWriteData.hrv = recentHRV
        newWriteData.rhr = recentRHR
        saveContext()
        completion()
    }
    
    
    
    //This saves our current context. Runs after both RHR and HRV are complete so it saves them together.
//    func saveContextClosure(_ completion : @escaping()->()) {
//        // THis is a save context function that has a closure so i can write both RHR and HRV at once
//
//        do {
//            try managedObjectContext.save()
//            completion()
//        } catch {
//            print("Error saving managed object context: \(error)")
//        }
//    }
    
    //This takes all of our data from CD and appends it to a workable array variable
    func getHRVArrayfromCD(_ completion : @escaping()->()) {
        // Access core data and write array to variable
        arrayHRV = variableArray30Day.map {$0.hrv}
        print("Array HRV = \(arrayHRV)")
        print(arrayHRV.count)
        completion()
    }
    
    //This takes all of our data from CD and appends it to a workable array variable
    func getRHRArrayfromCD(_ completion : @escaping()->()) {
        // Access core data and write array to variable
        arrayRHR = variableArray30Day.map {$0.rhr}
        print("Array RHR = \(arrayRHR)")
        print(arrayRHR.count)
        completion()
    }
    
    //Takes our variable array for HRV and finds the min and max
    func findMinMaxHRV(_ completion : @escaping()->()) {
        // Find min and max of HRV from core data array and write to variable
        
        maxHRV = arrayHRV.max() ?? 0
        minHRV = arrayHRV.min() ?? 0
        print("HRV min: \(minHRV) and max: \(maxHRV)")
        completion()
    }
    
    //Takes our variable array for RHR and finds the min and max
    func findMinMaxRHR(_ completion : @escaping()->()) {
        // Find min and max of HRV from core data array and write to variable
        
        maxRHR = arrayRHR.max() ?? 0
        minRHR = arrayRHR.min() ?? 0
        print("RHR min: \(minRHR) and max: \(maxRHR)")
        completion()
        
    }
    
    // Eventually i want to create varaibles that look at quartiles, IQR, and removes outliers
        
        // MARK: - Compare recent data to array to find % recovery and record to core data
        // Goal of this is to take the most recent healthkit values, compare them to our 30 day coredata array, and come up with a % recovery for each
        // Goal of this is to record that calculation and data to core data
        
        //Calculates HRV recovery % based off min/max and last reading
        func hrvRecoveryCalculation(_ completion : @escaping()->()) {
            hrvRecoveryPercentage = ((recentHRV - minHRV) / (maxHRV - minHRV))*100
            print("Recovery HRV %: \(hrvRecoveryPercentage)")
            completion()
        }
        
        //Calculates RHR recovery % (-1) based off min/max and last reading
        func rhrRecoveryCalculation(_ completion : @escaping()->()) {
            rhrRecoveryPercentage = (1-((recentRHR - minRHR) / (maxRHR - minRHR)))*100
            print("Recovery RHR %: \(rhrRecoveryPercentage)")
            completion()
        }
        
        // MARK: - Compute final recovery %
        // Goal is to take both of today's calculations and come up with a final %
        // Goal is to take that final percentage and record it to core data
        
    
        //Final recovery that takes RHR and HRV %
        func calculateFinalRecovery() {
           finalRecoveryPercentage2 = (rhrRecoveryPercentage + hrvRecoveryPercentage) / 2
            print("Final Recovery Percentage: \(finalRecoveryPercentage2)")
        }
        
    }


    
    
    
    
    
    //MARK: - SettingsView
    struct SettingsView: View {
        
        let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        var body: some View {
            NavigationView {
                VStack {
                    Text("When loading the application for the first time, press the Authorize Healthkit button:")
                        .multilineTextAlignment(.center)
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
                    Text("Now, every morning just put on your watch and double tap the recovery button.")
                        .multilineTextAlignment(.center)
                    Text("Indicate using the sliding bar how you actually feel, take a screen shot, and send it to me!")
                        .multilineTextAlignment(.center)
                    Button(action: {
                        print(dataFilePath)
                        
                    }) {
                        // How the button looks like
                        Text("Find Data Path")
                    }
                    Button(action: {
                        deleteAllRecords()
                        
                    }) {
                        // How the button looks like
                        Text("Delete Array Records")
                    }
                }
            }
            
        }
        
        func deleteAllRecords() {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext

            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Array30Day")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print ("There was an error")
            }
        }
    }
    //MARK: - StressView
    struct StressView: View {
        var body: some View {
            Text("Coming Soon")
        }
    }
    //MARK: - JournalView
    struct JournalView: View {
        var body: some View {
            Text("Coming Soon")
        }
    }
    
    //MARK: - AppView to Create Tabs
    struct AppView: View {
        var body: some View {
            TabView {
                ContentView()
                    .tabItem {
                        Image(systemName: "battery.100")
                        Text("Recovery")
                    }
                StressView()
                    .tabItem {
                        Image(systemName: "bolt.fill")
                        Text("Stress")
                    }
                JournalView()
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("Journal")
                    }
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Get Started")
                    }
            }
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            AppView()
                .previewDevice("iPhone 11 Pro")
        }
    }
