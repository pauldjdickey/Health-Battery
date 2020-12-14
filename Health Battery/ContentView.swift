//Last update:
//Sees the last HRV and RHR recordings during today(s) time frame and reports it in text fields. THis would glitch if there are multiple reportings in a day as it would see all recordings that day, instead of just the most recent one.

import Foundation
import HealthKit
import UIKit
import SwiftUI
import CoreData
import Dispatch
import SwiftProgress
import PZCircularControl
import SwiftUICharts


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
//Bar Data
var barColor:Color = .yellow

//Check Variables
var checkHRVAlert = 0
var baselineDaysLeft = 0
var baselineDays = 3

    //Array
var arrayHRV = [Double]()
var arrayRHR = [Double]()
var arrayNumbers = [NSManagedObject]()
    //Recent
var recentHRV = 0.0
var recentRHR = 0.0
var arrayHRVDone = false
var arrayRHRDone = false
    // Array's with outliers removed
var recentHRVNoOutlierArray = [Double]()
var initialHRVIQR = 0.0
var initialHRV1q = 0.0
var initialHRV3q = 0.0
var initialHRVLowOutlierCutoff = 0.0
var initialHRVHighOutlierCutoff = 0.0

    // Min/Max/1q/3q/avg HRV
var maxHRV = 0.0
var minHRV = 0.0
var q1HRV = 0.0
var q3HRV = 0.0
var avgHRV = 0.0
var sumHRV = 0.0
var medianHRV = 0.0
    // Min/Max RHR
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
var howManyRecoveries = [Double]()


typealias FinishedGettingHealthData = () -> ()

//var date = NSDate()
//let cal = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
//var lastMidnight = cal.startOfDay(for: date as Date)

//let date: Date = Date()
//let cal: Calendar = Calendar(identifier: .gregorian)
//let lastMidnight: Date = cal.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
var rightNow = Date()

