//
//  ImgurClient.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/4/20.
//

import Foundation
import CoreData
import UIKit
import KeychainAccess

class ImgurClient {
    
    static var sharedInstance = ImgurClient()
    struct Const {
        static let imgurClientId = "6b4d7944e52e28f"
        static let imgurClientSecret = "bacb98c85b5e7561bb107f17181c1ae579cfa75c"
        static let imgurList = "imgurList"
        static let maxUploadCount = 3
    }
    let keychain = Keychain(service: "com.PogoSnap", accessGroup: "group.com.PogoSnap")
    
    lazy var persistentContainer: NSPersistentContainer = {
       /*
        The persistent container for the application. This implementation
        creates and returns a container, having loaded the store for the
        application to it. This property is optional since there are legitimate
        error conditions that could cause the creation of the store to fail.
        */
       let container = NSPersistentContainer(name: "PogoSnap")

       var persistentStoreDescriptions: NSPersistentStoreDescription

       let storeUrl =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.PogoSnap")!.appendingPathComponent("PogoSnap.sqlite")

       let description = NSPersistentStoreDescription()
       description.shouldInferMappingModelAutomatically = true
       description.shouldMigrateStoreAutomatically = true
       description.url = storeUrl

       container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.PogoSnap")!.appendingPathComponent("PogoSnap.sqlite"))]

       container.loadPersistentStores(completionHandler: { (_, error) in
           if let error = error as NSError? {
               fatalError("Unresolved error \(error), \(error.userInfo)")
           }
       })
       return container
   }()

    private init() {}

//    {
//       "data":{
//          "id":"EBJIeoZ",
//          "title":null,
//          "description":null,
//          "datetime":1582389917,
//          "type":"image/jpeg",
//          "animated":false,
//          "width":1667,
//          "height":2048,
//          "size":172036,
//          "views":0,
//          "bandwidth":0,
//          "vote":null,
//          "favorite":false,
//          "nsfw":null,
//          "section":null,
//          "account_url":null,
//          "account_id":0,
//          "is_ad":false,
//          "in_most_viral":false,
//          "has_sound":false,
//          "tags":[
//
//          ],
//          "ad_type":0,
//          "ad_url":"",
//          "edited":"0",
//          "in_gallery":false,
//          "deletehash":"aCbT2JmYe6JYJp1",
//          "name":"",
//          "link":"https://i.imgur.com/EBJIeoZ.jpg"
//       },
//       "success":true,
//       "status":200
//    }
    
