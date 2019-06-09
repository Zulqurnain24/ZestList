//  ZestViewModel
//
//  Created by Mohammad Zulqarnain on 09/06/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.

import UIKit

let dataSourceEndpoint = URL(string:"http://pastebin.com/raw/wgkJgazE")!

class ZestModel {
    var photos: [PhotoRecord] = []

    func fetchPhotoDetails(successCompletionHandler: @escaping (Data) -> Void, failureCompletionHandler: @escaping (Error) -> Void) {
        let request = URLRequest(url: dataSourceEndpoint)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = URLSession(configuration: .default).dataTask(with: request) { data, response, error in
            let alertController = UIAlertController(title: "Oops!", message: "There was an error fetching photo details.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [[String: AnyObject]] {
                        for item in json {
                            guard let nameDictionary = item["user"] as! Dictionary<String, AnyObject>?, let name = nameDictionary["name"] as! String?, let profile_image = nameDictionary["profile_image"]  as! Dictionary<String, AnyObject>?, let small_image = profile_image["medium"] as! String?, let photoRecord = PhotoRecord(name: name, url: (URL(string: small_image) as URL?)!, height: (UIImage(named: "Placeholder")?.size.height)!, width: (UIImage(named: "Placeholder")?.size.width)!) as PhotoRecord? else { return }
                            self.photos.append(photoRecord)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        successCompletionHandler(data)
                    }
                } catch {
                    DispatchQueue.main.async {
                        failureCompletionHandler(error)
                    }
                }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    failureCompletionHandler(error)
                }
            }
        }
        task.resume()
    }
}


