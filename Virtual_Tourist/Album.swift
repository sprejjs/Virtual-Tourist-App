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
    @NSManaged var photos: [Photo]?

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext){
        let entity =  NSEntityDescription.entityForName("Album", inManagedObjectContext: context)!
        super.init(entity:entity, insertIntoManagedObjectContext: context)
        self.longitude = Double(coordinate.longitude)
        self.latitude = Double(coordinate.latitude)
        println(photos?.count)
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var title: String {
        return "\(id)"
    }
    
    func getPhotos(completionHandler: (photos: [Photo]) -> Void){
        if(photos != nil && photos?.count > 0) {
            //Return photos from the shared data
            completionHandler(photos: photos!)
        } else {
            //Return photos from the API
            flickrApiClient.getPhotosForCoorinate(coordinate, completionHandler:{
                (urls:[String]) in
                dispatch_async(dispatch_get_main_queue(),{
                    var photos = [Photo]()
    
                    for (var i = 0; i < urls.count; i++){
                        var photo = Photo(url: urls[i], context: self.sharedContext)
                        photo.album = self
                        photos.append(photo)
                    }
    
                    self.sharedContext.save(nil)
                    completionHandler(photos: photos)
                });
            });
        }
    }
        
    private var flickrApiClient : FlickrApiClient {
        var delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.flickrApiClient
    }
    
    private var sharedContext: NSManagedObjectContext {
        let appDeleate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDeleate.managedObjectContext!
    }
    
    func removeAllPhotos(){
        var n = photos!.count
        while (photos!.count > 0) {
            photos![0].album = nil
        }
    }
}
