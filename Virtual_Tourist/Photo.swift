//
// Created by Vlad Spreys on 23/05/15.
// Copyright (c) 2015 Spreys.com. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
class Photo: NSManagedObject {
    @NSManaged var url: String
    @NSManaged var album: Album?
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(url: String, context: NSManagedObjectContext){
        let entity =  NSEntityDescription.entity(forEntityName: "Photo", in: context)!
        super.init(entity:entity, insertInto: context)
        self.url = url
    }
}