var calendar = Calendar.current
var startDate = calendar.startOfDay(for: rightNow)
var yesterdayStartDate = calendar.startOfDay(for: Date.yesterday)
var weekAgoStartDate = calendar.startOfDay(for: Date.weekAgo)
var monthAgoStartDate = calendar.startOfDay(for: Date.monthAgo)
var lastMidnight = calendar.startOfDay(for: rightNow)


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
    static var yesterday: Date { return rightNow.dayBefore }
    static var tomorrow:  Date { return rightNow.dayAfter }
    static var weekAgo: Date { return rightNow.weekAgo }
    static var monthAgo: Date { return rightNow.monthAgo }
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
    func to(timeZone outputTimeZone: TimeZone, from inputTimeZone: TimeZone) -> Date {
         let delta = TimeInterval(outputTimeZone.secondsFromGMT(for: self) - inputTimeZone.secondsFromGMT(for: self))
         return addingTimeInterval(delta)
    }
    
}
extension DateFormatter {
    func date(from string: String, timeZoneInString: TimeZone, outputTimeZone: TimeZone = .autoupdatingCurrent) -> Date? {
        date(from: string)?.to(timeZone: outputTimeZone, from: timeZoneInString)
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
    
    @FetchRequest(
        entity: Recovery.entity(),
        sortDescriptors: []
    ) var recoveryCount: FetchedResults<Recovery>
    
    
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
    @State var showsRHRCheckAlert = false
    @State var showsAlertRecoveryCheck = false
    @State var showsHRV1DayCheckAlert = false
        
    enum ActiveAlert {
        case alertRecoveryCheck, showsHRV1DayCheckAlert, showsHRV1DayCheckAlertTryAgain, showsRHRCheckAlert, showsForcedHRVCheckAlert, checkStartingCoreDataAmount, checkDataForErrorsAlert
    }
    
    @State private var showAlert = false
    @State private var activeAlert: ActiveAlert = .alertRecoveryCheck
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Last RHR Value: \(lastRHRValue) BPM")
                Text("Last HRV Value: \(lastHRVValue) MS")
                Text("HRV Recovery: \(finalHRVPercentage) %")
                Text("RHR Recovery: \(finalRHRPercentage) %")
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                            print("Moving back to the foreground!")
                            todaysRecoveryRequest()
                            barColorChange()
                    }
                // Put calculated score below
                Text("\(finalRecoveryPercentage)%")
                    .fontWeight(.regular)
                    .font(.system(size: 70))
                LinearProgress(
                        progress: CGFloat(finalRecoveryPercentage),
                        foregroundColor: barColor,
                        backgroundColor: Color.gray.opacity(0.2)
                        )
                        .frame(width: 200, height: 50)
                        .padding()
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
                    healthKitTest()
                }) {
                    // How the button looks like
                    Text("HealthKit Test")
                }.alert(isPresented: $showAlert) {
                    switch activeAlert {
                    case .alertRecoveryCheck:
                        return Alert(title: Text("Recovery has already been calculated for the day."), message: Text("Would you like to recalculate your recovery?"), primaryButton: .default(Text("Keep current calculation")), secondaryButton: .destructive(Text("Recalculate")){
                                        print("Recalculate Button Pressed")
                                        finalFunctionWithoutRecoveryCheck()
                        })
                    case .showsHRV1DayCheckAlert:
                        return Alert(title: Text("Your most recent HRV reading is not up to date."), message: Text("Please go to the breathing app on your Apple Watch to record your HRV, then come back to recalculate recovery."), primaryButton: .default(Text("Ok")), secondaryButton: .destructive(Text("Calculate Recovery Anyways")){
                                        print("Forced Calculate Button Pressed")
                                        finalFunctionWithForcedHRVRecovery()
                        })
                    case .showsHRV1DayCheckAlertTryAgain:
                        return Alert(title: Text("Oops! Looks like forcing your HRV didn't work."), message: Text("Please try going back to the breathing app on your Apple Watch to record your HRV then coming back to calculate recovery. This may take a couple times to work."), primaryButton: .default(Text("Ok")), secondaryButton: .destructive(Text("Force Calculate Recovery Anyways")){
                                        print("Forced Calculate Button Pressed")
                                        finalFunctionWithForcedHRVRecovery()
                        })
                    case .showsRHRCheckAlert:
                        return Alert(title: Text("Not enough heart rate data available."), message: Text("Please wear your watch all day and try to calculate recovery again tomorrow."))
                    case .showsForcedHRVCheckAlert:
                        return Alert(title: Text("Unfortunately, we can not process your recovery."), message: Text("Please force your HRV in the breathing app or come back again tomorrow after wearing your watch all day today."))
                    case .checkStartingCoreDataAmount:
                        return Alert(title: Text("You need to record \(baselineDaysLeft) more days of morning recoveries to create your baseline."), message: Text("Please come back each morning to calculate your recovery while we create your baseline."), dismissButton: .default(Text("Okay")){
                            print("Create Baseline Button Tapped")
                            finalRecoveryBaselineFunction()
                        })
                    case .checkDataForErrorsAlert:
                        return Alert(title: Text("Unfortunately, there is not enough heart rate data available."), message: Text("Please wear your watch all day and try to calculate recovery again tomorrow."))
                    }
                }.onAppear(perform: {
                    print("Recovery Appeared using OnAppear")
                    todaysRecoveryRequest()
                    barColorChange()
                })
                Slider(value: $sliderValue, in: 0...100)
                Text("How Recovered I Actually Feel: \(sliderValue, specifier: "%.0f")%")
                //Text("App Version 0.1.11")
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
            rightNow = Date()
            lastMidnight = calendar.startOfDay(for: rightNow)
            
            
            print("Right now: \(rightNow)")
            print("lastMidnight: \(lastMidnight)")
            lastRecoveryArray = lastRecovery.map {$0.overallPercent}
            lastHRVValueArray = lastRecovery.map {$0.hrvValue}
            lastRHRValueArray = lastRecovery.map {$0.rhrValue}
            lastHRVPercentArray = lastRecovery.map {$0.hrvPercent}
            lastRHRPercentArray = lastRecovery.map {$0.rhrPercent}
            print("lastMidnight After Request: \(lastMidnight)")
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
    
    
        
        // MARK: - New Recovery Calculation Functions
    //The Final function that takes everything into account and calls other functions in a sync manor
    func finalFunction() {
        hasUserCalculatedRecovery {
            writeHRVRecentDatatoCD {
                writeRHRRecentDatatoCD {
                    checkRHRLast2Days {
                        checkHRVLast1Days {
                            saveBothRecents {
                                getHRVArrayfromCD {
                                    getRHRArrayfromCD {
                                        checkStartingCoreDataAmount {
                                            findMinMaxHRV {
                                                findMinMaxRHR {
                                                    checkDataforErrors {
                                                        hrvRecoveryCalculation {
                                                            rhrRecoveryCalculation {
                                                                calculateFinalRecovery {
                                                                    finalRecoverySave {
                                                                        updateStateValues {
                                                                            barColorChange()
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
                    }
                }
            }
        }
    }
    
    // MARK: - Still need a few more final recovery function based on above checks
    
    //Gets called when userCalculatedRecovery Guard is initiated, but user forces recovery anyways. Same as above, but without the first item
    func finalFunctionWithoutRecoveryCheck() {
        writeHRVRecentDatatoCD {
            writeRHRRecentDatatoCD {
                checkRHRLast2Days {
                    checkHRVLast1Days {
                        saveBothRecents {
                            getHRVArrayfromCD {
                                getRHRArrayfromCD {
                                    checkStartingCoreDataAmount {
                                        findMinMaxHRV {
                                            findMinMaxRHR {
                                                checkDataforErrors {
                                                    hrvRecoveryCalculation {
                                                        rhrRecoveryCalculation {
                                                            calculateFinalRecovery {
                                                                finalRecoverySave {
                                                                    updateStateValues {
                                                                        barColorChange()
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
                }
            }
        }
    }
    
    // MARK: - Function when forcing HRV Breathing App Calculation is Forced
    
    func finalFunctionWithForcedHRVRecovery() {
        writeHRVYesterdayRecentDatatoCD {
            writeRHRRecentDatatoCD {
                checkRHRLast2Days {
                    checkForcedHRVValue {
                        //Checking forced value is only done in this function as the user is forcing
                        saveBothRecents {
                            getHRVArrayfromCD {
                                getRHRArrayfromCD {
                                    checkStartingCoreDataAmount {
                                        findMinMaxHRV {
                                            findMinMaxRHR {
                                                checkDataforErrors {
                                                    hrvRecoveryCalculation {
                                                        rhrRecoveryCalculation {
                                                            calculateFinalRecovery {
                                                                finalRecoverySave {
                                                                    updateStateValues {
                                                                        barColorChange()
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
                }
            }
        }
    }
    
    
    
    
    // MARK: - Function that runs when less than 4 days of recoveries to create a baseline
    func finalRecoveryBaselineFunction() {
        // Need to create new final recovery calculation to save in final recovery save. I think we can still use final recovery save, just make up the numbers into calculation variables
        print("Final recovery baseline function running")
        createAndSaveBaselineCalculation {
                finalRecoverySave()
                self.finalRecoveryPercentage = Int(finalRecoveryPercentage2)
                self.finalRHRPercentage = Int(rhrRecoveryPercentage)
                self.finalHRVPercentage = Int(hrvRecoveryPercentage)
                self.lastHRVValue = Int(recentHRV)
                self.lastRHRValue = Int(recentRHR)
                print("Final @state is: \(finalRecoveryPercentage2)")
                barColor = .gray
        }
    }
    
    // MARK: - Change bar color function
    func barColorChange() {
        
        howManyRecoveries = recoveryCount.map {$0.overallPercent}
        
        if howManyRecoveries.count >= 3 {
            if finalRecoveryPercentage <= 39 {
                barColor = .red
            } else if finalRecoveryPercentage > 39 && finalRecoveryPercentage < 74 {
                barColor = .yellow
            } else if finalRecoveryPercentage >= 74 {
                barColor = .green
            }
        } else {
            barColor = .gray
        }
    }
    
    
        // MARK: - Take recent data from healthkit and put into an array in CoreData
        // Goal of this is to take the most recent HRV and RHR data and append it to our 30 day array in core data
    
        // Let's us conditional statements to check if the array has 30 points, if so then run the code that removes the oldest point and adds a new one, if not, itll run another code that takes the last x amount of days to populate it
        // Then we can create a conditional statement that runs code (not here) that calculates % and using the conditional statement to make sure things are run before it calculates so we only have to press one time.
    
        // MARK: - GUARD - User Calculated Recovery
    func testAlert() {
        activeAlert = .showsHRV1DayCheckAlert
        showAlert.toggle()
    }
    
    
        func hasUserCalculatedRecovery(_ completion : @escaping()->()) {
            // Gets core data array
            // Conditional statement checking count of array -> If count == 0, then closure
            // If count >= 1, then prompt asking for redo
            hasRecoveryHappened = lastRecovery.map {$0.overallPercent}
            print(hasRecoveryHappened.count)
            
            guard hasRecoveryHappened.count == 0 else {
                print("User has calculated recovery, prompt to continue to recalculate or not? and either closure or break")
                //showsAlertRecoveryCheck.toggle()
                activeAlert = .alertRecoveryCheck
                showAlert.toggle()
                return
            }
            print("User has not calculated recovery, enact closure to continue as usual")
            completion()
        }

        //Takes the most recent HRV recording from yesterday until today and appends it to CoreData
        func writeHRVRecentDatatoCD(_ completion : @escaping()->()) {
            //1 - Access most recent hrv value between midnight yesterday and right this second
            hkm.variabilityMostRecent(from: lastMidnight, to: Date()) {
                (results) in
                                
                var lastHRV = 0.0
                // results is an array of [HKQuantitySample]
                // example conversion to BPM:
                for result in results {
                    lastHRV = result.quantity.doubleValue(for: .variabilityUnit)
                }
                recentHRV = Double(lastHRV)
                print("Last HRV: \(recentHRV)")
                arrayHRVDone = true
                print("HRV Done = \(arrayHRVDone)")
                completion()
            }
        }
    
    func writeHRVYesterdayRecentDatatoCD(_ completion : @escaping()->()) {
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
                var testResult: [String:Any] = [:]
                // results is an array of [HKQuantitySample]
                // example conversion to BPM:
                for result in results {
                    lastRHR = result.quantity.doubleValue(for: .heartRateUnit)
                    //testResult = result.metadata!
                }
                recentRHR = Double(lastRHR)
                print("Last RHR: \(recentRHR)")
                print("Metadata: \(testResult)")
                arrayRHRDone = true
                print("RHR Done = \(arrayRHRDone)")
                completion()
            }
            //3 - Check how big array is, add or remove as necessary
        }
    
    func healthKitTest() {
        //1 - Access most recent rhr value between midnight yesterday and right this second
        hkm.restingHeartRateMostRecent(from: yesterdayStartDate, to: Date()) {
            (results) in
            
            var lastRHR = 0.0
            var testResult: [String:Any] = [:]
            var test: Date? = nil
            // results is an array of [HKQuantitySample]
            // example conversion to BPM:
            for result in results {
                lastRHR = result.quantity.doubleValue(for: .heartRateUnit)
                //testResult = result.metadata!
                //test = result.endDate
                test = result.startDate
                //test = result.
            }
            recentRHR = Double(lastRHR)
            print("Last RHR: \(recentRHR)")
            print("Metadata: \(test)")
            arrayRHRDone = true
            print("RHR Done = \(arrayRHRDone)")
            print("Calendar.current: \(calendar)")
        }
        //3 - Check how big array is, add or remove as necessary
    }
    
    
    
    // MARK: - ADD GUARD - Guard to check if any RHR from last 2 days - Just stops and tells to wear watch more if there arent so we dont even have to continue and fail
    
    func checkRHRLast2Days(_ completion : @escaping()->()) {
        guard recentRHR != 0.0 else {
            activeAlert = .showsRHRCheckAlert
            showAlert.toggle()
            return
        }
        completion()
    }

    // MARK: - GUARD - Check if HRV was in past day guard, otherwise prompt to go back to breathe app. Need to change variable +=, and if user decides to run the recovery anyways, it will need to then change most recent HRV to be yesterday. If past recording since midnight was 0.0, then we know we need to look back farther. What if the user forces and it has no HRV recovery data?
    
    func checkHRVLast1Days(_ completion : @escaping()->()) {
        guard recentHRV != 0.0 else {
            //Popup to go to breathe app that then runs a new final function redoing everything but with checking HRV 2 days ago.
            
            
            //Need to have an if then statement of what alert to open
            
            //"Oops, looks like forcing your HRV didn't work. Please go back to the breathing app and try again
            //Need to += to a variable, defaulted at 0 for the first time someone pressed it
            
            //Variable = 0, runs as usual below
            //Variable = 1 or more, then run new case function
            
            if checkHRVAlert == 0 {
                activeAlert = .showsHRV1DayCheckAlert
                showAlert.toggle()
            } else if checkHRVAlert >= 1 {
                activeAlert = .showsHRV1DayCheckAlertTryAgain
                showAlert.toggle()
            }
            checkHRVAlert += 1
            //recentHRV since midnight is equal to 0.0, nothing was found this morning
            //+= to variable
            return
        }
        completion()
        //recentHRV has data, continue with completion()
    }
    
    // MARK: - GUARD - Check to make sure we have HRV data before saving most recent, should be more than 0. This will only be triggered if the user forces the HRV above and it doesnt work through the breathing app and they force it anyways and it cant find any HRV from yesterday either. Prompt them the same as the RHR function above, different text to wear the watch more or to try to force HRV again. "Unfortunately we can not process your recovery due to lack of HRV in the last 2 days. Please either force your HRV in the breathing app or come back again tomorrow after wearing your watch all day".
    
    func checkForcedHRVValue(_ completion : @escaping()->()) {
        
        guard recentHRV != 0.0 else {
            //recentHRV when forced from yesterday is 0
            //Make alert to tell them to force in breathing app or wear all day and come back
            activeAlert = .showsForcedHRVCheckAlert
            showAlert.toggle()
            return
        }
        //Forced HRV is not 0, continue with main calculation function
       completion()
    }
    
    
    func saveBothRecents(_ completion : @escaping()->()) {
        let newWriteData = Array30Day(context: managedObjectContext)
        newWriteData.hrv = recentHRV
        newWriteData.rhr = recentRHR
        newWriteData.date = Date()
        checkHRVAlert = 0
        
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
        
        initialHRV1q = (Sigma.percentile(arrayHRV, percentile: 0.25) ?? 0.0)
        initialHRV3q = (Sigma.percentile(arrayHRV, percentile: 0.75) ?? 0.0)
        
        initialHRVIQR = initialHRV3q - initialHRV1q
        
        initialHRVLowOutlierCutoff = initialHRV1q - (1.5 * initialHRVIQR)
        
        initialHRVHighOutlierCutoff = initialHRV3q + (1.5 * initialHRVIQR)
        
        recentHRVNoOutlierArray = arrayHRV.filter { $0 < initialHRVHighOutlierCutoff && $0 > initialHRVLowOutlierCutoff }
        
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
    // MARK: - GUARD - Check to see if there are 3-4 days worth of core data recoveries to use, otherwise give popup and calculate @ 50% without checking for errors. This will be a good place because we have done all the checks above first
    
    func checkStartingCoreDataAmount(_ completion : @escaping()->()) {
        //Use recovery count fetch request then guard map
        //Checks the .count of recoveries
        //If 4 or more, no guard
        //If less than 4, guard then run final calculation function that just records the HRV and RHR values, and sets the final % and all other % to 50%
        
        howManyRecoveries = recoveryCount.map {$0.overallPercent}
        
        guard howManyRecoveries.count >= 3 else {
            // Count is less than 4
            // Show popup with 1 option, and force a 50% recovery with new function
            baselineDaysLeft = (baselineDays - howManyRecoveries.count)
            print("Recoveries: \(howManyRecoveries)")
            print("Array count for baseline calculation: \(howManyRecoveries.count)")
            activeAlert = .checkStartingCoreDataAmount
            showAlert.toggle()
            return
        }
        //count is greater than 4
        baselineDays = 3
        completion()
    }

    //Takes our variable array for HRV and finds the min and max
    func findMinMaxHRV(_ completion : @escaping()->()) {
        // Find min and max of HRV from core data array and write to variable
        
        
        //Need to remove outliers first, then use that new array of items in these
        maxHRV = recentHRVNoOutlierArray.max() ?? 0
        minHRV = recentHRVNoOutlierArray.min() ?? 0
        sumHRV = recentHRVNoOutlierArray.reduce(0, +)
        avgHRV = sumHRV / Double(recentHRVNoOutlierArray.count)
        q1HRV = Sigma.percentile(recentHRVNoOutlierArray, percentile: 0.25) ?? 0.0
        q3HRV = Sigma.percentile(recentHRVNoOutlierArray, percentile: 0.75) ?? 0.0
        medianHRV = Sigma.median(recentHRVNoOutlierArray) ?? 0.0
        
        print("HRV min: \(minHRV) and q1: \(q1HRV) and median: \(medianHRV) and q3: \(q3HRV) and max: \(maxHRV) and sum: \(sumHRV) ")
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
    
    // MARK: - GUARD - before calculating to make sure we dont get an error. Can we remove anything from this? Better alert? Can we work with it just being more than 1 in the array count no matter what it is?
    func checkDataforErrors (_ completion : @escaping()->()) {
        guard arrayRHR.count > 1 && arrayHRV.count > 1 && maxHRV != minHRV && maxRHR != minRHR else {
            print("Check Data for Errors Guard is running and it all stops")
            // Make a message popup and then be dismissed?
            //Message will state to wear apple watch more and come back tomorrow
            print(showAlert)
            activeAlert = .checkDataForErrorsAlert
            showAlert = true
            print(showAlert)
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
            //This is where we do that if then statement to calculate recent compared to all my other variables!
            
            if recentHRV < minHRV {
                hrvRecoveryPercentage  = 25.0
            } else if recentHRV > maxHRV {
                hrvRecoveryPercentage = 99.0
            } else if minHRV <= recentHRV && recentHRV <= q1HRV {
                //(A) Calculation
                hrvRecoveryPercentage = ((((recentHRV - minHRV) / (q1HRV - minHRV)) * 25.0) + 25.0)
                
            } else if q1HRV <= recentHRV && recentHRV <= medianHRV {
                //(B) Calculation
                hrvRecoveryPercentage = ((((recentHRV - q1HRV) / (medianHRV - q1HRV)) * 15.0) + 50.0)
                
            } else if medianHRV <= recentHRV && recentHRV <= q3HRV {
                //(C) Calculation
                hrvRecoveryPercentage = ((((recentHRV - medianHRV) / (q3HRV - medianHRV)) * 20.0) + 65.0)
                
            } else if q3HRV <= recentHRV && recentHRV <= maxHRV {
                //(D) Calculation
                hrvRecoveryPercentage = ((((recentHRV - q3HRV) / (maxHRV - q3HRV)) * 14.0) + 85.0)
                
            }
            
            
//            hrvRecoveryPercentage = ((recentHRV - minHRV) / (maxHRV - minHRV))*100
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
            
            finalRecoveryPercentage2 = hrvRecoveryPercentage
            print("Final Recovery Percentage: \(finalRecoveryPercentage2)")
            
//           finalRecoveryPercentage2 = (rhrRecoveryPercentage + hrvRecoveryPercentage) / 2
//            print("Final Recovery Percentage: \(finalRecoveryPercentage2)")
            completion()
        }
    
        func createAndSaveBaselineCalculation(_ completion : @escaping()->()) {
            hrvRecoveryPercentage = 50
            rhrRecoveryPercentage = 50
            finalRecoveryPercentage2 = 50
            completion()
        }
    
        func finalRecoverySave(_ completion : @escaping()->()) {
            let finalWriteData = Recovery(context: managedObjectContext)
            finalWriteData.date = Date()
            finalWriteData.hrvValue = recentHRV
            finalWriteData.hrvPercent = hrvRecoveryPercentage
            finalWriteData.rhrValue = recentRHR
            finalWriteData.rhrPercent = rhrRecoveryPercentage
            finalWriteData.overallPercent = finalRecoveryPercentage2
            
            saveContext()
            print("Final Recovery Saved!")
            completion()
        }
    
        func updateStateValues(_ completion : @escaping()->()) {
            self.finalRecoveryPercentage = Int(finalRecoveryPercentage2)
            self.finalRHRPercentage = Int(rhrRecoveryPercentage)
            self.finalHRVPercentage = Int(hrvRecoveryPercentage)
            self.lastHRVValue = Int(recentHRV)
            self.lastRHRValue = Int(recentRHR)
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
                        deleteAllRecordsReadiness()
                        
                    }) {
                        // How the button looks like
                        Text("Delete Readiness Records")
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
        
        func deleteAllRecordsReadiness() {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext

            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Readiness")
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
    //MARK: - HomeView
    //MARK: - Variables
    var recentHRVValue = 0.0
    var recentHRVTime: Date? = nil
    var recentHRVCalculation = 0.0
//
    var newFinalHRVCalculation = 0.0
//
    var variability30DayArray = [Double]()
//
    var variability30DayArrayNoOutliers = [Double]()
    var hrvOutlierIQR = 0.0
    var hrvOutlier1Q = 0.0
    var hrvOutlier3Q = 0.0
    var hrvOutlierLowCutoff = 0.0
    var hrvOutlierHighCutoff = 0.0
//
    var hrvMax = 0.0
    var hrvMin = 0.0
    var hrv1Q = 0.0
    var hrv0_75Q = 0.0
    var hrv1_5Q = 0.0
    var hrv2_5Q = 0.0
    var hrv3_25Q = 0.0
    var hrv3Q = 0.0
    var hrvMedian = 0.0
//
    var hrvReadinessPercentage = 0.0
//
    var coreDataHRVCalculationArray = [Double]()
    var coreDataHRVTimeArray = [Date]()
    var coreDataHRVValueArray = [Double]()
//
    var coreDataHRVValue = 0.0
    var coreDataHRVTime: Date? = nil
    var coreDataHRVCalculation = 0.0
//
    var readinessColor:Color = .blue

    struct HomeView: View {
        //Core Data SwiftUI Object Management
        @Environment(\.managedObjectContext) var managedObjectContext
        
        //State Variables
        @State private var recentHRVValueState = 0
        @State private var recentHRVTimeState: String = ""
        @State private var finalReadinessPercentage = 0
        @State private var readinessColorState:Color = .gray
        @State private var hrvMorningRecordedAlertHidden = true
        @State private var noLastHRVAlertHidden = true
        @State private var creatingBaselineAlertHidden = true
        @State private var readinessBarState = 0
        
        
        //Alert Enum
        
        
        //MARK: - SWiftui
        var body: some View {
            NavigationView {
                VStack {
                    HStack(alignment: .center) {
                        Text("Current Day Load:")
                            .multilineTextAlignment(.center)

                        ZStack {
                            CircularProgress(
                                progress: CGFloat(readinessBarState),
                                lineWidth: 15,
                                foregroundColor: readinessColorState,
                                backgroundColor: readinessColorState.opacity(0.20)
                            ).rotationEffect(.degrees(-90)).frame(width: 150, height: 150, alignment: .center)
                            CircularProgress(
                                progress: 26,
                                lineWidth: 15,
                                foregroundColor: .gray,
                                backgroundColor: Color.gray.opacity(0.20)
                            ).rotationEffect(.degrees(-90)).frame(width: 200, height: 200, alignment: .center)
                            Circle()
                                .foregroundColor(readinessColorState)
                                    .frame(width: 85, height: 85)
                            Text("\(finalReadinessPercentage)")
                                .font(Font.largeTitle.bold())
                                .foregroundColor(.white)
                                .shadow(radius: 8)
                            
                        }
                        Text("Current Day Load:")
                            .multilineTextAlignment(.center)

                    }
                    Text("Last HRV Number: \(recentHRVValueState)")
                    Text("Last HRV Recorded Time: \(recentHRVTimeState)")
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                                print("Moving back to the foreground!")
                            newReadinessCalculation()
                        }
                    Button(action: {
                        newReadinessCalculation()
                    }) {
                        Text("Test Button - Developer Use")
                    }.onAppear(perform: {
                        print("Recovery Appeared using OnAppear")
                        newReadinessCalculation()
                    })
                    
                    if !hrvMorningRecordedAlertHidden {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.20))
                                .frame(width: 350, height: 120)
                                .cornerRadius(10)
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.orange)
                                    Text("Your Body Energy Calculation is not up to date.")
                                        .font(.headline)
                                }
                                Text("The most recent Body Energy score is from yesterday. Go to the breathe app on your Apple Watch to update your score.")
                                    .frame(width: 340)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    if !creatingBaselineAlertHidden {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.20))
                                .frame(width: 350, height: 120)
                                .cornerRadius(10)
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.blue)
                                    Text("Calculation Baseline.")
                                        .font(.headline)
                                }
                                Text("We are currently calculating your baseline. Please wear your watch and come back regularly to see your energy levels.")
                                    .frame(width: 340)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    if !noLastHRVAlertHidden {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.20))
                                .frame(width: 350, height: 120)
                                .cornerRadius(10)
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.red)
                                    Text("There is no HRV Health data.")
                                        .font(.headline)
                                }
                                Text("Please wear your Watch all day and report back later to see your readiness calculation.")
                                    .frame(width: 340)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.gray.opacity(0.20))
                            .frame(width: 350, height: 120)
                            .cornerRadius(10)
                        VStack {
                            HStack {
                                Image(systemName: "info.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("You can push it hard today!")
                                    .font(.headline)
                            }
                            Text("To reach your Recommended Day Load, go on your normal 20 mile bike ride! (Work in progress, not an actual suggestion)")
                                .frame(width: 340)
                                .multilineTextAlignment(.center)
                        }
                    }
                    Text("Build 0.1.12")
                }
            }
        }
        
        // MARK: - CRUD Functions
        
        //Saves whatever we are working with
        func saveContext() {
            do {
                try managedObjectContext.save()
            } catch {
                print("Error saving managed object context: \(error)")
            }
        }
        
        // MARK: - Functions
        
        func fullReadinessCalculation() {
            findMostRecentHRV {
                find30DayHRVArray {
                    hrvRemoveOutliers {
                        hrvStatsCalculations {
                            calculateReadinessPercent {
                                changeReadinessTextandColors()
                            }
                        }
                    }
                }
            }
        }
        
        func findMostRecentHRV(_ completion : @escaping()->()) {
            hkm.variabilityMostRecent(from: weekAgoStartDate, to: Date()) { (results) in
                var lastHRV = 0.0
                var lastHRVTime: Date? = nil
                
                for result in results {
                    lastHRV = result.quantity.doubleValue(for: .variabilityUnit)
                    lastHRVTime = result.startDate
                }
                
                //Create guard here if there is no data
                guard lastHRV > 0.0 else {
                    print("No recent data to calculate, guard is enabled and everything stops")
                    self.finalReadinessPercentage = 0
                    self.noLastHRVAlertHidden = false
                    self.readinessColorState = .gray
                    return
                }
                self.noLastHRVAlertHidden = true
                recentHRVValue = Double(lastHRV)
                recentHRVTime = lastHRVTime
                //
                print(recentHRVValue)
                print(lastHRVTime!)
                //
                let formattedDate = getFormattedDate(date: recentHRVTime!, format: "MMM d, hh:mm a")
                print("Formatted Date: \(formattedDate)")
                self.recentHRVTimeState = String("\(formattedDate)")
                self.recentHRVValueState = Int(recentHRVValue)
                if recentHRVTime! < lastMidnight {
                    hrvMorningRecordedAlertHidden = false
                } else if recentHRVTime! >= lastMidnight {
                    hrvMorningRecordedAlertHidden = true
                }
                completion()
                
                
//                let utcTimeZone = TimeZone(abbreviation: "UTC")!
//                let pdtTimeZone = TimeZone(abbreviation: "PDT")!
//                let dateString = "2020-12-08T20:10:00.888Z"
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
//
//                print(dateFormatter.date(from: dateString))
//                print(dateFormatter.date(from: dateString, timeZoneInString: utcTimeZone))
//                print(dateFormatter.date(from: dateString, timeZoneInString: utcTimeZone, outputTimeZone: pdtTimeZone))
//
//
//                print(dateFormatter.date(from: String("\(lastHRVTime!)"), timeZoneInString: utcTimeZone, outputTimeZone: pdtTimeZone)!)
//
//               //RecentHRVTime needs to be a date
//               recentHRVTime = dateFormatter.date(from: String("\(lastHRVTime!)"), timeZoneInString: utcTimeZone, outputTimeZone: pdtTimeZone)
//                print("\(recentHRVTime!)")
 
                
            }
        }
        
        func find30DayHRVArray(_ completion : @escaping()->()) {
            hkm.variability(from: monthAgoStartDate, to: Date()) { (results) in
                
                var variabilityRetrieve = 0.0
                var variabilityRetrieveArray = [Double]()
                
                for result in results {
                    variabilityRetrieve = result.quantity.doubleValue(for: .variabilityUnit)
                    variabilityRetrieveArray.append(variabilityRetrieve)
                }
                variability30DayArray = variabilityRetrieveArray
                print(variability30DayArray)
                completion()
            }
        }
        func hrvRemoveOutliers(_ completion : @escaping()->()) {
            hrvOutlier1Q = (Sigma.percentile(variability30DayArray, percentile: 0.25) ?? 0.0)
            hrvOutlier3Q = (Sigma.percentile(variability30DayArray, percentile: 0.75) ?? 0.0)
            
            hrvOutlierIQR = hrvOutlier3Q - hrvOutlier1Q
            
            hrvOutlierLowCutoff = hrvOutlier1Q - (1.5 * hrvOutlierIQR)
            hrvOutlierHighCutoff = hrvOutlier3Q + (1.5 * hrvOutlierIQR)
            
            variability30DayArrayNoOutliers = variability30DayArray.filter { $0 < hrvOutlierHighCutoff && $0 > hrvOutlierLowCutoff }
            
            completion()
        }
        
        func hrvStatsCalculations(_ completion : @escaping()->()) {
            hrvMax = variability30DayArrayNoOutliers.max() ?? 0.0
            hrvMin = variability30DayArrayNoOutliers.min() ?? 0.0
            hrv1Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.25) ?? 0.0
            hrv3Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.75) ?? 0.0
            hrvMedian = Sigma.median(variability30DayArrayNoOutliers) ?? 0.0
            
            print("Max: \(hrvMax) Min: \(hrvMin) 1Q: \(hrv1Q) 3Q: \(hrv3Q) Median: \(hrvMedian)")
            completion()
        }
        
        func calculateReadinessPercent(_ completion : @escaping()->()) {
            if recentHRVValue <= hrvMin {
                hrvReadinessPercentage = 0.0
            } else if recentHRVValue >= hrvMax {
                hrvReadinessPercentage = 99.0
            } else if hrvMin <= recentHRVValue && recentHRVValue <= hrv1Q {
                hrvReadinessPercentage = ((((recentHRVValue - hrvMin) / (hrv1Q - hrvMin)) * 25.0) + 0.0)
            } else if hrv1Q <= recentHRVValue && recentHRVValue <= hrvMedian {
                hrvReadinessPercentage = ((((recentHRVValue - hrv1Q) / (hrvMedian - hrv1Q)) * 25.0) + 25.0)
            } else if hrvMedian <= recentHRVValue && recentHRVValue <= hrv3Q {
                hrvReadinessPercentage = ((((recentHRVValue - hrvMedian) / (hrv3Q - hrvMedian)) * 25.0) + 50.0)
            } else if hrv3Q <= recentHRVValue && recentHRVValue <= hrvMax {
                hrvReadinessPercentage = ((((recentHRVValue - hrv3Q) / (hrvMax - hrv3Q)) * 25.0) + 75.0)
            }
            print("Readiness % is: \(hrvReadinessPercentage)")
            self.finalReadinessPercentage = Int(hrvReadinessPercentage)
            completion()
        }
        
        func changeReadinessTextandColors() {
            if hrvReadinessPercentage <= 39 {
                readinessColor = .red
            } else if hrvReadinessPercentage > 39 && hrvReadinessPercentage < 74 {
                readinessColor = .orange
            } else if hrvReadinessPercentage >= 74 {
                readinessColor = .green
            }
            readinessColorState = readinessColor
            print("Bar color is: \(readinessColor)")
        }
        func saveFinalReadinessCalculation() {
            let newReadinessCalculationWrite = Readiness(context: managedObjectContext)
            
            newReadinessCalculationWrite.calculation = hrvReadinessPercentage
            newReadinessCalculationWrite.hrv = recentHRVValue
            newReadinessCalculationWrite.time = recentHRVTime
            
            saveContext()
            
        }
        
        
        //MARK: - New Core Data Manipulation
        @FetchRequest(
            entity: Readiness.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Readiness.time, ascending: false)]
        ) var coreDataItems: FetchedResults<Readiness>
        
        //MARK: - New Functions
        func getFormattedDate(date: Date, format: String) -> String {
                let dateformat = DateFormatter()
                dateformat.dateFormat = format
                return dateformat.string(from: date)
        }
        
        func newReadinessCalculation() {
            //Where all of our functions will be put in and then called
            findNewHRVReading {
                findOldCoreDataReading {
                    compareNewAndOldData {
                        getHRVArrayFromHealth {
                            checkAmountofHRVArrayValues {
                                    removeOutliers {
                                        calculateStats {
                                            recentHRVRecoveryCalculation {
                                                compareAndCalculateNewReadinessScore {
                                                    changeReadinessColorsandText {
                                                        saveNewCalculationToCD()
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
        
        
        
        func findNewHRVReading(_ completion : @escaping()->()) {
            hkm.variabilityMostRecent(from: weekAgoStartDate, to: Date()) { (results) in
                var lastHRV = 0.0
                var lastHRVTime: Date? = nil
                
                for result in results {
                    lastHRV = result.quantity.doubleValue(for: .variabilityUnit)
                    lastHRVTime = result.startDate
                }
                
                //Revise this?
                guard lastHRV > 0.0 else {
                    print("No recent data to calculate, guard is enabled, everything stops, and alert shows")
                    self.finalReadinessPercentage = 0
                    self.noLastHRVAlertHidden = false
                    self.readinessColorState = .gray
                    return
                }
                
                self.noLastHRVAlertHidden = true
                recentHRVValue = Double(lastHRV)
                recentHRVTime = lastHRVTime
                
                if recentHRVTime! < lastMidnight {
                    hrvMorningRecordedAlertHidden = false
                } else if recentHRVTime! >= lastMidnight {
                    hrvMorningRecordedAlertHidden = true
                }
                completion()
            }
        }
        
        func findOldCoreDataReading(_ completion : @escaping()->()) {
            coreDataHRVCalculationArray = coreDataItems.map {$0.calculation}
            coreDataHRVTimeArray = coreDataItems.map {$0.time!}
            coreDataHRVValueArray = coreDataItems.map {$0.hrv}
            
            coreDataHRVValue = coreDataHRVValueArray.first ?? 0
            coreDataHRVTime = coreDataHRVTimeArray.first ?? nil
            coreDataHRVCalculation = coreDataHRVCalculationArray.first ?? 0
            
            guard coreDataHRVValue > 0 else {

                
                newFinalHRVCalculation = Double.random(in: 60...65)
                
                saveNewCalculationToCD()
                
                changeReadinessColorsandTextnoCompletion()

                
                print("There were 0 core data items, so we created a baseline to save")
                self.creatingBaselineAlertHidden = false
                return
            }
                        
            print("Last core data value: \(coreDataHRVValue)")
            print("Last core data time: \(coreDataHRVTime)")
            print("Last core data calculation: \(coreDataHRVCalculation)")
            
            completion()
        }
        
        
        
        func compareNewAndOldData(_ completion : @escaping()->()) {
            //Compares new hrv reading and old to see if they are the same and continues or doesn't\
            //This stops with guard and just sets our values to what was in our core data variables if the recent hrv and the core data items are the same, meaning that nothing new has happened
            //It will continue with calculation if our hrv from health is newer than our core data items
            
            guard recentHRVTime! > coreDataHRVTime! else {
                //They are the same time, just update @state and color variables with most recent and formatting
                changeReadinessColorsandTextCoreData()
                return
            }
            completion()
            
        }
        
        func getHRVArrayFromHealth(_ completion : @escaping()->()) {
            hkm.variability(from: monthAgoStartDate, to: Date()) { (results) in
                
                var variabilityRetrieve = 0.0
                var variabilityRetrieveArray = [Double]()
                
                for result in results {
                    variabilityRetrieve = result.quantity.doubleValue(for: .variabilityUnit)
                    variabilityRetrieveArray.append(variabilityRetrieve)
                }
                variability30DayArray = variabilityRetrieveArray
                print(variability30DayArray)
                completion()
            }
            
        }

        func checkAmountofHRVArrayValues(_ completion : @escaping()->()) {
            //When we get our array we will see how many values we have
            //If there are not 4 data points, guard, calculate and save to core data, and have blue ! warning
                     
            guard variability30DayArray.count > 3 else {
                //If variability has less than 4 values, run this
                
                //Set our newFinalHRVCalculation to random Double(int 60...65)
                
                newFinalHRVCalculation = Double.random(in: 60...65)
                
                //Save to core data using saveNewCalculationToCD
                saveNewCalculationToCD()
                
                //Run change readiness colors and text w/o completion
                changeReadinessColorsandTextnoCompletion()
                
                //Make blue notification saying we are creating baseline
                print("Less than 4 data points worth of hrv from health")
                self.creatingBaselineAlertHidden = false

                return
            }
            
            self.creatingBaselineAlertHidden = true
            
            
            
            //If we have more than 4 items, continue as normal
            
            completion()
            
        }
        
        
        func removeOutliers(_ completion : @escaping()->()) {
            hrvOutlier1Q = (Sigma.percentile(variability30DayArray, percentile: 0.25) ?? 0.0)
            hrvOutlier3Q = (Sigma.percentile(variability30DayArray, percentile: 0.75) ?? 0.0)
            
            hrvOutlierIQR = hrvOutlier3Q - hrvOutlier1Q
            
            hrvOutlierLowCutoff = hrvOutlier1Q - (1.5 * hrvOutlierIQR)
            hrvOutlierHighCutoff = hrvOutlier3Q + (1.5 * hrvOutlierIQR)
            
            variability30DayArrayNoOutliers = variability30DayArray.filter { $0 < hrvOutlierHighCutoff && $0 > hrvOutlierLowCutoff }
            
            completion()
        }
        
        func calculateStats(_ completion : @escaping()->()) {
            hrvMax = variability30DayArrayNoOutliers.max() ?? 0.0
            hrvMin = variability30DayArrayNoOutliers.min() ?? 0.0
            hrv1Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.25) ?? 0.0
            hrv0_75Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.1875) ?? 0.0
            hrv1_5Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.375) ?? 0.0
            hrv2_5Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.625) ?? 0.0
            hrv3_25Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.8125) ?? 0.0
            hrv3Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.75) ?? 0.0
            hrvMedian = Sigma.median(variability30DayArrayNoOutliers) ?? 0.0
            
            print("Max: \(hrvMax) Min: \(hrvMin) 1Q: \(hrv1Q) 3Q: \(hrv3Q) Median: \(hrvMedian) 0.75Q: \(hrv0_75Q) 1.5Q: \(hrv1_5Q) 2.5Q: \(hrv2_5Q) 3.25Q: \(hrv3_25Q)")
            
            completion()
        }
        
        func recentHRVRecoveryCalculation(_ completion : @escaping()->()) {
            //We need to calculate our hrv recovery first before apply it into our algorithm...
            
            if recentHRVValue <= hrvMin {
                recentHRVCalculation = 0.0
            } else if recentHRVValue >= hrvMax {
                recentHRVCalculation = 99.0
            } else if hrvMin <= recentHRVValue && recentHRVValue <= hrv1Q {
                recentHRVCalculation = ((((recentHRVValue - hrvMin) / (hrv1Q - hrvMin)) * 25.0) + 0.0)
            } else if hrv1Q <= recentHRVValue && recentHRVValue <= hrvMedian {
                recentHRVCalculation = ((((recentHRVValue - hrv1Q) / (hrvMedian - hrv1Q)) * 25.0) + 25.0)
            } else if hrvMedian <= recentHRVValue && recentHRVValue <= hrv3Q {
                recentHRVCalculation = ((((recentHRVValue - hrvMedian) / (hrv3Q - hrvMedian)) * 25.0) + 50.0)
            } else if hrv3Q <= recentHRVValue && recentHRVValue <= hrvMax {
                recentHRVCalculation = ((((recentHRVValue - hrv3Q) / (hrvMax - hrv3Q)) * 25.0) + 75.0)
            }
            print("Recent HRV Calculation Func run")
            completion()
        }
        
        func compareAndCalculateNewReadinessScore(_ completion : @escaping()->()) {
            //Compares our old and new data to come up with a new score\
            //Append new calculation to new calculation variable
            //Appends to "newFinalHRVCalculation"
            
            //Check where our old readiness is first, then apply new
            
            if coreDataHRVCalculation < 25 { //in red
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 25
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 35
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = 60
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 68
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 70
                            }
                        } else if coreDataHRVCalculation == 25 { //on gate
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 25
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = 43
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = 60
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 69
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 71
                            }
                            
                        } else if coreDataHRVCalculation > 25 && coreDataHRVCalculation < 40 { //in yellow
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 20
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 25
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 58
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 72
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 75
                            }

                        } else if coreDataHRVCalculation == 40 { //on gate
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 25
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 30
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 58
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 75
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 80
                            }

                        } else if coreDataHRVCalculation > 40 && coreDataHRVCalculation < 65 { //in blue
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 35
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 35
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 38
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 80
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 85
                            }

                        } else if coreDataHRVCalculation == 65 { //on gate
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 38
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 45
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 49
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 85
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 90
                            }
                            
                        } else if coreDataHRVCalculation > 65 && coreDataHRVCalculation < 85 { //in green
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 50
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 53
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 85
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            }
                            
                        } else if coreDataHRVCalculation == 85 { //on gate
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 42
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 53
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 58
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = 60
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 85
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            }
                            
                        } else if coreDataHRVCalculation > 85 { //in pink
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 42
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 53
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 58
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = 60
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 85
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            }
                        }
            print("New HRV Calculation Func run")

            completion()
        }
        
        func changeReadinessColorsandText(_ completion : @escaping()->()) {
            //Changes the text based on our 3 new calculation variables
            //Changes the colors based on our new calculation
            
            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d, hh:mm a")

            
            //Changes Text
            self.recentHRVValueState = Int(recentHRVValue)
            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
            self.finalReadinessPercentage = Int(newFinalHRVCalculation)
            
            //Changes Colors and Bar Data
            if newFinalHRVCalculation <= 25 {
                readinessColor = .red
            } else if newFinalHRVCalculation > 25 && newFinalHRVCalculation <= 40 {
                readinessColor = .orange
            } else if newFinalHRVCalculation > 40 && newFinalHRVCalculation <= 65 {
                readinessColor = .blue
            } else if newFinalHRVCalculation > 65 && newFinalHRVCalculation <= 85 {
                readinessColor = .green
            } else if newFinalHRVCalculation > 85 {
                readinessColor = .purple
            }
            
            self.readinessBarState = Int(newFinalHRVCalculation)
            self.readinessColorState = readinessColor
            
            completion()
            
        }
        
        func saveNewCalculationToCD() {
            //Saves new calculation / data to core data with save context
            let newReadinessCalculationWrite = Readiness(context: managedObjectContext)

            newReadinessCalculationWrite.calculation = newFinalHRVCalculation
            newReadinessCalculationWrite.hrv = recentHRVValue
            newReadinessCalculationWrite.time = recentHRVTime
            
            saveContext()
        }
        
        func saveNewCalculationToCDGuard() {
            //Saves new calculation / data to core data with save context
            let newReadinessCalculationWrite = Readiness(context: managedObjectContext)

            newReadinessCalculationWrite.calculation = recentHRVCalculation
            newReadinessCalculationWrite.hrv = recentHRVValue
            newReadinessCalculationWrite.time = recentHRVTime
            
            saveContext()
        }
        
        func changeReadinessColorsandTextCoreData() {
            //Same as above function, but uses core data in our comparison
            
            let formattedCoreDataDate = getFormattedDate(date: coreDataHRVTime!, format: "MMM d, hh:mm a")
            
            //Changes Text
            self.recentHRVValueState = Int(coreDataHRVValue)
            self.recentHRVTimeState = String("\(formattedCoreDataDate)")
            self.finalReadinessPercentage = Int(coreDataHRVCalculation)
            
            //Changes Colors and Bar
            if coreDataHRVCalculation <= 25 {
                readinessColor = .red
            } else if coreDataHRVCalculation > 25 && coreDataHRVCalculation <= 40 {
                readinessColor = .orange
            } else if coreDataHRVCalculation > 40 && coreDataHRVCalculation <= 65 {
                readinessColor = .blue
            } else if coreDataHRVCalculation > 65 && coreDataHRVCalculation <= 85 {
                readinessColor = .green
            } else if coreDataHRVCalculation > 85 {
                readinessColor = .purple
            }
            
            print("Readiness color is \(readinessColor)")
            
            self.readinessBarState = Int(coreDataHRVCalculation)
            self.readinessColorState = readinessColor
        }
        
        func changeReadinessColorsandTextnoCompletion() {
            //Changes the text based on our 3 new calculation variables
            //Changes the colors based on our new calculation
            
            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d, hh:mm a")

            
            //Changes Text
            self.recentHRVValueState = Int(recentHRVValue)
            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
            self.finalReadinessPercentage = Int(newFinalHRVCalculation)
            
            //Changes Colors and Bar Data
            if newFinalHRVCalculation <= 25 {
                readinessColor = .red
            } else if newFinalHRVCalculation > 25 && newFinalHRVCalculation <= 40 {
                readinessColor = .orange
            } else if newFinalHRVCalculation > 40 && newFinalHRVCalculation <= 65 {
                readinessColor = .blue
            } else if newFinalHRVCalculation > 65 && newFinalHRVCalculation <= 85 {
                readinessColor = .green
            } else if newFinalHRVCalculation > 85 {
                readinessColor = .purple
            }
            
            self.readinessBarState = Int(newFinalHRVCalculation)
            self.readinessColorState = readinessColor
            
        }
        
        func changeReadinessColorsandTextnoCompletionGuard() {
            //Changes the text based on our 3 new calculation variables
            //Changes the colors based on our new calculation
            
            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d, hh:mm a")

            
            //Changes Text
            self.recentHRVValueState = Int(recentHRVValue)
            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
            self.finalReadinessPercentage = Int(recentHRVCalculation)
            
            //Changes Colors and Bar Data
            if recentHRVCalculation <= 25 {
                readinessColor = .red
            } else if recentHRVCalculation > 25 && recentHRVCalculation <= 40 {
                readinessColor = .orange
            } else if recentHRVCalculation > 40 && recentHRVCalculation <= 65 {
                readinessColor = .blue
            } else if recentHRVCalculation > 65 && recentHRVCalculation <= 85 {
                readinessColor = .green
            } else if recentHRVCalculation > 85 {
                readinessColor = .purple
            }
            
            self.readinessBarState = Int(recentHRVCalculation)
            self.readinessColorState = readinessColor
            
        }
        
        
        
    }



    //MARK: - Readiness View
    struct ReadinessView: View {
        var body: some View {
            Text("More detailed information about your Body Energy will be available here.")
                .multilineTextAlignment(.center)
            }
    }

//MARK: - Body Load View
struct BodyLoadView: View {
    var body: some View {
        NavigationView {
            Text("More detailed information about your Body Load will be available here.")
                .multilineTextAlignment(.center)

        }
    }
}
    
    //MARK: - AppView to Create Tabs
    struct AppView: View {
        var body: some View {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                ReadinessView()
                    .tabItem {
                        Image(systemName: "battery.100")
                        Text("Body Energy")
                    }
                BodyLoadView()
                    .tabItem {
                        Image(systemName: "bolt.fill")
                        Text("Body Load")
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
