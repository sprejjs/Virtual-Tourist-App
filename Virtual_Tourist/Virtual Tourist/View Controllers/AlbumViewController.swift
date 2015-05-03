//
// Created by Vlad Spreys on 6/04/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class AlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var loadingOverlay: UIView!
    var btnNewCollection: UIButton?
    
    var annotation: MKAnnotation?
    var photoUrls: [String]?
    var photosCache: [UIImage?]?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.addAnnotation(self.annotation!)
        mapView.showAnnotations([self.annotation!], animated: true)
        
        navigationController?.navigationBarHidden = false
        
        retrieveNewCollection()
    }
    
    private func retrieveNewCollection() {
        photoUrls = nil
        photosCache = nil
        loadingOverlay.hidden = false
        
        flickrApiClient.getPhotosForCoorinate(annotation!.coordinate, completionHandler:{
            (urls:[String]) in
            
            //Hide loading overlay with animation
            UIView.transitionWithView(self.loadingOverlay, duration: NSTimeInterval(0.4), options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {}, completion: {(finished: Bool) -> () in })
            self.loadingOverlay.hidden = true
            
            //Update model
            self.photoUrls = urls
            self.photosCache = [UIImage?](count:urls.count, repeatedValue: nil)
            
            //Reload collection view
            self.collectionView.reloadData()
        })
    }
    
    private var flickrApiClient : FlickrApiClient {
        var delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.flickrApiClient
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if photoUrls == nil {
            return 0
        } else {
            return photoUrls!.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var newCollection = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footer", forIndexPath: indexPath) as! UICollectionReusableView
        
        self.btnNewCollection = newCollection.subviews[0] as? UIButton
        
        return newCollection
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //Deque cell
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCell
        
        //Check the cache
        if let imageFromCache = photosCache![indexPath.item] {
            cell.imageView.image = imageFromCache
            cell.loadingOverlay.hidden = true
        } else {
            //Asyncrhoniously load image from URL:
            var imageUrl = NSURL(string: photoUrls![indexPath.item])
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                var image = UIImage(data: NSData(contentsOfURL: imageUrl!)!)
                
                //update cache
                self.photosCache![indexPath.item] = image
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    //Check if this is still the right cell and not a re-used one
                    if let updateCell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoCell {
                        //Display loaded image
                        updateCell.imageView.image = image
                        
                        //Hide loading overla with animation
                        UIView.transitionWithView(cell.loadingOverlay, duration: NSTimeInterval(0.4), options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {}, completion: {(finished: Bool) -> () in })
                        updateCell.loadingOverlay.hidden = true
                        
                        //Enable "New Collection" button if all of the images have been loaded
                        self.btnNewCollection!.enabled = self.allImagesLoaded
                    }
                })
            })
        }
        
        return cell
    }
    
    private var allImagesLoaded: Bool {
        var loaded = true
        for (var i = 0; i < photosCache!.count; i++){
            if photosCache![i] == nil {
                loaded = false
            }
        }
        
        return loaded
    }
    
    @IBAction func newCollection() {
        retrieveNewCollection()
    }
}
