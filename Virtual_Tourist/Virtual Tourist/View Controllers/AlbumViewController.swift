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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.addAnnotation(album)
        mapView.showAnnotations([album], animated: true)
        
        navigationController?.isNavigationBarHidden = false
        
        retrieveNewCollection()
    }
    
    fileprivate func retrieveNewCollection() {
        loadingOverlay.isHidden = false
        
        album.getPhotos({
            (photos:[Photo]) in
            
            //Hide loading overlay with animation
            UIView.transition(with: self.loadingOverlay, duration: TimeInterval(0.4), options: UIViewAnimationOptions.transitionCrossDissolve, animations: {}, completion: {(finished: Bool) -> () in })
            self.loadingOverlay.isHidden = true
            
            //Reload collection view
            self.collectionView.reloadData()
        });
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if album.photos == nil {
            return 0
        } else {
            return album.photos!.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let newCollection = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath) 
        
        self.btnNewCollection = newCollection.subviews[0] as? UIButton
        self.lblNoImages = newCollection.subviews[1] as? UILabel
        
        //Hide display elements
        if album.photos != nil && album.photos!.count > 0 {
            lblNoImages?.isHidden = true
            btnNewCollection?.isHidden = false
        } else {
            lblNoImages?.isHidden = false
            btnNewCollection?.isHidden = true
        }
        
        return newCollection
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //Deque cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        
        //Check the cache
        let imageId = self.album.photos![indexPath.item].objectID.uriRepresentation().lastPathComponent
        if let imageFromCache = AppDelegate.Cache.imageCache.imageWithIdentifier(imageId) {
            cell.imageView.image = imageFromCache
            cell.loadingOverlay.stopAnimating()
            cell.loadingOverlay.isHidden = true
        } else {
            //Asyncrhoniously load image from URL:
            let imageUrl = URL(string: album.photos![indexPath.item].url)
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {
                let image = UIImage(data: try! Data(contentsOf: imageUrl!))
                
                //update cache                
                let id = self.album.photos![indexPath.item].objectID.uriRepresentation().lastPathComponent
                AppDelegate.Cache.imageCache.storeImage(image, withIdentifier: id)
                
                DispatchQueue.main.async(execute: {
                    
                    //Check if this is still the right cell and not a re-used one
                    if let updateCell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
                        //Display loaded image
                        updateCell.imageView.image = image
                        
                        //Hide loading overla with animation
                        UIView.transition(with: cell.loadingOverlay, duration: TimeInterval(0.4), options: UIViewAnimationOptions.transitionCrossDissolve, animations: {}, completion: {(finished: Bool) -> () in })
                        updateCell.loadingOverlay.isHidden = true
                        
                        //Enable "New Collection" button if all of the images have been loaded
                        if self.btnNewCollection != nil {
                            self.btnNewCollection!.isEnabled = self.allImagesLoaded
                        }
                    }
                })
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Delete the image from cache
        let id = self.album.photos![indexPath.item].objectID.uriRepresentation().lastPathComponent
        AppDelegate.Cache.imageCache.storeImage(nil, withIdentifier: id)
        
        //Remove core data object
        album.photos![indexPath.item].album = nil
        collectionView.reloadData()
        try! sharedContext.save()
    }
    
    fileprivate var allImagesLoaded: Bool {
        var loaded = true
        
        for photo in album.photos! {
            let imageId = photo.objectID.uriRepresentation().lastPathComponent
            
            if AppDelegate.Cache.imageCache.imageWithIdentifier(imageId) == nil {
                loaded = false
            }
        }
        
        return loaded
    }
    
    @IBAction func newCollection() {
        album.removeAllPhotos()
        retrieveNewCollection()
    }
    
    fileprivate var sharedContext: NSManagedObjectContext {
        let appDeleate = UIApplication.shared.delegate as! AppDelegate
        return appDeleate.managedObjectContext!
    }
}
