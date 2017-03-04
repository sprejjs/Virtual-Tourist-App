//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Vlad Spreys on 3/05/15.
//  Copyright (c) 2015 Spreys.com. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadingOverlay: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        imageView.image = nil
        loadingOverlay.isHidden = false
        loadingOverlay.startAnimating()
    }
}
