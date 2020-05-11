//
//  AddressSearchViewController.swift
//  MapBoxDemoApp
//
//  Created by Rahul Sharma on 23/08/19.
//  Copyright © 2019 Rahul Sharma. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Alamofire_SwiftyJSON
import CoreLocation

class AddressSearchViewController: UIViewController{
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!      //outlet to the tableview you created in storyboard
    
    
    var searchActive : Bool = false  //for controlling search states
    var searchedPlaces: NSMutableArray = []   //array to store the places returned in response
    let decoder = JSONDecoder()//for decoding data returned by API
    static var mapbox_api = "https://api.mapbox.com/geocoding/v5/mapbox.places/"
    static var mapbox_access_token = "pk.eyJ1IjoicmVyeWRlIiwiYSI6ImNqejg1cWN4ODBncWgzZW8xM3p0bGI2b3cifQ.k6_-lKDCqeeS2aDclApVTQ"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SEARCH ADDRESS"
        if self.searchBar == nil {
            self.searchBar?.searchBarStyle = UISearchBar.Style.prominent
            self.searchBar?.placeholder = "Search for place";
        }
    }
    
    
    @objc func searchPlaces(query: String) {
        let urlStr = "\(AddressSearchViewController.mapbox_api)\(query).json?access_token=\(AddressSearchViewController.mapbox_access_token)"
        
        Alamofire.request(urlStr, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseSwiftyJSON { (dataResponse) in
            
            if dataResponse.result.isSuccess {
               let resJson = JSON(dataResponse.result.value!)
                if let myjson = resJson["features"].array {
                    for itemobj in myjson {
                        try? print(itemobj.rawData())
                        do {
                            let place = try self.decoder.decode(Feature.self, from: itemobj.rawData())
                            self.searchedPlaces.add(place)
                            self.tableView.reloadData()
                        } catch let error  {
                            if let error = error as? DecodingError {
                                print(error.errorDescription!)
                            }
                        }
                    }
                }
            } else {
                
            print("Failed to featch places")
            }
            
            
            if dataResponse.result.isFailure {
                let _ : Error = dataResponse.result.error!
            }
        }
    }
    
    func cancelSearching(){
        searchActive = false
        self.searchBar!.resignFirstResponder()
        self.searchBar!.text = ""
        
    }
    
    @objc func searchMe() {
        if(searchBar?.text!.isEmpty)!{ } else {
            self.searchPlaces(query: (searchBar?.text)!)
        }
    }
    
    
    
    
}

extension AddressSearchViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "addressCell")
                cell.detailTextLabel?.textColor = UIColor.darkGray
        
                let pred = self.searchedPlaces.object(at: indexPath.row) as! Feature
                cell.textLabel?.text = pred.place_name!
                if let add = pred.properties.address {
                    cell.detailTextLabel?.text = add
                } else {    }
                cell.imageView?.backgroundColor = UIColor.gray
        
                return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedPlaces.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if searchedPlaces.count > 0 {
        return 60.0
        } else {
            return 0.0
        }
    }
}
    
    extension AddressSearchViewController : UISearchBarDelegate {
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            cancelSearching()
            searchActive = false
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            self.view.endEditing(true)
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            self.searchBar!.setShowsCancelButton(true, animated: true)
        }
        
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            self.searchBar!.setShowsCancelButton(false, animated: false)
        }
        
        
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchMe), object: nil)
            self.perform(#selector(self.searchMe), with: nil, afterDelay: 0.5)
            if(searchBar.text!.isEmpty){
                searchedPlaces = []
                tableView.reloadData()
            } else {
                
            }
        }
}