    private func getBase64Image(image: UIImage, completion: @escaping Base64Handler) {
        DispatchQueue.main.async {
            let imageData = image.jpegData(compressionQuality: 1.0)
            if let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters) {
                completion(base64Image)
            }
        }
    }
    
    public func getImageUploadCount() -> Int {
        if let imageUploadCountString = keychain["imageUploadCount"], let imageUploadCount = Int(imageUploadCountString) {
            return imageUploadCount
        }
        return 0
    }
    
    public func incrementUploadCount() {
        let imageUploadCount = getImageUploadCount() + 1
        keychain["imageUploadCount"] = String(imageUploadCount)
    }
    
    public func canUpload() -> Bool {
        let currentDate = Date()
        let cal = Calendar(identifier: .gregorian)
        let nextPossibleDate = cal.startOfDay(for: currentDate).timeIntervalSince1970

        if let previousTimeString = keychain["imageUploadTime"] {
            let imageUploadCount = getImageUploadCount()
            let previousDate = TimeInterval(previousTimeString)
            
            if previousDate == nextPossibleDate && imageUploadCount < Const.maxUploadCount {
                return true
            } else if previousDate != nextPossibleDate {
                keychain["imageUploadTime"] = String(nextPossibleDate)
                keychain["imageUploadCount"] = String(0)
                return true
            } else {
                // cannot upload
                return false
            }
        }

        // keychain values are not set and return true for first timers
        return true
    }
    
    typealias Base64Handler = (String) -> Void
    typealias ImageUploadHandler = (ImgurUploadResult) -> Void // image, errorOccured, maxedOut
    public func uploadImageToImgur(image: UIImage, completion: @escaping ImageUploadHandler) {
        getBase64Image(image: image) { base64Image in
            let boundary = "Boundary-\(UUID().uuidString)"
            var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!)
            request.addValue("Client-ID \(Const.imgurClientId)", forHTTPHeaderField: "Authorization")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"

            var body = ""
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"image\""
            body += "\r\n\r\n\(base64Image)\r\n"
            body += "--\(boundary)--\r\n"
            
            let postData = body.data(using: .utf8)
            request.httpBody = postData
            
            URLSession.shared.dataTask(with: request) { data, response, _ in
                guard let response = response, let data = data, let mimeType = response.mimeType, mimeType == "application/json" else {
                    completion(ImgurUploadResult.error(error: "Unable to upload image"))
                    return
                }

                do {
                    guard let parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] else {
                        completion(ImgurUploadResult.error(error: "Unable to upload image"))
                        return
                    }
                    if let dataJson = parsedResult["data"] as? [String: Any] {
                        if let error = dataJson["error"], error as? String == "File is over the size limit" {
                            completion(ImgurUploadResult.error(error: "Unable to upload image: Imgur and PogoSnap only allows image size up to 10MB"))
                        } else if let link = dataJson["link"] as? String, let deleteHash = dataJson["deletehash"] as? String, let width = dataJson["width"] as? Int, let height = dataJson["height"] as? Int {
                            let imageSource = ImageSource(url: link, width: width, height: height)
                            self.saveImageUrlDelete(url: link, deleteHash: deleteHash)
                            completion(ImgurUploadResult.success(imageSource: imageSource))
                        } else {
                            completion(ImgurUploadResult.error(error: "Unable to upload image"))
                        }
                    } else {
                        completion(ImgurUploadResult.error(error: "Unable to upload image"))
                    }
                } catch {
                    completion(ImgurUploadResult.error(error: "Unable to upload image"))
                }
            }.resume()
        }
    }
    
    typealias DeleteImgHandler = (ImgurDeleteResult) -> Void
    public func deleteImgurPhoto(imageUrlDelete: ImageUrlDelete, completion: @escaping DeleteImgHandler) {
        guard let deleteHash = imageUrlDelete.deleteHash else {
            return
        }
        var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image/\(deleteHash)")!)
        request.addValue("Client-ID \(Const.imgurClientId)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode), let data = data else {
                completion(ImgurDeleteResult.error)
                return
            }
            
            do {
                guard let parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] else {
                    completion(ImgurDeleteResult.error)
                    return
                }
                if let success = parsedResult["success"] as? Bool, success {
                    self.deleteImageUrlDelete(imageUrlDelete: imageUrlDelete)
                    completion(ImgurDeleteResult.success)
                } else {
                    completion(ImgurDeleteResult.error)
                }
            } catch {
                completion(ImgurDeleteResult.error)
            }
        }.resume()
    }
    
    private func deleteImageUrlDelete(imageUrlDelete: ImageUrlDelete) {
        let context = self.persistentContainer.viewContext
        context.delete(imageUrlDelete)
    }
    
    public func saveImageUrlDelete(url: String, deleteHash: String) {
        let context = self.persistentContainer.viewContext
        let imageUrlDelete = ImageUrlDelete(context: context)
        imageUrlDelete.url = url
        imageUrlDelete.deleteHash = deleteHash
        
        do {
            try context.save()
        } catch {}
    }
    
    public func getImageUrlList() -> [ImageUrlDelete]? {
        let context = self.persistentContainer.viewContext
        let imageUrlDeleteFetch = NSFetchRequest<ImageUrlDelete>(entityName: "ImageUrlDelete")
        
        do {
            let fetchedImageUrlDeletes = try context.fetch(imageUrlDeleteFetch)
            return fetchedImageUrlDeletes
        } catch {}

        return nil
    }
}
