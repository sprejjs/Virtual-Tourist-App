//
// Created by Vlad Spreys on 23/05/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//
import Foundation
import CoreData
import MapKit

@objc(Album)
class Album: NSManagedObject, MKAnnotation {
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var id: Int

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext){
        let entity =  NSEntityDescription.entityForName("Album", inManagedObjectContext: context)!
        super.init(entity:entity, insertIntoManagedObjectContext: context)
        self.longitude = Double(coordinate.longitude)
        self.latitude = Double(coordinate.latitude)
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var title: String {
        return "\(id)"
    }
    
    func getPhotos(completionHandler: (urls: [String]) -> Void){
        flickrApiClient.getPhotosForCoorinate(coordinate, completionHandler:{
            (urls:[String]) in
            dispatch_async(dispatch_get_main_queue(),{
                completionHandler(urls: urls)
            });
        });
    }
        
        
    private var flickrApiClient : FlickrApiClient {
        var delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.flickrApiClient
    }
}
