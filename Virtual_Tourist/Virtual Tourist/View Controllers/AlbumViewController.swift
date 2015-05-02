//
// Created by Vlad Spreys on 6/04/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class AlbumViewController : UIViewController {
    @IBOutlet var mapView : MKMapView!
    
    var annotation : MKAnnotation?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.addAnnotation(self.annotation!)
        mapView.showAnnotations([self.annotation!], animated: true)
        
        navigationController?.navigationBarHidden = false
        
        flickrApiClient.getPhotosForCoorinate(annotation!.coordinate, completionHandler:{
            (urls:[String]) in
        })
    }
    
    private var flickrApiClient : FlickrApiClient {
        var delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.flickrApiClient
    }
}
