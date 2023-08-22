//
//  ViewController.swift
//  Lab03
//
//  Created by Harsh Bhatt on 2023-03-14.
//

import UIKit
import CoreLocation
import CoreData

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var searchLocationTextField: UITextField!
    
    @IBOutlet weak var weatherConditionImage: UIImageView!
    
    @IBOutlet weak var locationImage: UIImageView!
    
    @IBOutlet weak var tempImage: UIImageView!
    
    @IBOutlet weak var feelsLikeImage: UIImageView!
    
    @IBOutlet weak var timeImage: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var degreeLabel: UILabel!
    
    @IBOutlet weak var feelsLikeLabel: UILabel!
    
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var enableFahrenheit: UISwitch!
    
    @IBOutlet weak var handleErrorText: UILabel!
    
    private var locationManager: CLLocationManager!
    
    private var lat: Double?
    private var long: Double?
    private var tempF: String = ""
    private var tempC: String = ""
    private var feelsLikeTempF: String = ""
    private var feelsLikeTempC: String = ""
    private let goToHistorySegue = "goToHistoryScreen"
    
    private var items: [HistoryItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //search delegate
        searchLocationTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //to close on screen keyboard
        textField.endEditing(true)
        
        //make a network call after search button is tapped
        loadWeatherAPI(searchLocation: textField.text)
        return true
    }

    //checking switch value
    @IBAction func changeSwitchValue(_ sender: UISwitch) {
        if enableFahrenheit.isOn {
            (tempF.isEmpty) ? (temperatureLabel.text = "Temperature") : (temperatureLabel.text = tempF)
            (tempF.isEmpty) ? (degreeLabel.text = "") : (degreeLabel.text = "°F")
            
            (feelsLikeTempF.isEmpty) ? (feelsLikeLabel.text = "") : (feelsLikeLabel.text = "\(feelsLikeTempF)°F")
        } else {
            (tempC.isEmpty) ? (temperatureLabel.text = "Temperature") : (temperatureLabel.text = tempC)
            (tempC.isEmpty) ? (degreeLabel.text = "") : (degreeLabel.text = "°C")
            
            (feelsLikeTempC.isEmpty) ? (feelsLikeLabel.text = "") : (feelsLikeLabel.text = "\(feelsLikeTempC)°C")
        }
    }
    
    @IBAction func onLocationTapped(_ sender: UIButton) {
        
        //Clear the search text when fetching current location
        searchLocationTextField.text = ""
        
        //on location tap requesting user for location permission
        locationRequest()
    }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        
        //make a network call after search button is tapped
        loadWeatherAPI(searchLocation: searchLocationTextField.text)
    }
    
    //This function will request user for location authorization
    private func locationRequest(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    //This function will get current Lat & Long of the user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lat = location.coordinate.latitude
        long = location.coordinate.longitude
        
        //after getting lat/long making a Network call
        if let lat = lat, let long = long {
            //format to pass lat/long in query
            let query = "\(lat),\(long)"
            loadWeatherAPI(searchLocation: query)
        }
    }
    
    //print error if occured while requesting location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
    
    //checking location status
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Location authorization granted.")
                    if let lat = lat, let long = long {
                        let query = "\(lat),\(long)"
                        loadWeatherAPI(searchLocation: query)
                    }
                case .denied, .restricted:
                    print("Location authorization denied.")
                    self.requestLocationAuthorization()
                case .notDetermined:
                    print("Location authorization not yet determined.")
                case .authorized:
                    print("Location authorization granted.")
                @unknown default:
                    fatalError()
                }
    }
    
    private func loadWeatherAPI(searchLocation: String?) {
        guard let searchLocation = searchLocation else {
            return
        }
        
        guard let url = getURL(query: searchLocation) else {
            print("Error getting the URL")
            return
        }

        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: url) { data, response, error in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                        print("Unexpected response")
                        return
            }
            
            switch httpResponse.statusCode {
                    case 200:
                        // Handle the success case
                        guard let data = data else {
                            print("No data received")
                            return
                        }
                
                        if let weatherResponse = self.parseWeatherJSON(data: data) {
                                print("data ---> \(data)")
                                //Assigning values to the variables
                                self.tempC = "\(weatherResponse.current.temp_c)"
                                self.tempF = "\(weatherResponse.current.temp_f)"

                                self.feelsLikeTempC = "\(weatherResponse.current.feelslike_c)"
                                self.feelsLikeTempF = "\(weatherResponse.current.feelslike_f)"

                                DispatchQueue.main.async { [self] in
                                        if enableFahrenheit.isOn {
                                                displayWeatherInfo(location: weatherResponse.location.name, temperature:tempF, degree: "F", time: weatherResponse.location.localtime, feelsLike: "\(feelsLikeTempF)°F")
                                        } else {
                                                displayWeatherInfo(location: weatherResponse.location.name, temperature:tempC, degree: "C", time: weatherResponse.location.localtime, feelsLike: "\(feelsLikeTempC)°C")
                                        }
                                    setWeatherIconBasedOnCode(code: weatherResponse.current.condition.code)
                                }
                        }
                    // Parse the response data
                    case 400, 403:
                        // Handle the wrong API key error
                        guard let data = data else {
                            print("No data received")
                            return
                        }
                        do {
                            let decoder = JSONDecoder()
                            var errorResponse: Response?
                            
                            errorResponse = try decoder.decode(Response.self, from: data)
                            
                            if let errorCode = errorResponse?.error?.code,
                            let errorMessage = errorResponse?.error?.message {
                                
                                print("Error Code -> \(errorCode)")
                                print("Error Message -> \(errorMessage)")
                                DispatchQueue.main.async {
                                    self.handleErrorText.text = "Code: \(errorCode)" + " Message: \(errorMessage)"
                                    self.saveAPIError(errorCode: "\(errorCode)", errorMessage: errorMessage, errorCodeInt: errorCode)
                                }
                            }
                        } catch {
                            print("Error decoding error response: \(error.localizedDescription)")
                        }
                    default:
                        print("Unexpected status code: \(httpResponse.statusCode)")
                    }
        }
        dataTask.resume()
    }
    
    //function to display Location and Temperature in label
    private func displayWeatherInfo(location: String, temperature: String, degree: String, time: String, feelsLike: String){
        locationLabel.text = location
        temperatureLabel.text = "\(temperature)"
        degreeLabel.text = "°\(degree)"
        timeLabel.text = "\(formatTime(time: time))"
        feelsLikeLabel.text = feelsLike
    }
    
    //function to setup URL
    private func getURL(query: String) -> URL? {
        let baseURL = "https://api.weatherapi.com/v1/"
        let currentEndPoint = "current.json"
        //let apiKey = "f79bb512536f4fccb6652011233003"
        let apiKey = "c4c9ba77110141da98f192111231608"
        
        guard let url = "\(baseURL)\(currentEndPoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        print(url)
        return URL(string: url)
    }
    
    //function to parse JSON
    private func parseWeatherJSON(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        
        do{
            weather = try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Error Decoding")
        }
        
        return weather
    }
    
    //helper function to set images based on weather code
    private func setWeatherIconBasedOnCode(code: Int){
        switch code {
        case 1000:
            displayWeatherImage(imageName: "sun.max.circle")
        case 1006 ,1003:
            displayWeatherImage(imageName: "cloud.circle")
        case 1009:
            displayWeatherImage(imageName: "cloud")
        case 1030, 1150, 1153:
            displayWeatherImage(imageName: "humidifier.and.droplets")
        case 1063, 1180:
            displayWeatherImage(imageName: "cloud.sun.rain")
        case 1066, 1069, 1072, 1087:
            displayWeatherImage(imageName: "cloud.snow")
        case 1114:
            displayWeatherImage(imageName: "snowflake.circle")
        case 1117, 1198:
            displayWeatherImage(imageName: "snowflake.circle.fill")
        case 1135:
            displayWeatherImage(imageName: "cloud.fog.circle")
        case 1168, 1171:
            displayWeatherImage(imageName: "cloud.drizzle.circle")
        case 1183, 1186, 1189, 1240:
            displayWeatherImage(imageName: "cloud.rain")
        case 1192, 1195, 1201:
            displayWeatherImage(imageName: "cloud.heavyrain.circle")
        case 1204, 1207, 1210, 1213, 1216:
            displayWeatherImage(imageName: "cloud.snow")
        case 1219, 1222:
            displayWeatherImage(imageName: "cloud.snow.circle")
        case 1225:
            displayWeatherImage(imageName: "snowflake.circle")
        case 1237:
            displayWeatherImage(imageName: "cloud.snow.circle.fill")
        case 1243, 1246:
            displayWeatherImage(imageName: "cloud.bolt.rain")
        case 1255, 1261:
            displayWeatherImage(imageName: "snowflake.road.lane.dashed")
        case 1258:
            displayWeatherImage(imageName: "cloud.snow")
        case 1273, 1276:
            displayWeatherImage(imageName: "cloud.bolt.rain")
        case 1279, 1282:
            displayWeatherImage(imageName: "cloud.bolt.rain.circle")
        default:
            displayWeatherImage(imageName: "sun.dust.circle")
        }
    }
    
    //function to display image in UI Image
    private func displayWeatherImage(imageName: String) {
        //palette colors config for the image
        let config = UIImage.SymbolConfiguration(paletteColors: [
            .white, .systemOrange, .gray
        ])
        
        //setting config for all the images
        weatherConditionImage.preferredSymbolConfiguration = config
        locationImage.preferredSymbolConfiguration = config
        tempImage.preferredSymbolConfiguration = config
        feelsLikeImage.preferredSymbolConfiguration = config
        timeImage.preferredSymbolConfiguration = config
        
        weatherConditionImage.image = UIImage(systemName: imageName)
        locationImage.image = UIImage(systemName: "building.2")
        tempImage.image = UIImage(systemName: "thermometer.transmission")
        feelsLikeImage.image = UIImage(systemName: "figure.wave.circle")
        timeImage.image = UIImage(systemName: "clock")
    }
    
    //Alertbox to show if location is denied
    private func requestLocationAuthorization() {
        let alert = UIAlertController(title: "Location Access Required", message: "Please grant location access to get weather data", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                })
            }
        }
        alert.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //helper function to extract only Time from date and time
    private func formatTime(time:String) -> String {
        let dateString = time
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        var timeString: String = ""
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "hh:mm a"
            timeString = dateFormatter.string(from: date)
        }
        return timeString
    }
    
    @IBAction func historyButtonTapped(_ sender: UIButton) {
        navigateToHistory()
    }
    
    private func navigateToHistory(){
        performSegue(withIdentifier: goToHistorySegue, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == goToHistorySegue {
        }
    }
    
    private func saveAPIError(errorCode: String, errorMessage: String ,errorCodeInt: Int){
        guard let context = self.getCoreContext() else {
            return
        }
        let item = HistoryItem(context: context)
        item.errorCode = errorCode
        item.errorMessage = errorMessage
        
        //getting image name based on error code
        item.iconName = imageName(code: errorCodeInt)
        
        self.items.append(item)
        self.saveItems()
    }
    
    //return imagename based on error code
    private func imageName(code: Int) -> String {
        switch code {
        case 2008 :
            return "key.horizontal.fill"
        case 1006 :
            return "location.magnifyingglass"
        default :
            return "xmark.octagon"
        }
    }
    
    private func saveItems() {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    private func getCoreContext() -> NSManagedObjectContext? {
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    }
    
}

struct Response: Decodable {
    let error: WeatherAPIError?
}

struct WeatherAPIError: Codable {
    let code: Int
    let message: String
}

struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
    let localtime: String
}

struct Weather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let condition: WeatherCondition
    let wind_mph: Float
    let wind_kph: Float
    let humidity: Float
    let feelslike_c: Float
    let feelslike_f: Float
    let uv: Float
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}

