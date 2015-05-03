//
// Created by Vlad Spreys on 6/04/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MapViewController : UIViewController, MKMapViewDelegate {
    //Key used for data persistance
    private let KEY_MAP_VIEW_COORDINATE_LAT = "key_map_view_coordinate_lat"
    private let KEY_MAP_VIEW_COORDINATE_LON = "key_map_view_coordinate_lon"
    private let KEY_MAP_VIEW_ZOOM_LEVEL = "key_map_view_zoom_level"
    private let KEY_MAP_VIEW_ROTATION_ANGLE = "key_map_view_rotation_angle"
    
    @IBOutlet var mapView : MapViewWithZoom!
    var selectedAnnotation : MKAnnotation?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBarHidden = true
        initialiseLongPressRecogniser()
        
        //Restore previous MapView position
        restoreMapViewPosition()
    }
    
    private func restoreMapViewPosition(){

        //Getting data from NSUserDefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        
        //Check if there is anything set in the NSUserDefaults
        if let lat = defaults.objectForKey(KEY_MAP_VIEW_COORDINATE_LAT) as? CLLocationDegrees{
            let lat = defaults.objectForKey(KEY_MAP_VIEW_COORDINATE_LAT) as! CLLocationDegrees
            let lon = defaults.objectForKey(KEY_MAP_VIEW_COORDINATE_LON) as! CLLocationDegrees
            let zoomLevel = defaults.objectForKey(KEY_MAP_VIEW_ZOOM_LEVEL) as! Int
            let rotationAngle = defaults.objectForKey(KEY_MAP_VIEW_ROTATION_ANGLE) as! CLLocationDegrees
            
            //Setting it back to the map view
            mapView.setCenterCoordinate(CLLocationCoordinate2DMake(lat, lon), animated: false)
            mapView.zoomLevel = zoomLevel
            mapView.camera.heading = rotationAngle
        }
    }
    
    func initialiseLongPressRecogniser(){
        var longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")

        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.title = "Test"
        annotation.coordinate = touchMapCoordinate

        mapView.addAnnotation(annotation)
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.canShowCallout = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        selectedAnnotation = view.annotation
        performSegueWithIdentifier("toAlbum", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "toAlbum") {
            let destinationController = segue.destinationViewController as? AlbumViewController
            destinationController!.annotation = selectedAnnotation
        }
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        //Persist the current MapView position
        
        //1 - center of the map
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(mapView.centerCoordinate.latitude, forKey: KEY_MAP_VIEW_COORDINATE_LAT)
        defaults.setObject(mapView.centerCoordinate.longitude, forKey: KEY_MAP_VIEW_COORDINATE_LON)
        
        //2 - zoom level
        if let mapViewWithZoom = mapView as? MapViewWithZoom {
            defaults.setObject(mapViewWithZoom.zoomLevel, forKey: KEY_MAP_VIEW_ZOOM_LEVEL)
        }
        
        //3 - camera rotation angle
        defaults.setObject(mapView.camera.heading, forKey: KEY_MAP_VIEW_ROTATION_ANGLE)
        
    }
}
