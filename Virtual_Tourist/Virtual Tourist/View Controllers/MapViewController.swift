//
// Created by Vlad Spreys on 6/04/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController : UIViewController, MKMapViewDelegate {
    //Key used for data persistance
    fileprivate let KEY_MAP_VIEW_COORDINATE_LAT = "key_map_view_coordinate_lat"
    fileprivate let KEY_MAP_VIEW_COORDINATE_LON = "key_map_view_coordinate_lon"
    fileprivate let KEY_MAP_VIEW_ZOOM_LEVEL = "key_map_view_zoom_level"
    fileprivate let KEY_MAP_VIEW_ROTATION_ANGLE = "key_map_view_rotation_angle"
    
    @IBOutlet var mapView : MapViewWithZoom!
    var selectedAlbum : Album?
    var albums: [Album]?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        initialiseLongPressRecogniser()
        
        //Restore previous MapView position
        restoreMapViewPosition()
        
        //Fetch albums
        restoreAlbumAnnotations()
    }
    
    fileprivate func restoreMapViewPosition(){

        //Getting data from NSUserDefaults
        let defaults = UserDefaults.standard
        
        //Check if there is anything set in the NSUserDefaults
        if (defaults.object(forKey: KEY_MAP_VIEW_COORDINATE_LAT) as? CLLocationDegrees) != nil{
            let lat = defaults.object(forKey: KEY_MAP_VIEW_COORDINATE_LAT) as! CLLocationDegrees
            let lon = defaults.object(forKey: KEY_MAP_VIEW_COORDINATE_LON) as! CLLocationDegrees
            let zoomLevel = defaults.object(forKey: KEY_MAP_VIEW_ZOOM_LEVEL) as! Int
            let rotationAngle = defaults.object(forKey: KEY_MAP_VIEW_ROTATION_ANGLE) as! CLLocationDegrees
            
            //Setting it back to the map view
            mapView.setCenter(CLLocationCoordinate2DMake(lat, lon), animated: false)
            mapView.zoomLevel = zoomLevel
            mapView.camera.heading = rotationAngle
        }
    }
    
    fileprivate func restoreAlbumAnnotations(){
        //Clear old annotations
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        //Fetch new annotations from the core data
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
        try! albums = sharedContext.fetch(fetchRequest) as? [Album]
        
        
        self.mapView.addAnnotations(albums!)
    }
    
    func initialiseLongPressRecogniser(){
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))

        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    func handleLongPress(_ getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .began { return }
        
        let touchPoint = getstureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let album = Album(coordinate: touchMapCoordinate, context: sharedContext)

        mapView.addAnnotation(album)
        albums!.append(album)
        try! sharedContext.save()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        selectedAlbum = view.annotation as? Album
        performSegue(withIdentifier: "toAlbum", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toAlbum") {
            let destinationController = segue.destination as? AlbumViewController
            destinationController!.album = selectedAlbum
            deselectAllAnnotations()
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //Persist the current MapView position
        
        //1 - center of the map
        let defaults = UserDefaults.standard
        defaults.set(mapView.centerCoordinate.latitude, forKey: KEY_MAP_VIEW_COORDINATE_LAT)
        defaults.set(mapView.centerCoordinate.longitude, forKey: KEY_MAP_VIEW_COORDINATE_LON)
        
        //2 - zoom level
        if let mapViewWithZoom = mapView as? MapViewWithZoom {
            defaults.set(mapViewWithZoom.zoomLevel, forKey: KEY_MAP_VIEW_ZOOM_LEVEL)
        }
        
        //3 - camera rotation angle
        defaults.set(mapView.camera.heading, forKey: KEY_MAP_VIEW_ROTATION_ANGLE)
    }
    
    func deselectAllAnnotations(){
        
        let selectedAnnotations = mapView.selectedAnnotations
        
        for annotation in selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }    
    
    var sharedContext: NSManagedObjectContext {
        let appDeleate = UIApplication.shared.delegate as! AppDelegate
        return appDeleate.managedObjectContext!
    }
}
