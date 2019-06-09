//  PhotoRecord
//
//  Created by Mohammad Zulqarnain on 09/06/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.

import Foundation
import UIKit

// This enum contains all the possible states a photo record can be in
enum PhotoRecordState {
  case new, downloaded, filtered, failed
}

class PhotoRecord {
  let name: String
  let url: URL
  var height: CGFloat
  var width: CGFloat
  var state = PhotoRecordState.new
    var image = UIImage(named: "Placeholder") {
        didSet {
            height = (image?.size.height)!
            width = (image?.size.width)!
        }
    }
  
    init(name:String, url:URL, height: CGFloat, width: CGFloat) {
    self.name = name
    self.url = url
    self.width = width
    self.height = height
  }
}

class PendingOperations {
  lazy var downloadsInProgress: [IndexPath: Operation] = [:]
  lazy var downloadQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "Download queue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  lazy var filtrationsInProgress: [IndexPath: Operation] = [:]
  lazy var filtrationQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "Image Filtration queue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
}

class ImageDownloader: Operation {

  let photoRecord: PhotoRecord
  
  let imageCache = NSCache<NSString, UIImage>()
    
  init(_ photoRecord: PhotoRecord) {
    self.photoRecord = photoRecord
  }

  override func main() {

    if isCancelled {
      return
    }
    if let cachedImage = imageCache.object(forKey: photoRecord.url.absoluteString as NSString) {
        photoRecord.image = cachedImage
        photoRecord.state = .downloaded
    } else {
        guard let imageData = try? Data(contentsOf: photoRecord.url) else { return }

        if isCancelled {
          return
        }

        if let image = photoRecord.image , !imageData.isEmpty {
          photoRecord.image = UIImage(data:imageData)
          imageCache.setObject(image, forKey: photoRecord.url.absoluteString as NSString)
          photoRecord.state = .downloaded
        } else {
          photoRecord.state = .failed
          photoRecord.image = UIImage(named: "Failed")
        }
    }
  }
}

class ImageFiltration: Operation {
  let photoRecord: PhotoRecord
  
  init(_ photoRecord: PhotoRecord) {
    self.photoRecord = photoRecord
  }
  
  override func main () {
    if isCancelled {
      return
    }
    
    guard photoRecord.state == .downloaded else {
      return
    }
    
    if let image = photoRecord.image,
       let filteredImage = applySepiaFilter(image) {
      photoRecord.image = filteredImage
      photoRecord.state = .filtered
    }
  }
  
  func applySepiaFilter(_ image: UIImage) -> UIImage? {
    guard let data = image.pngData() else { return nil }
    let inputImage = CIImage(data: data)
    
    if isCancelled {
      return nil
    }
    
    let context = CIContext(options: nil)
    
    guard let filter = CIFilter(name: "CINoiseReduction") else { return nil }
    filter.setValue(inputImage, forKey: kCIInputImageKey)
    
    if self.isCancelled {
      return nil
    }
    
    guard
      let outputImage = filter.outputImage,
      let outImage = context.createCGImage(outputImage, from: outputImage.extent)
    else {
      return nil
    }
    
    return UIImage(cgImage: outImage)
  }
}
