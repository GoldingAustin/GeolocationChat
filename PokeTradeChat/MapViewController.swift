//
//  MapViewController.swift
//  PokeTradeChat
//
//  Created by Austin Golding on 8/30/16.
//

import Foundation
import UIKit
import GoogleMaps


class MapViewController: UIViewController, GMSMapViewDelegate {
    
    var mapView = GMSMapView()
    var markerLoc = CLLocationCoordinate2D()
    
    override func viewDidAppear(_ animated: Bool) {
        if (AppState.sharedInstance.markerSet == true) {
            let marker = GMSMarker()
            marker.position = AppState.sharedInstance.loc
            marker.title = (AppState.sharedInstance.cp + ": " + AppState.sharedInstance.mess)
            marker.icon = UIImage(named: AppState.sharedInstance.number)
            marker.snippet = AppState.sharedInstance.number
            marker.appearAnimation = kGMSMarkerAnimationPop
            marker.map = mapView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.camera(withLatitude: Constants.users.lat, longitude: Constants.users.lng, zoom: 13)
        mapView.camera = camera
        //mapView = GMSMapView.mapWithFrame(self.view.bounds, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        print("map")

        //setMarker()
        self.view = mapView
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        markerLoc.latitude = coordinate.latitude
        markerLoc.longitude = coordinate.longitude
        AppState.sharedInstance.loc = coordinate
        performSegue(withIdentifier: Constants.Segues.PokeLists, sender: nil)
        print("You tapped at \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    func setMarker() {

        self.view = mapView
        print("marker")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
