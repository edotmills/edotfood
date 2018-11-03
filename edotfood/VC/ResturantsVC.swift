//
//  ResturantsVC.swift
//  edotfood
//
//  Created by Eric Mills on 10/30/18.
//  Copyright © 2018 edotmills llc. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import AlamofireImage

class ResturantsVC: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    var location_manager:CLLocationManager = CLLocationManager()
    var resturants:[Resturant] = []
    var categories:[Category] = []
    var filtered_resturants:[Resturant] = []
    var tap_gesture:UITapGestureRecognizer!
    
    @IBOutlet var resturant_tableview:UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //Ask for permission to use location services
        location_manager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled()
        {
            location_manager.delegate = self
            location_manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            location_manager.startUpdatingLocation()
        }
        
        let dismiss_selector : Selector = #selector(ResturantsVC.dismissKeyboard)
        tap_gesture = UITapGestureRecognizer(target: self, action: dismiss_selector)
        
        tap_gesture.numberOfTapsRequired = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(ResturantsVC.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ResturantsVC.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notificaton : Notification){
        view.addGestureRecognizer(tap_gesture)
    }
    
    @objc func keyboardWillHide(_ notificaiton : Notification){
        view.removeGestureRecognizer(tap_gesture)
        self.dismissKeyboard()
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        location_manager.stopUpdatingLocation()
        
        //Once we have the users location we can use the Yelp API to find local resturants.
        find_local_resturants(lat: locValue.latitude, long: locValue.longitude, query: "")
    }
    
    // MARK: - IBAction Methods
    
    
    //Here I use the Yelp Fusion api to find all local resturants.
    func find_local_resturants(lat:Double, long:Double,query:String){
        
        let parameters: Parameters = [
            "latitude": "\(lat)",
            "longitude": "\(long)"
        ]
        
        let headers = ["Authorization": "Bearer 90BuGMVOBsth1wAh124QXBbIGDGpf6fpwwas3pxoZ4iMYL4uc7974Ey5n4dIQ37qPLuA5YrxmzDTf6H1EjrCPNyljoNW4OMdAS_dQppnG3kIm0cYjufhwqYcLlPYW3Yx"]
        
        let url:String = "https://api.yelp.com/v3/businesses/search?&latitude=\(lat)&longitude=\(long)&term=resturant,\(query)&sort_by=distance"
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            //I parse the response JSON and create Resturant and Category objects.
            if let json = response.result.value {
                if let json_dict = json as? [String : Any] {
                    if let resturants = json_dict["businesses"] as? [Dictionary<String,Any>] {
                        self.resturants = []
                        for resturant_dict in resturants {
                            guard let name = resturant_dict["name"] as? String else {
                                return
                            }
                            
                            guard let image_url = resturant_dict["image_url"] as? String else {
                                return
                            }
                            
                            guard let distance = resturant_dict["distance"] as? Double else {
                                return
                            }
                            
                            //Because I use category information for not only display but for filtering I created a seperate array.
                            var categories_array:[Category] = []
                            for category in resturant_dict["categories"] as! [Dictionary<String,String>] {
                               
                                guard let alias = category["alias"] else {
                                    return
                                }
                                guard let title = category["title"] else {
                                    return
                                }
                                
                                let category = Category.init(alias: alias, title: title)
                                categories_array.append(category)
                                
                                let had_category = self.categories.contains { element in
                                    if case category.alias = element.alias {
                                        return true
                                    } else {
                                        return false
                                    }
                                }
                                
                                if had_category{
                                    //Category Already there
                                }else{
                                    self.categories.append(category)
                                }
                                
                            }
                            
                            let resturant:Resturant = Resturant.init(name: name, image_url: image_url, categories: categories_array, distance: distance)
                            self.resturants.append(resturant)
                        }
                        
                        DispatchQueue.main.async{
                            
                            self.filtered_resturants = self.resturants
                            self.resturant_tableview.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    // This method filters the filtered_resturants array. Once an item is selected I check each resturants categories to see if it is included.
    func filter_by_category(alias:String){
        filtered_resturants = []
        for resturant in resturants {
            if let categories = resturant.categories {
                for category in categories {
                    if let cat_alias = category.alias {
                        if cat_alias == alias {
                            filtered_resturants.append(resturant)
                        }
                    }
                }
            }
        }

        resturant_tableview.reloadData()
    }
    
    //MARK: - UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered_resturants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resturant_cell = tableView.dequeueReusableCell(withIdentifier: "ResturantCell", for: indexPath) as! ResturantCell
        
        let resturant = filtered_resturants[indexPath.item]
        
        if let name = resturant.name {
            resturant_cell.rest_name.text = name
        }
        
        resturant_cell.rest_imageeview.image = nil
        
        //Normally I would subclass UIImageview for downloading images. It seems like overkill for this exercise.
        if let image_url = resturant.image_url {
            resturant_cell.rest_imageeview.layer.cornerRadius = 5
            resturant_cell.rest_imageeview.layer.masksToBounds = true
            
            Alamofire.request(image_url).responseImage { response in
                
                if let image = response.result.value {
                    DispatchQueue.main.async{
                        resturant_cell.rest_imageeview.image = image
                    }
                }
            }
        }
        
        if let distance = resturant.distance {
            let formatter = MeasurementFormatter()
            
            let distance_miles = distance / 1609.34
            let formatted_distance = Measurement(value: distance_miles, unit: UnitLength.miles)
            
            resturant_cell.rest_distance.text = formatter.string(from: formatted_distance)
        }
        
        if let categories = resturants[indexPath.item].categories {
            var category_string:String = ""
            for category in categories {
                if let title = category.title {
                    if category_string.isEmpty {
                        category_string = title
                    }else{
                        category_string = "\(category_string), \(title)"
                    }
                }
                
                resturant_cell.rest_type.text = category_string
            }
        }
        
        return resturant_cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: - UISearchBarDelegate Methods
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        guard let lat = location_manager.location?.coordinate.latitude else {
            return
        }
        
        guard let long = location_manager.location?.coordinate.longitude else {
            return
        }
        
        find_local_resturants(lat: lat, long: long, query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.dismissKeyboard()
    }
}
