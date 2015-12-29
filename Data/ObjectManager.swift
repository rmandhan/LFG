//
//  ObjectManager.swift
//  LFG
//
//  Created by Rakesh Mandhan on 2015-12-03.
//  Copyright © 2015 Rakesh. All rights reserved.
//

import Foundation
import CoreData
import Parse

class ObjectManager {
    
    static let sharedInstance = ObjectManager()
    
    var appDelegate: AppDelegate
    var masterContext: NSManagedObjectContext
    var mainContext: NSManagedObjectContext
    
    private init() {
        
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        masterContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        
        masterContext.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        mainContext.parentContext = masterContext
    }
    
    // Retrieves the Game objects from Core Data
    func retrieveGames() -> [Game] {
        
        var games = [Game]()
        
        let fetchRequest = NSFetchRequest(entityName: "Game")
        let sortDescriptor = NSSortDescriptor(key: "fullName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try self.mainContext.executeFetchRequest(fetchRequest)
            
            for result in results {
                if let game = result as? Game {
                    games.append(game)
                } else {
                    print("One of results could not be casted as a Game")
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        return games
    }
    
    func retrieveGame(withId id: String) -> Game? {
        
        var game: Game!
        
        let fetchRequest = NSFetchRequest(entityName: "Game")
        fetchRequest.predicate = NSPredicate(format: "objectId == %@", id)
        
        do {
            let results = try self.mainContext.executeFetchRequest(fetchRequest)
            
            if results.count > 0 {
                if let gameFound = results[0] as? Game {
                    game = gameFound
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        return game
    }
    
    // Retrieves the Post objects from Core Data sorted by date (most recent first)
    func retrievePosts(withGameId gameId: String) -> [Post] {
        
        var posts = [Post]()
        
        let fetchRequest = NSFetchRequest(entityName: "Post")
        fetchRequest.predicate = NSPredicate(format: "gameId == %@", gameId)
        
        do {
            let results = try self.mainContext.executeFetchRequest(fetchRequest)
            
            for result in results {
                if let post = result as? Post {
                    posts.append(post)
                } else {
                    print("One of results could not be casted as a Post")
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        return posts
        
    }
    
    // Retrieves the Post objects from Core Data
    func retrievePosts(withPredicate predicate: NSPredicate?) -> [Post] {
        
        var posts = [Post]()
        
        let fetchRequest = NSFetchRequest(entityName: "Post")
        fetchRequest.predicate = predicate
        
        do {
            let results = try self.mainContext.executeFetchRequest(fetchRequest)
            
            for result in results {
                if let post = result as? Post {
                    posts.append(post)
                } else {
                    print("One of results could not be casted as a Post")
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        return posts
        
    }
    
    // Deletes expired posts locally - NOTE: Does not save on master context
    @available(iOS 9.0, *)
    func deleteExpiredPosts() {
        
        let allGames = self.getGameWithObjectIds(withPredicate: nil)
        let fetchRequest = NSFetchRequest(entityName: "Post")
        
        for (gameId, game) in allGames {
            if game.postExpiryTime.integerValue != -1 {
                // Delete posts that are older than X hours
                let xHoursAgo = NSDate(timeIntervalSinceNow: NSTimeInterval.init(game.postExpiryTime.intValue*(-1)))
                let predicate = NSPredicate(format: "gameId == %@ AND createdAt < %@", gameId, xHoursAgo)
                fetchRequest.predicate = predicate
                
                do {
                    try self.masterContext.executeRequest(NSBatchDeleteRequest(fetchRequest: fetchRequest))
                    try self.masterContext.save()
                    print("Successfully deleted expired posts for game(\(game.fullName))")
                }
                catch let error as NSError {
                    print("Failed to delete posts for game(\(game.fullName)) \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    // Downloads/Updates Game data from Parse
    func downloadGames(withPredicate predicate: NSPredicate?, completionHandler: ((success: Bool) -> Void)?) {
        
        var gamesWithObjectId = self.getGameWithObjectIds(withPredicate: predicate)
        var downloadedGamesIds = [String]()
        
        var query = PFQuery(className:"Game", predicate: predicate)
        
        query.findObjectsInBackgroundWithBlock() {
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if let gameObjects = objects where error == nil {
                
                print("Game download count: \(objects!.count)")
                
                for gameObject in gameObjects {
                    
                    if let objectId = gameObject.objectId,
                        fullName = gameObject["fullName"] as? String,
                        shortName = gameObject["shortName"] as? String,
                        primaryLevelMin = gameObject["primaryLevelMin"] as? NSNumber,
                        primaryLevelMax = gameObject["primaryLevelMax"] as? NSNumber,
                        secondaryLevelMin = gameObject["secondaryLevelMin"] as?  NSNumber,
                        secondaryLevelMax = gameObject["secondaryLevelMax"] as? NSNumber,
                        postExpiryTime = gameObject["postExpiryTime"] as? NSNumber,
                        platformsArray = gameObject["platforms"] as? [String],
                        charactersArray = gameObject["characters"] as? [String],
                        playlistArray = gameObject["playlist"] as? [String] {
                            
                            var game: Game
                            
                            if let gameFound = gamesWithObjectId[objectId] {
                                game = gameFound
                                game.platforms = NSSet()
                                game.characters = NSSet()
                                game.gameTypes = NSSet()
                            } else {
                                game = NSEntityDescription.insertNewObjectForEntityForName("Game", inManagedObjectContext: self.mainContext) as! Game
                            }
                            
                            game.objectId = objectId
                            game.fullName = fullName
                            game.shortName = shortName
                            
                            game.primaryLevelMin = primaryLevelMin
                            game.primaryLevelMax = primaryLevelMax
                            game.secondaryLevelMin = secondaryLevelMin
                            game.secondaryLevelMax = secondaryLevelMax
                            game.postExpiryTime = postExpiryTime
                            
                            if game.primaryLevelMax.integerValue != 0 {
                                if let name = gameObject["primaryLevelName"] as? String {
                                    game.primaryLevelName = name
                                } else {
                                    game.primaryLevelName = "Primary Level"
                                }
                            }
                            
                            if game.secondaryLevelMax.integerValue != 0 {
                                if let name = gameObject["secondaryLevelName"] as? String {
                                    game.secondaryLevelName = name
                                } else {
                                    game.secondaryLevelName = "Secondary Level"
                                }
                            }
                            
                            
                            if platformsArray.count > 0 && charactersArray.count > 0 && playlistArray.count > 0 {
                                
                                for platformName in platformsArray {
                                    let platform = NSEntityDescription.insertNewObjectForEntityForName("Platform", inManagedObjectContext: self.mainContext) as! Platform
                                    platform.name = platformName
                                    platform.game = game
                                }
                                
                                for characterName in charactersArray {
                                    let character = NSEntityDescription.insertNewObjectForEntityForName("Character", inManagedObjectContext: self.mainContext) as! Character
                                    character.name = characterName
                                    character.game = game
                                }
                                
                                for gameTypeName in playlistArray {
                                    let gameType = NSEntityDescription.insertNewObjectForEntityForName("GameType", inManagedObjectContext: self.mainContext) as! GameType
                                    gameType.name = gameTypeName
                                    gameType.game = game
                                }
                            }
                            
                            downloadedGamesIds.append(objectId)
                    }
                }
                
                // Keep device and cloud in sync by deleting games that were deleted in the cloud (if any)
                
                var gamesToDelete = [String]()
                
                for key in gamesWithObjectId.keys {
                    if !downloadedGamesIds.contains(key) {
                        gamesToDelete.append(key)
                    }
                }
                
                for gameId in gamesToDelete {
                    if let game = gamesWithObjectId[gameId] {
                        print("Deleting game(\(game.fullName))")
                        self.mainContext.deleteObject(game)
                    }
                }
                
                do {
                    try self.mainContext.save()
                    UserDefaultsManager.sharedInstance.setGamesDownloadedState(true)
                    
                    self.masterContext.performBlock({
                        do {
                            try self.masterContext.save()
                            print("Games saved successfully")
                        }
                        catch let error as NSError {
                            print("Could not save downloaded game \(error), \(error.userInfo)")
                        }
                    })
                }
                catch let error as NSError {
                    print("Could not save downloaded game \(error), \(error.userInfo)")
                }
                
                if let handler = completionHandler {
                    handler(success: true)
                }
            }
            else {
                print("Could not download \(error!), \(error!.userInfo)")
                
                if let handler = completionHandler {
                    handler(success: false)
                }
            }
        }
    }
    
    // Downloads/Updates Post data from Parse specified by a game Id (more flexibility here)
    func downloadPosts(gameId: String, withPredicate predicate: NSPredicate?, completionHandler: ((success: Bool) -> Void)?) {
        
        let gamesWithObjectId = self.getGameWithObjectIds(withPredicate: nil)
        guard let game = gamesWithObjectId[gameId] else { return }
        
        // Maybe improve this in the future
        let gamePredicate = NSPredicate(format: "gameId == %@", gameId)
        let postsWithObjectId = self.getPostsWithObjectIds(withPredicate: gamePredicate)
        var downloadedPostsIds = [String]()
        
        let downloadDate = NSDate()
        
        let query = PFQuery(className: "Post", predicate: predicate)
        query.whereKey("gameId", equalTo: gameId)
        
        if game.postExpiryTime.integerValue != -1 {
            // Always get posts that are at max X hours old
            let xHoursAgo = NSDate(timeIntervalSinceNow: NSTimeInterval.init(game.postExpiryTime.intValue*(-1)))
            query.whereKey("createdAt", greaterThanOrEqualTo: xHoursAgo)
        }
        
        query.findObjectsInBackgroundWithBlock({
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if let postObjects = objects where error == nil {
                
                print("Posts download count: \(postObjects.count)")
                
                for postObject in postObjects {
                    
                    if let deviceId = postObject["deviceId"] as? String,
                        objectId = postObject.objectId,
                        createdAt = postObject.createdAt,
                        updateAt = postObject.updatedAt,
                        gameId = postObject["gameId"] as? String,
                        character = postObject["character"] as? String,
                        platform = postObject["platform"] as? String,
                        desc = postObject["description"] as? String,
                        gameType = postObject["gameType"] as? String,
                        mic = postObject["mic"] as? Bool,
                        playerId = postObject["playerId"] as? String,
                        primaryLevel = postObject["primaryLevel"] as? NSNumber,
                        secondaryLevel = postObject["secondaryLevel"] as? NSNumber {
                            
                            if let gameFound = gamesWithObjectId[gameId] {
                                
                                var post: Post
                                
                                if let postFound = postsWithObjectId[objectId] {
                                    post = postFound
                                } else {
                                    post = NSEntityDescription.insertNewObjectForEntityForName("Post", inManagedObjectContext: self.mainContext) as! Post
                                }
                                
                                post.deviceId = deviceId
                                post.objectId = objectId
                                post.createdAt = createdAt
                                post.updatedAt = updateAt
                                post.game = gameFound
                                post.gameId = gameId
                                post.character = character
                                post.platform = platform
                                post.desc = desc
                                post.gameType = gameType
                                post.mic = mic
                                post.playerId = playerId
                                post.primaryLevel = primaryLevel
                                post.secondaryLevel = secondaryLevel
                                
                                downloadedPostsIds.append(objectId)
                            }
                    }
                }
                
                // Keep device and cloud in sync by deleting posts that were deleted in the cloud (if any)
                
                var postsToDelete = [String]()
                
                for key in postsWithObjectId.keys {
                    if !downloadedPostsIds.contains(key) {
                        postsToDelete.append(key)
                    }
                }
                
                for postId in postsToDelete {
                    if let post = postsWithObjectId[postId] {
                        print("Deleting post(\(post.objectId))")
                        self.mainContext.deleteObject(post)
                    }
                }
                
                do {
                    try self.mainContext.save()
                    UserDefaultsManager.sharedInstance.setLastUpdatedPostsDate(downloadDate, gameId: gameId)
                    
                    self.masterContext.performBlock({
                        do {
                            try self.masterContext.save()
                            print("Post(s) saved successfully")
                        }
                        catch let error as NSError {
                            print("Could not save downloaded post(s) \(error), \(error.userInfo)")
                        }
                    })
                }
                catch let error as NSError {
                    print("Could not save downloaded posts \(error), \(error.userInfo)")
                }
                
                if let handler = completionHandler {
                    handler(success: true)
                }
            }
            else {
                print("Could not download \(error!), \(error!.userInfo)")
                
                if let handler = completionHandler {
                    handler(success: false)
                }
            }
        })
    }
    
    // Uploads Post data to Parse
    func uploadPost(post: PseudoPost, completionHandler: ((success: Bool) -> Void)?) {
        
        self.savePresetsForPost(post)
        self.deleteUsersLastPost()
        
        let gameObject = PFObject(withoutDataWithClassName: "Game", objectId: post.gameId)
        let postObject = PFObject(className: "Post")
        
        postObject["platform"] = post.platform
        postObject["mic"] = post.mic
        postObject["playerId"] = post.playerId
        postObject["character"] = post.character
        postObject["primaryLevel"] = post.primaryLevel
        postObject["secondaryLevel"] = post.secondaryLevel
        postObject["description"] = post.desc
        postObject["gameType"] = post.gameType
        postObject["game"] = gameObject
        postObject["gameId"] = gameObject.objectId
        
        if let deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString {
            postObject["deviceId"] = deviceId
        }
        
        postObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            
            if success && error == nil {
                print("Post has been uploaded.")
                UserDefaultsManager.sharedInstance.setLastPostDate(NSDate())
            }
            else {
                print("Post failed to upload. \(error!), \(error!.userInfo)")
            }
            
            if let handler = completionHandler {
                handler(success: success)
            }
        }
    }
    
    // Saves last uploaded post's data into game's "postPresets" property
    func savePresetsForPost(post: PseudoPost) {
        
        guard let game = self.retrieveGame(withId: post.gameId) else { return }
        
        let postPresets: PostPresets!
        
        if let presetsFound = game.postPresets {
            postPresets = presetsFound
        } else {
            postPresets = NSEntityDescription.insertNewObjectForEntityForName("PostPresets", inManagedObjectContext: self.mainContext) as! PostPresets
            game.postPresets = postPresets
        }
        
        postPresets.gameId = post.gameId
        postPresets.platform  = post.platform
        postPresets.mic  = post.mic
        postPresets.playerId  = post.playerId
        postPresets.character  = post.character
        postPresets.primaryLevel  = post.primaryLevel
        postPresets.secondaryLevel  = post.secondaryLevel
        postPresets.desc  = post.desc
        postPresets.gameType  = post.gameType
        
        // Not the most precise or accurate, but just putting it in there
        postPresets.createdAt = NSDate()
        
        do {
            try self.mainContext.save()
            
            self.masterContext.performBlock({
                do {
                    try self.masterContext.save()
                }
                catch let error as NSError {
                    print("Could not save post presets \(error), \(error.userInfo)")
                }
            })
        }
        catch let error as NSError {
            print("Could not save post presets \(error), \(error.userInfo)")
        }
        
    }
    
    // Deletes previous posts on Parse by the user
    func deleteUsersLastPost() {
        
        if let deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString {
            
            let query = PFQuery(className: "Post")
            query.whereKey("deviceId", equalTo: deviceId)
            query.whereKey("createdAt", lessThan: NSDate())

            query.findObjectsInBackgroundWithBlock() {
                (objects: [PFObject]?, error: NSError?) -> Void in
                if let posts = objects {
                    for post in posts {
                        post.deleteEventually()
                    }
                }
            }
        }
        
    }
    
    // Deletes post with given objecId
    func deletePostForId(id: String, completionHandler: ((success: Bool) -> Void)?) {
        
        let postObject = PFObject(withoutDataWithClassName: "Post", objectId: id)
        
        postObject.deleteInBackgroundWithBlock({
            (success: Bool, error: NSError?) -> Void in
            
            if success && error == nil {
                print("Post object deleted in Parse")
            } else {
                print("Failed to delete object in Parse")
            }
            
            if let handler = completionHandler {
                handler(success: success)
            }
        })
    }
    
    // MARK: Helper Methods
    
    func getGameWithObjectIds(withPredicate predicate: NSPredicate?) -> [String: Game] {
        
        let allExistingGames = self.retrieveGames()
        var gamesWithObjectId = [String: Game]()
        
        for game in allExistingGames {
            gamesWithObjectId[game.objectId] = game
        }
        
        return gamesWithObjectId
    }
    
    func getPostsWithObjectIds(withPredicate predicate: NSPredicate?) -> [String: Post] {
        
        let allExistingPosts = self.retrievePosts(withPredicate: predicate)
        var postsWithObjectId = [String: Post]()
        
        for post in allExistingPosts {
            postsWithObjectId[post.objectId] = post
        }
        
        return postsWithObjectId
    }
}
