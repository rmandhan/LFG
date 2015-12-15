//
//  Post+CoreDataProperties.swift
//  
//
//  Created by Rakesh Mandhan on 2015-12-03.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Post {

    @NSManaged var objectId: String
    @NSManaged var gameId: String
    @NSManaged var character: String
    @NSManaged var platform: String
    @NSManaged var desc: String
    @NSManaged var gameType: String
    @NSManaged var mic: Bool
    @NSManaged var playerId: String
    @NSManaged var primaryLevel: NSNumber
    @NSManaged var secondaryLevel: NSNumber
    @NSManaged var updatedAt: NSDate
    @NSManaged var game: Game

}
