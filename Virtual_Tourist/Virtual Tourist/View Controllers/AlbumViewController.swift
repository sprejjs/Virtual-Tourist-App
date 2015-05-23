//
// Created by Vlad Spreys on 6/04/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var loadingOverlay: UIView!
    var btnNewCollection: UIButton?
    var lblNoImages: UILabel?
    
    var album: Album!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.addAnnotation(album)
        mapView.showAnnotations([album], animated: true)
        
        navigationController?.navigationBarHidden = false
        
        retrieveNewCollection()
    }
    
    private func retrieveNewCollection() {
        loadingOverlay.hidden = false
        
        album.getPhotos({
            (photos:[Photo]) in
            
            //Hide loading overlay with animation
            UIView.transitionWithView(self.loadingOverlay, duration: NSTimeInterval(0.4), options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {}, completion: {(finished: Bool) -> () in })
            self.loadingOverlay.hidden = true
            
            //Reload collection view
            self.collectionView.reloadData()
        });
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if album.photos == nil {
            return 0
        } else {
            return album.photos!.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var newCollection = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footer", forIndexPath: indexPath) as! UICollectionReusableView
        
        self.btnNewCollection = newCollection.subviews[0] as? UIButton
        self.lblNoImages = newCollection.subviews[1] as? UILabel
        
        //Hide display elements
        if album.photos != nil && album.photos!.count > 0 {
            lblNoImages?.hidden = true
            btnNewCollection?.hidden = false
        } else {
            lblNoImages?.hidden = false
            btnNewCollection?.hidden = true
        }
        
        return newCollection
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //Deque cell
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCell
        
        //Check the cache
        if let imageFromCache = album.photos![indexPath.item].image {
            let image = UIImage(data: imageFromCache)
            cell.imageView.image = image
            cell.loadingOverlay.stopAnimating()
            cell.loadingOverlay.hidden = true
        } else {
            //Asyncrhoniously load image from URL:
            var imageUrl = NSURL(string: album.photos![indexPath.item].url)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                var image = UIImage(data: NSData(contentsOfURL: imageUrl!)!)
                
                //update cache
                self.album.photos![indexPath.item].image = UIImagePNGRepresentation(image);
                self.sharedContext.save(nil)
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    //Check if this is still the right cell and not a re-used one
                    if let updateCell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoCell {
                        //Display loaded image
                        updateCell.imageView.image = image
                        
                        //Hide loading overla with animation
                        UIView.transitionWithView(cell.loadingOverlay, duration: NSTimeInterval(0.4), options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {}, completion: {(finished: Bool) -> () in })
                        updateCell.loadingOverlay.hidden = true
                        
                        //Enable "New Collection" button if all of the images have been loaded
                        if self.btnNewCollection != nil {
                            self.btnNewCollection!.enabled = self.allImagesLoaded
                        }
                    }
                })
            })
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        album.photos![indexPath.item].album = nil
        collectionView.reloadData()
        sharedContext.save(nil)
    }
    
    private var allImagesLoaded: Bool {
        var loaded = true
        for (var i = 0; i < album.photos!.count; i++){
            if album.photos![i].image == nil {
                loaded = false
            }
        }
        
        return loaded
    }
    
    @IBAction func newCollection() {
        retrieveNewCollection()
    }
    
    private var sharedContext: NSManagedObjectContext {
        let appDeleate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDeleate.managedObjectContext!
    }
}
