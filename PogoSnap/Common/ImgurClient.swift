//
//  ImgurClient.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/4/20.
//

import Foundation
import UIKit

struct ImgurClient {
    
    static var sharedInstance = ImgurClient()
    struct Const {
        static let imgurClientId = "6b4d7944e52e28f"
        static let imgurClientSecret = "bacb98c85b5e7561bb107f17181c1ae579cfa75c"
        static let imgurList = "imgurList"
    }
    let defaults = UserDefaults(suiteName: "group.com.PogoSnap")

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
    
    typealias Base64Handler = (String) -> Void
    typealias ImageUploadHandler = (ImageSource?, Bool) -> Void
    public func uploadImageToImgur(image: UIImage, completion: @escaping ImageUploadHandler) {
        
        func getBase64Image(image: UIImage, completion: @escaping Base64Handler) {
            DispatchQueue.main.async {
                let imageData = image.pngData()
                if let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters) {
                    completion(base64Image)
                }
            }
        }
        
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
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    completion(nil, true)
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                    completion(nil, true)
                    return
                }
                if let mimeType = response.mimeType, mimeType == "application/json", let data = data, let _ = String(data: data, encoding: .utf8) {
                    let parsedResult: [String: AnyObject]
                    do {
                        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                        if let dataJson = parsedResult["data"] as? [String: Any] {
                            if let link = dataJson["link"] as? String, let deleteHash = dataJson["deletehash"] as? String, let width = dataJson["width"] as? Int, let height = dataJson["height"] as? Int {
                                let imageSource = ImageSource(url: link, width: width, height: height)
                                let imageUrlDelete = ImageUrlDelete(url: link, deleteHash: deleteHash)
                                self.saveImageUrlDelete(imageUrlDelete: imageUrlDelete)
                                completion(imageSource, false)
                            }
                        }
                    } catch {
                        completion(nil, true)
                    }
                }
            }.resume()
        }
    }
    
    typealias DeleteImgHandler = (Bool) -> Void
    public func deleteImgurPhoto(imageUrlDelete: ImageUrlDelete, imageUrlDeletes: [ImageUrlDelete], completion: @escaping DeleteImgHandler) {
        var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image/\(imageUrlDelete.deleteHash)")!)
        request.addValue("Client-ID \(Const.imgurClientId)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(true)
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                completion(true)
                return
            }
            
            if let data = data {
                let parsedResult: [String: AnyObject]
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                    if let success = parsedResult["success"] as? Bool, success {
                        deleteImageFromDefaults(imageUrlDelete: imageUrlDelete, imageUrlDeletes: imageUrlDeletes)
                        completion(false)
                    } else {
                        completion(true)
                    }
                } catch {
                    completion(true)
                }
            }
        }.resume()
    }
    
    private func deleteImageFromDefaults(imageUrlDelete: ImageUrlDelete, imageUrlDeletes: [ImageUrlDelete]) {
        var imageUrlDeletes = imageUrlDeletes
        if let index = imageUrlDeletes.firstIndex(of: imageUrlDelete) {
            imageUrlDeletes.remove(at: index)
            NSKeyedArchiver.setClassName("PogoSnap.ImageUrlDelete", for: ImageUrlDelete.self)
            let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: imageUrlDeletes, requiringSecureCoding: false)
            defaults?.setValue(encodedData, forKey: Const.imgurList)
        }
    }
    
    public func saveImageUrlDelete(imageUrlDelete: ImageUrlDelete) {
        if let decoded = defaults?.object(forKey: Const.imgurList) as? Data {
            do {
                NSKeyedUnarchiver.setClass(ImageUrlDelete.self, forClassName: "PogoSnap.ImageUrlDelete")
                guard var imgurList = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? [ImageUrlDelete] else {
                    fatalError("ImageUrlDelete - Can't get Array")
                }
                imgurList.append(imageUrlDelete)
                NSKeyedArchiver.setClassName("PogoSnap.ImageUrlDelete", for: ImageUrlDelete.self)
                let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: imgurList, requiringSecureCoding: false)
                defaults?.setValue(encodedData, forKey: Const.imgurList)
            } catch {
                fatalError("ImageUrlDelete - Can't encode data: \(error)")
            }
        } else {
            NSKeyedArchiver.setClassName("ImageUrlDelete", for: ImageUrlDelete.self)
            let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: [imageUrlDelete], requiringSecureCoding: false)
            defaults?.setValue(encodedData, forKey: Const.imgurList)
        }
    }
    
    public func getImageUrlList() -> [ImageUrlDelete]? {
        if let decoded = defaults?.object(forKey: Const.imgurList) as? Data {
            do {
                NSKeyedUnarchiver.setClass(ImageUrlDelete.self, forClassName: "PogoSnap.ImageUrlDelete")
                guard let imgurList = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? [ImageUrlDelete] else {
                    fatalError("ImageUrlDelete - Can't get Array")
                }
                return imgurList
            } catch {
                fatalError("ImageUrlDelete - Can't encode data: \(error)")
            }
        }
        return nil
    }
}
