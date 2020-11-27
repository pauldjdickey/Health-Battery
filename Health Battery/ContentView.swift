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
    // Loading Last Recovery
var lastRecoveryArray = [Double]()
var lastHRVValueArray = [Double]()
var lastRHRValueArray = [Double]()
var lastHRVPercentArray = [Double]()
var lastRHRPercentArray = [Double]()
var lastRecoveryVar = 0.0
var lastHRVVar = 0.0
var lastRHRVar = 0.0
var lastHRVPercentVar = 0.0
var lastRHRPercentVar = 0.0
    // Core Data Check
var hasRecoveryHappened = [Double]()


typealias FinishedGettingHealthData = () -> ()

//var date = NSDate()
//let cal = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
//var lastMidnight = cal.startOfDay(for: date as Date)

//let date: Date = Date()
//let cal: Calendar = Calendar(identifier: .gregorian)
//let lastMidnight: Date = cal.date(bySettingHour: 0, minute: 0, second: 0, of: date)!

let calendar = Calendar.current
let startDate = calendar.startOfDay(for: Date())
let yesterdayStartDate = calendar.startOfDay(for: Date.yesterday)
let weekAgoStartDate = calendar.startOfDay(for: Date.weekAgo)
let monthAgoStartDate = calendar.startOfDay(for: Date.monthAgo)
let lastMidnight = calendar.startOfDay(for: Date())

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

//MARK: - ContentView

struct ContentView: View {
    
    //Core Data SwiftUI Object Management + Filepath Location
    @Environment(\.managedObjectContext) var managedObjectContext
    
    //So this should be working to request array
    @FetchRequest(
        entity: Array30Day.entity(),
        sortDescriptors: []
        ) var variableArray30Day: FetchedResults<Array30Day>
    
    
    //Need to make this so it loads the most recent item within midnight and this second, put into function that can be called and then takes these results and changes the @statevariable accordingly
    
    // This is working and fetches all core date from midnight until right now, organize by most recent first in the array
    @FetchRequest(
        entity: Recovery.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Recovery.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@", lastMidnight as NSDate)
    ) var lastRecovery: FetchedResults<Recovery>
    
    
    
    
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
        
