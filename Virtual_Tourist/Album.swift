//
// Created by Vlad Spreys on 23/05/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//
import Foundation
import CoreData
import MapKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


@objc(Album)
class Album: NSManagedObject, MKAnnotation {
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]?

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext){
        let entity =  NSEntityDescription.entity(forEntityName: "Album", in: context)!
        super.init(entity:entity, insertInto: context)
        self.longitude = Double(coordinate.longitude)
        self.latitude = Double(coordinate.latitude)
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var title: String? {
        return "\(objectID)"
    }
    
    func getPhotos(_ completionHandler: @escaping (_ photos: [Photo]) -> Void){
        if(photos != nil && photos?.count > 0) {
            //Return photos from the shared data
            completionHandler(photos!)
        } else {
            //Return photos from the API
            flickrApiClient.getPhotosForCoorinate(coordinate, completionHandler:{
                (urls:[String]) in
                DispatchQueue.main.async(execute: {
                    var photos = [Photo]()
                    
                    for url in urls {
                        let photo = Photo(url: url, context: self.sharedContext)
                        photo.album = self
                        photos.append(photo)
                    }
    
    
                    try! self.sharedContext.save()
                    completionHandler(photos)
                });
            });
        }
    }
        
    fileprivate var flickrApiClient : FlickrApiClient {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.flickrApiClient
    }
    
    fileprivate var sharedContext: NSManagedObjectContext {
        let appDeleate = UIApplication.shared.delegate as! AppDelegate
        return appDeleate.managedObjectContext!
    }
    
    func removeAllPhotos(){
        while (photos!.count > 0) {
            photos![0].album = nil
        }
    }
}
