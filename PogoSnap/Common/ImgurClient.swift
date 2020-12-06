//
//  ImgurClient.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/4/20.
//

import Foundation
import UIKit

struct ImgurClient {
    
    struct Const {
        static let imgurClientId = "6b4d7944e52e28f"
        static let imgurClientSecret = "bacb98c85b5e7561bb107f17181c1ae579cfa75c"
    }
    
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
    typealias ImageUploadHandler = (ImageSource, ImageUrlDelete) -> Void
    static func uploadImageToImgur(image: UIImage, completion: @escaping ImageUploadHandler) {
        
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
                if let error = error {
                    print("failed with error: \(error)")
                    return
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                    print("server error")
                    return
                }
                if let mimeType = response.mimeType, mimeType == "application/json", let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("imgur upload results: \(dataString)")

                    let parsedResult: [String: AnyObject]
                    do {
                        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                        if let dataJson = parsedResult["data"] as? [String: Any] {
                            if let link = dataJson["link"] as? String, let deleteHash = dataJson["deletehash"] as? String, let width = dataJson["width"] as? Int, let height = dataJson["height"] as? Int {
                                let imageSource = ImageSource(url: link, width: width, height: height)
                                let imageUrlDelete = ImageUrlDelete(url: link, deleteHash: deleteHash)
                                completion(imageSource, imageUrlDelete)
                            }
                        }
                    } catch {
                        // Display an error
                    }
                }
            }.resume()
        }
    }
}
