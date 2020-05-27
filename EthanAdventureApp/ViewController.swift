//
//  ViewController.swift
//  EthanAdventureApp
//
//  Created by Toby Kreiman on 5/23/20.
//  Copyright © 2020 Toby Kreiman. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    var mapView = MKMapView()
    var slider = UISlider()
    var randomButton = UIButton()
    
    var locationManager = CLLocationManager()
    
    
    var circle = MKCircle()
    var centerAnnotation: MKPointAnnotation?
    var randomAnnotation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        
        if let map = self.view.viewWithTag(1) as? MKMapView {
            self.mapView = map
            self.mapView.showsUserLocation = true
            self.mapView.delegate = self
        }
        
        if let s = self.view.viewWithTag(2) as? UISlider {
            self.slider = s
            self.slider.addTarget(self, action: #selector(ViewController.sliderChanged), for: .valueChanged)
        }
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.addAnnotation(sender:)))
        self.mapView.addGestureRecognizer(doubleTap)
        
        if let b = self.view.viewWithTag(3) as? UIButton {
            self.randomButton = b
            self.randomButton.addTarget(self, action: #selector(ViewController.createRandomPoint), for: .touchUpInside)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let loc = self.mapView.userLocation.location {
            self.mapView.centerToLocation(loc)
            self.circle = self.mapView.createCircle(center: loc.coordinate, radius: 100)
        }
    }
    
    @objc func addAnnotation(sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.mapView)
        let coordinate = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        
        if let center = self.centerAnnotation {
            center.coordinate = coordinate
        } else {
            self.centerAnnotation = MKPointAnnotation()
            self.centerAnnotation?.coordinate = coordinate
            self.mapView.addAnnotation(self.centerAnnotation!)
        }
        
        self.mapView.removeOverlay(circle)
        self.circle = self.mapView.createCircle(center: self.centerAnnotation!.coordinate, radius: self.circle.radius)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var circleView = MKCircleRenderer(overlay: overlay)
        circleView.strokeColor = .red
        return circleView
    }
    
    @objc func sliderChanged() {
        self.mapView.removeOverlay(circle)
        //self.circle = self.mapView.createCircle(radius: 1000 * Double(self.slider.value))
        self.circle = self.mapView.createCircle(center: self.centerAnnotation!.coordinate, radius: 1000 * Double(self.slider.value))
    }
    
    @objc func createRandomPoint() {
        
        if let centerAnno = self.centerAnnotation {
            
            let randDegree = Double.random(in: 0...360)
            let randRadius = Double.random(in: 0...self.circle.radius)
            
            let dx = randRadius * cos(randDegree * Double.pi / 180)
            let dy = randRadius * sin(randDegree * Double.pi / 180)
            
            let dLatitude = dy / 111111
            let finalLatitude = centerAnno.coordinate.latitude + dLatitude
            
            let dLongitude = dx / 111111 / cos(finalLatitude * Double.pi / 180)
            let finalLongitude = centerAnno.coordinate.longitude + dLongitude
            
            let finalLocation = CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
            if let rand = self.randomAnnotation {
                self.randomAnnotation?.coordinate = finalLocation
            } else {
                self.randomAnnotation = MKPointAnnotation()
                self.randomAnnotation?.coordinate = finalLocation
                self.mapView.addAnnotation(self.randomAnnotation!)
            }
            
            let coder = CLGeocoder()
            let location3D = CLLocation(latitude: finalLocation.latitude, longitude: finalLocation.longitude)
            
            coder.reverseGeocodeLocation(location3D) { (placemarks, error) in
                if let e = error {
                    print(e)
                } else {
                    if let marks = placemarks {
                        for p in marks {
                            print("----")
                            print(p.inlandWater)
                            print(p.ocean)
                        }
                    }
                }
            }
        }
    }
}

private extension MKMapView {
  func centerToLocation(
    _ location: CLLocation,
    regionRadius: CLLocationDistance = 1000
  ) {
    let coordinateRegion = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: regionRadius,
      longitudinalMeters: regionRadius)
    self.setRegion(coordinateRegion, animated: true)
  }
    
    func createCircle(center: CLLocationCoordinate2D, radius: Double) -> MKCircle {
        let c = MKCircle(center: center, radius: radius)
        self.addOverlay(c)
        return c
    }
    
    func createCircle(radius: Double) -> MKCircle {
        if let center = self.userLocation.location?.coordinate {
            let c = MKCircle(center: center, radius: radius)
            self.addOverlay(c)
            return c
        } else {
            return MKCircle()
        }
    }
}

