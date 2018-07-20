//
//  ViewController.swift
//  WhereISS App
//
//  Created by SERDAR ILARSLAN on 19/07/2018.
//  Copyright © 2018 SERDAR ILARSLAN. All rights reserved.
//

import UIKit
import Mapbox
import SwiftyJSON
import Alamofire

class ViewController: UIViewController, MGLMapViewDelegate {
    
    // Declaring the global constants and variables
    let URL_ISS_Location = "http://api.open-notify.org/iss-now.json"
    let URL_ISS_Names = "http://api.open-notify.org/astros.json"
    let url = URL(string: "mapbox://styles/mapbox/streets-v10")
    let defaults = UserDefaults.standard
    
    var ISS_Current_Location = [String : Double]() // To keep location info taken from API
    var ISS_People : String = "" // To keep people names on ISS
    var ISS_Info = [String : String]() // To store ISS Location and Time info
    var mapView = MGLMapView()
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MGLMapView(frame: view.bounds, styleURL: url)
        
        getInfoData()
        
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.getInfoData), userInfo: nil, repeats: true)
    }
    
    // To call two main functions which will connect to the API point and gather JSON file and run jsonData()
    @objc func getInfoData(){
        getISSInfo(url: URL_ISS_Location, infoType: "ISS Location")
        getISSInfo(url: URL_ISS_Names, infoType: "ISS Names")
    }
    
    // #################### URL NETWORKING AND JSON PARSING ##############################
    
    // GET method defined within the function called getISSInfo()
    
    func getISSInfo(url : String, infoType : String){
        Alamofire.request(url, method : .get).responseJSON{
            response in
            if response.result.isSuccess{
                
                print("Success...")
                let infoJSON : JSON = JSON(response.result.value!)
                self.jsonData(json: infoJSON, infoType: infoType)
                
            }else{
                
                print("Error \(String(describing: response.result.error))")
                
            }
        }

    }
    
    // ######################## jsonData() to parse json data and update UI #####################
    
    // JSON Data Parsing for Location / Setting the Location on the map and People on ISS from API
    
    func jsonData(json : JSON, infoType : String){
        // ISS Location coordinates
        if infoType == "ISS Location"{
            if json["message"].string != nil{
                ISS_Current_Location["latitude"] = json["iss_position"]["latitude"].doubleValue//Latitude
                ISS_Current_Location["longitude"] = json["iss_position"]["longitude"].doubleValue//Longitude
                mapView = MGLMapView(frame: view.bounds)//Getting view bounds again for refreshing the screen
                mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                mapView.setCenter(CLLocationCoordinate2D(latitude: ISS_Current_Location["latitude"]!, longitude: ISS_Current_Location["longitude"]!), zoomLevel: 5, animated: false)

                view.addSubview(mapView)
                
                // Date Formatter
                let unixTimestamp = json["timestamp"].doubleValue
                let date = Date(timeIntervalSince1970: unixTimestamp)
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(abbreviation: "GMT") //Timezone
                dateFormatter.locale = NSLocale.current
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" //Date Format
                let strDate = dateFormatter.string(from: date)
                
                // Saving the latest location information to UserDefaults
                ISS_Info["TIME"] = strDate
                ISS_Info["LATITUDE"] = "\(String(describing: ISS_Current_Location["latitude"]))"
                ISS_Info["LONGITUDE"] = "\(String(describing: ISS_Current_Location["longitude"]))"
                defaults.set(ISS_Info, forKey: "ISS_Location_Info")
                
                // Putting the date into the label on top of mapView
                print("date: \(date)")
                let label = UILabel(frame: CGRect(x: view.frame.width - 200 , y: view.frame.height - 120 , width: 200, height: 100))
                label.textAlignment = NSTextAlignment.center
                label.font = UIFont(name: label.font.fontName, size: 10)
                label.text = " \(strDate)"
                view.addSubview(label)
            }else{
                print("Conecction Issue for The Location! Please try it again")
                let labelError = UILabel(frame: CGRect(x: view.frame.width/2, y: view.frame.height/2, width: 200, height: 100))
                labelError.textAlignment = NSTextAlignment.center
                labelError.font = UIFont(name: labelError.font.fontName, size: 20)
                labelError.text = "Connection Issue! Try again!"
                view.addSubview(labelError)
            }
        }
        
        // ISS People's names
        if infoType == "ISS Names"{
            if ISS_Current_Location["latitude"] != nil{
                for person in 0..<json["number"].intValue{
                    ISS_People = ISS_People + " - " + (json["people"][person]["name"].string!)
                }
                // Set the delegate property of our map view to `self` after instantiating it.
                mapView.delegate = self
                
                // Declare the marker `annotation` and set its coordinates, title, and subtitle.
                let annotation = MGLPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: ISS_Current_Location["latitude"]!, longitude: ISS_Current_Location["longitude"]!)
                annotation.title = "People Names"
                annotation.subtitle = ISS_People
                // Add marker `annotation` to the map.
                mapView.addAnnotation(annotation)
            }
            else{
                print("Connection Issue for the Marker! Please try it again!")
                let labelError = UILabel(frame: CGRect(x: view.frame.width/2 , y: view.frame.height/2 , width: 200, height: 100))
                labelError.textAlignment = NSTextAlignment.center
                labelError.font = UIFont(name: labelError.font.fontName, size: 20)
                labelError.text = "Connection Issue! Try again!"
                view.addSubview(labelError)
            }
        }
    }
    
    // Use the default marker. See also: our view annotation or custom marker examples.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

