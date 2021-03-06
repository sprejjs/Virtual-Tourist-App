//
// Created by Vlad Spreys on 27/04/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//

import Foundation
import CoreLocation

class FlickrApiClient {
    fileprivate let geoAccuracyVariable = 0.001//Used to convert Lat/Long to a bounding box for flickr search
    
    fileprivate let flickrApiBaseUrl = "https://api.flickr.com/services/rest?"

    //Facade design pattern
    func getPhotosForCoorinate(_ coordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ urls: [String]) -> Void){

        //1. Convert CLLLocationCoordinate to a Bounding box which Flickr can understand
        let bboxForCoordinate = convertLatLongToBbox(coordinate.latitude, long: coordinate.longitude)
        
        //2. Create a Dictionary containing all of the required parameters for API call
        let requestDictionary = createRequestDictionaryWithBbox(bboxForCoordinate)
        
        //3. Make the service call
        let request = NSMutableURLRequest(url: URL(string: self.flickrApiBaseUrl + convertDicToGetString(requestDictionary))!)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            
            let jsonDict = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary

            //4. convert retrieved jSON to an array of Strings containing photo urls
            let photosDict = jsonDict["photos"] as! NSDictionary
            let photosArray = photosDict["photo"] as! NSArray
            var results = [String]()
            
            for photo in photosArray {
                results.append(self.convertPhotoObjectToUrl(photo as! NSDictionary))
            }
            
            //5. Call the completion handler with results
            completionHandler(results)
        }
        task.resume()
    }
    
    fileprivate func createRequestDictionaryWithBbox(_ bbox: String) -> [String:String]{
        var dictionary = [String:String]()
        dictionary["api_key"] = "686a4ed4204f0b7fb93b00063d2f1a1c"
        dictionary["method"] = "flickr.photos.search"
        dictionary["nojsoncallback"] = "1"
        dictionary["format"] = "json"
        dictionary["bbox"] = bbox
        
        return dictionary
    }
    
    fileprivate func convertPhotoObjectToUrl(_ object: NSDictionary) -> String{
        //URL format = https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
        let farmId = object["farm"] as! Int
        let serverId = object["server"] as! NSString
        let photoId = object["id"] as! NSString
        let secret = object["secret"] as! NSString
        
        
        return "https://farm\(farmId).staticflickr.com/\(serverId)/\(photoId)_\(secret).jpg"
    }

    fileprivate func convertLatLongToBbox(_ lat: Double, long: Double) -> String {
        let minLat = "\(lat - geoAccuracyVariable)"
        let maxLat = "\(lat + geoAccuracyVariable)"
        let minLong = "\(long - geoAccuracyVariable)"
        let maxLong = "\(long + geoAccuracyVariable)"
    
        return minLong + "," + minLat + "," + maxLong + "," + maxLat
    }
    
    private func convertDicToGetString(_ dic: [String: String]) -> String {
        let dic = dic
        var string = ""
        for (myKey,myValue) in dic {
            string += myKey + "=" + myValue + "&"
        }
        return string
    }
}
