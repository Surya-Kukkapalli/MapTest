//
//  ViewController.swift
//  MapTest
//
//  Created by Kukkapalli, Surya on 6/24/19.
//  Copyright © 2019 Kukkapalli, Surya. All rights reserved.
//


import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}

class MapViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    
    var resultsSearchController: UISearchController!
    var selectedPin: MKPlacemark?
    
    let mapView: MKMapView = {
        let view = MKMapView()
        view.isScrollEnabled = true
        view.isZoomEnabled = true
        view.mapType = MKMapType.standard
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsUserLocation = true
        view.userLocation.title = "Your location"
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate methods used to handle responses asychronously to account for different request response times
        locationManager.delegate = self
        // Overriding the default level of map accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Triggers location permission dialog
        locationManager.requestWhenInUseAuthorization()
        // API call to trigger the one-time location request
        locationManager.requestLocation()
        
        view.addSubview(mapView)
        setupMapView()
        
        // Create instance of the location table view controller when search bar is selected
        let locationSearchTable = LocationSearchTableViewController()
        resultsSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultsSearchController.searchResultsUpdater = locationSearchTable
        
        // Setting up the search bar
        let searchBar = resultsSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for place"
        navigationItem.titleView = resultsSearchController?.searchBar
        resultsSearchController.hidesNavigationBarDuringPresentation = false
        resultsSearchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        
        // MapVC (parent) passing a handle of itself to child controller (locationsearchtableVC)
        locationSearchTable.handleMapSearchDelegate = self
        mapView.delegate = self
        
    }
    
    func setupMapView() {
        mapView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mapView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        mapView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        mapView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
    
    // Using API that launches apple maps with driving directions
    @objc func getDirections() {
        guard let selectedPin = selectedPin else { return }
        let mapItem = MKMapItem(placemark: selectedPin)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
        
    }
    
}

// More organized way of grouping delegate methods
extension MapViewController: CLLocationManagerDelegate {
    
    // Called when user responds to permission dialog
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    // Called when location info comes back (as an array, but only interested in the first item).
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error)")
    }
}

// Extension to handle protocol defined above
extension MapViewController: HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark) {
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
                annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
    }
}

extension MapViewController: MKMapViewDelegate {
    // MKMapView Delegate method that customizes appearance of map pins/callouts
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
//        guard !(annotation is MKUserLocation) else { return nil }
//        let reuseId = "pin"
//        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
//        if pinView == nil {
//            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
//        }
//        pinView?.pinTintColor = UIColor.orange
//        pinView?.canShowCallout = true
//        let smallSquare = CGSize(width: 30, height: 30)
//        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
//        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
//        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
//        // setting a uibutton to instantiate programmamtically
//        pinView?.leftCalloutAccessoryView = button
//        return pinView
        
        // Making button
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        
        
        guard !(annotation is MKUserLocation) else { return nil }
        let reuseId = "pin"
        let view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.leftCalloutAccessoryView = button
        }
    return view
    }
}