    @State var showsAlert = false
    @State var showsAlert1 = false
    
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
                        .foregroundColor(Color.white).bold()
                                .padding()
                        .background(RoundedRectangle(cornerRadius: 15).opacity(0.5).foregroundColor(.gray))
                }
                Button(action: {
                    todaysRecoveryRequest()
                }) {
                    // How the button looks like
                    Text("Test Request Recovery from CD")
                }
                Button(action: {
                    hasUserCalculatedRecovery()
                }) {
                    // How the button looks like
                    Text("Test Check for Recovery Happened")
                }.onAppear(perform: {
                    print("Recovery Appeared using OnAppear")
                    todaysRecoveryRequest()
                })
                .alert(isPresented: self.$showsAlert) {
                    Alert(title: Text("Not Enough Data to Calculate Recovery"), message: Text("Try again tomorrow morning to calculate your first recovery"))
                        }
                .alert(isPresented: self.$showsAlert1) {
                    Alert(title: Text("No HRV or RHR Data Available"), message: Text("Use the breathe app on your watch to force HRV"))
                        }
                Slider(value: $sliderValue, in: 0...100)
                Text("How Recovered I Actually Feel: \(sliderValue, specifier: "%.0f")%")
                }.padding()
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
    
        // MARK: - Core Data Request Functions
        
        //Searches for and loads today's recovery % Data from Model
        func todaysRecoveryRequest() {
            print("Recovery Request Function Called!")
            //This works! Now let's get the last item from core data from midnight until right now, apply those details to variables that then change the @state variables. There should be an if-then statement checking if there is data to make sure it doesnt pull no data. Maybe a guard?
            
            lastRecoveryArray = lastRecovery.map {$0.overallPercent}
            lastHRVValueArray = lastRecovery.map {$0.hrvValue}
            lastRHRValueArray = lastRecovery.map {$0.rhrValue}
            lastHRVPercentArray = lastRecovery.map {$0.hrvPercent}
            lastRHRPercentArray = lastRecovery.map {$0.rhrPercent}
            //This is an array of all items from midnight to right now
            print("Full recovery Array: \(lastRecoveryArray)")
            
            //So... This function should have a guard or if then that checks if any data is pulled, if no data is pulled between midnight and right now, that means a calculation has not been done yet and we dont have to run this function. If there is data that is pulled, we should find the most recent one and apply it to our @state variables on .appear. Then if that works, we can change the text of our button to say "Recalculate". Then we can do this to all our variables to load!
            // Guard statement goes here!
            // Guard checks if we got data (Array county is empty)
            guard lastRecoveryArray.count >= 1 else {
                print("Guard is running and it all stops")
                // If array is empty, we simply return and dont run the rest of function
                self.finalRecoveryPercentage = Int(0)
                self.finalRHRPercentage = Int(0)
                self.finalHRVPercentage = Int(0)
                self.lastHRVValue = Int(0)
                self.lastRHRValue = Int(0)
                
                return
            }
            // If array has something, we run the function below
            print("Guard didnt activate")
            
            
            //For now, assume we will get data to test
            
            lastRecoveryVar = lastRecoveryArray.first ?? 0
            lastHRVVar = lastHRVValueArray.first ?? 0
            lastRHRVar = lastRHRValueArray.first ?? 0
            lastHRVPercentVar = lastHRVPercentArray.first ?? 0
            lastRHRPercentVar = lastRHRPercentArray.first ?? 0
            
            print("Recovery %: \(lastRecoveryVar)")
            print("Last HRV Value: \(lastHRVVar)")
            print("Last RHR Value: \(lastRHRVar)")
            print("Last HRV %: \(lastHRVPercentVar)")
            print("Last RHR %: \(lastRHRPercentVar)")
            
            self.finalRecoveryPercentage = Int(lastRecoveryVar)
            self.finalRHRPercentage = Int(lastRHRPercentVar)
            self.finalHRVPercentage = Int(lastHRVPercentVar)
            self.lastHRVValue = Int(lastHRVVar)
            self.lastRHRValue = Int(lastRHRVar)
            
            
            
        }
    
    func hasUserCalculatedRecovery() {
        // Gets core data array
        // Conditional statement checking count of array -> If count == 0, then closure
        // If count >= 1, then prompt asking for redo
        hasRecoveryHappened = lastRecovery.map {$0.overallPercent}
        print(hasRecoveryHappened.count)
        
        if hasRecoveryHappened.count == 0 {
            print("User has not calculated recovery, enact closure to continue as usual")
        } else {
            print("User has calculated recovery, prompt to continue to recalculate or not? and either closure or break")
        }
        
    }
        
        // MARK: - New Recovery Calculation Functions
    //The Final function that takes everything into account and calls other functions in a sync manor
    func finalFunction() {
        writeHRVRecentDatatoCD {
            writeRHRRecentDatatoCD {
                checkIfRecentRHRHRVZero {
                    saveBothRecents {
                        getHRVArrayfromCD {
                            getRHRArrayfromCD {
                                findMinMaxHRV {
                                    findMinMaxRHR {
                                        checkDataforErrors {
                                            hrvRecoveryCalculation {
                                                rhrRecoveryCalculation {
                                                    calculateFinalRecovery {
                                                        finalRecoverySave()
                                                        self.finalRecoveryPercentage = Int(finalRecoveryPercentage2)
                                                        self.finalRHRPercentage = Int(rhrRecoveryPercentage)
                                                        self.finalHRVPercentage = Int(hrvRecoveryPercentage)
                                                        self.lastHRVValue = Int(recentHRV)
                                                        self.lastRHRValue = Int(recentRHR)
                                                        print("Final @state is: \(finalRecoveryPercentage2)")
                                                        
                                                        
                                                        print("Current Date: \(Date())")
                                                        print("Midnight: \(lastMidnight)")
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
    
    func checkIfRecentRHRHRVZero(_ completion : @escaping()->()) {
        guard recentHRV != 0.0 && recentRHR != 0.0 else {
            print("Guard is running and it all stops")
            // Make a message popup and then be dismissed?
            showsAlert1.toggle()
            return //break?
        }
        
        print("Guard didnt activate")
        completion()
    }
    
    func saveBothRecents(_ completion : @escaping()->()) {
        let newWriteData = Array30Day(context: managedObjectContext)
        newWriteData.hrv = recentHRV
        newWriteData.rhr = recentRHR
        newWriteData.date = Date()
        
        //Its crashing for sam on saveContext, both when she pressed the app and when she left the app... Maybe its trying to save nothing?
        saveContext()
        completion()
    }
    
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
    
    func checkDataforErrors (_ completion : @escaping()->()) {
        guard arrayRHR.count > 1 && arrayHRV.count > 1 && maxHRV != minHRV && maxRHR != minHRV else {
            print("Guard is running and it all stops")
            // Make a message popup and then be dismissed?
            showsAlert.toggle()
            return //break?
        }
        
        print("Guard didnt activate")
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
        func calculateFinalRecovery(_ completion : @escaping()->()) {
           finalRecoveryPercentage2 = (rhrRecoveryPercentage + hrvRecoveryPercentage) / 2
            print("Final Recovery Percentage: \(finalRecoveryPercentage2)")
            completion()
        }
    
        func finalRecoverySave() {
            let finalWriteData = Recovery(context: managedObjectContext)
            finalWriteData.date = Date()
            finalWriteData.hrvValue = recentHRV
            finalWriteData.hrvPercent = hrvRecoveryPercentage
            finalWriteData.rhrValue = recentRHR
            finalWriteData.rhrPercent = rhrRecoveryPercentage
            finalWriteData.overallPercent = finalRecoveryPercentage2
            
            saveContext()
            print("Final Recovery Saved!")
        }
    
        func retrieveLastRecordedRecovery() {
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
                    Button(action: {
                        deleteAllRecordsRecovery()
                        
                    }) {
                        // How the button looks like
                        Text("Delete Recovery Records")
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
        
        func deleteAllRecordsRecovery() {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext

            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Recovery")
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
