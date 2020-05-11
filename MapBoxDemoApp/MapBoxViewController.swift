//
//  MapBoxViewController.swift
//  MapBoxDemoApp
//
//  Created by Rahul Sharma on 22/08/19.
//  Copyright © 2019 Rahul Sharma. All rights reserved.
//

import UIKit
import Mapbox
import MapboxCoreNavigation
import MapboxDirections
//import MapboxNavigation
import MapboxGeocoder
import Alamofire
import SwiftyJSON
import Alamofire_SwiftyJSON


class MapBoxViewController: UIViewController , MGLMapViewDelegate{
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var showNavigationButton: UIButton!
    
    @IBOutlet weak var reset: UIButton!
    
    
    var locationManager:CLLocationManager!
    var directionsRoute: Route?
    let rtNagar = CLLocationCoordinate2D(latitude: 49.8951, longitude: -97.1384)
    var showBackBtn = false
    let anotation = MGLPointAnnotation()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Do any additional setup after loading the view.
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        setNavigationButton()
        setlocationName()
        reset.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if showBackBtn {
            reset.isHidden = false
        } else {
            reset.isHidden = true
        }
    }

    fileprivate func setNavigationButton() {
        showNavigationButton.layer.cornerRadius = 25
        showNavigationButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        showNavigationButton.layer.shadowColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        showNavigationButton.layer.shadowRadius = 5
        showNavigationButton.layer.shadowOpacity = 0.3
        showNavigationButton.setTitle(" Search Location ", for: .normal)
    }
    
    fileprivate func setlocationName() {
        locationView.layer.cornerRadius = 15
        locationView.layer.shadowOffset = CGSize(width: 0, height: 10)
        locationView.layer.shadowColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        locationView.layer.shadowRadius = 5
        locationView.layer.shadowOpacity = 0.3
        locationView.clipsToBounds = true
        locationLabel.layer.cornerRadius = 15
        locationLabel.clipsToBounds = true
    }
    
    @IBAction func showSearch(_ sender: Any) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: String.init(describing: AddressSearchViewController.self)) as? AddressSearchViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func backBtn(_ sender: Any) {
        showBackBtn = false
        mapView.removeAnnotation(anotation)
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = nil
        }
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        mapView.setCenter( mapView.userLocation!.coordinate , zoomLevel: 15, animated: true)
    }
    
    
    @IBAction func showNavigationBtn(_ sender: Any) {
        self.reset.isHidden = false
        mapView.setUserTrackingMode(.none, animated: true, completionHandler: nil)

        //For back button in navigation bar
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton

        anotation.coordinate = rtNagar
        anotation.title = "Start navigation"
        mapView.addAnnotation(anotation)
        calculateRoute(from: mapView.userLocation!.coordinate, to: rtNagar) { (route, error) in
            if error != nil {
                print("error getitng the route")
            }
        }
        
    }
    
    fileprivate func calculateRoute(from origenCoor: CLLocationCoordinate2D, to destinationCoor : CLLocationCoordinate2D, completion: @escaping(Route?, Error) -> Void) {
        
        let origin = Waypoint(coordinate: origenCoor, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destinationCoor, coordinateAccuracy: -1, name: "Finish")
        let options = NavigationRouteOptions(waypoints: [origin,destination], profileIdentifier: .automobileAvoidingTraffic)
        _ = Directions.shared.calculate(options, completionHandler: { (waypoints, routes, error) in
            self.directionsRoute = routes?.first
            
            //draw line
            if let direcRoute = self.directionsRoute?.coordinateCount, direcRoute > 0 {
                self.drawRoute(route: self.directionsRoute!)
                let cordinateBounds = MGLCoordinateBounds(sw: destinationCoor, ne: origenCoor)
                let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
                let routeCam = self.mapView.cameraThatFitsCoordinateBounds(cordinateBounds, edgePadding: insets)
                self.mapView.setCamera(routeCam, animated: true)
                self.reverseGeoCoding(location: CLLocationCoordinate2D(latitude: self.mapView.latitude, longitude: self.mapView.longitude))


            }
            
        })
    }
    
    fileprivate func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else { return }
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = NSExpression(forConstantValue: UIColor.red)
            lineStyle.lineWidth = NSExpression(forConstantValue: 4.0)
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
//        let navigationViewController = NavigationViewController(for: directionsRoute!)
//        present(navigationViewController, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MGLMapView, shouldChangeFrom oldCamera: MGLMapCamera, to newCamera: MGLMapCamera) -> Bool {
        print("\(mapView.latitude) \(mapView.longitude)")
        locationLabel.text =  getAddress(location: CLLocationCoordinate2D(latitude: mapView.latitude, longitude: mapView.longitude))
        return true
    }
    
    fileprivate func getAddress(location: CLLocationCoordinate2D) -> String {
        
        reverseGeoCoding(location: CLLocationCoordinate2D(latitude: mapView.latitude, longitude: mapView.longitude))
        
        return "Loading..."
    }
    
     func reverseGeoCoding(location: CLLocationCoordinate2D)  {
        let mapbox_access_token = "pk.eyJ1IjoicmVyeWRlIiwiYSI6ImNqejg1cWN4ODBncWgzZW8xM3p0bGI2b3cifQ.k6_-lKDCqeeS2aDclApVTQ"
        let urlStr = "https://api.mapbox.com/geocoding/v5/mapbox.places/\(location.longitude),\(location.latitude).json?access_token=\(mapbox_access_token)"

        Alamofire.request(urlStr, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseSwiftyJSON { (dataResponse) in
            let decoder = JSONDecoder()//for decoding data returned by API
            if dataResponse.result.isSuccess {
                let resJson = JSON(dataResponse.result.value!)
                if let myjson = resJson["features"].array {
                    print(myjson)
                    for itemobj in myjson {
                        if (itemobj.first != nil) {
                        try? print(itemobj.rawData())
                        do {
                            let place = try decoder.decode(PlaceName.self, from: itemobj.rawData())
                            self.locationLabel.text = place.place_name
                            break
                        } catch let error  {
                            if let error = error as? DecodingError {
                                print(error.errorDescription!)
                            }
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
}



