//  ZestViewController
//
//  Created by Mohammad Zulqarnain on 09/06/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.

import UIKit
import CoreImage

class ZestViewController: UIViewController {
  var zestModel: ZestModel!
  var zestTableView: ZestTableView!
  let pendingOperations = PendingOperations()
  let cellHeight = 60.0
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Zest List Demo"
    
    let alertController = UIAlertController(title: "Oh No!", message: "There was an issue fetching photo details.", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default)
    alertController.addAction(okAction)
    
    setupViews()
    
    setupModel()
    
    zestModel.fetchPhotoDetails(successCompletionHandler: { data in
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.zestTableView.reloadData()
        }
    }, failureCompletionHandler: {_ in 
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.present(alertController, animated: true, completion: nil)
        }
    })
  }
  
  func setupViews() {
    zestTableView = ZestTableView(frame: self.view.frame, style: .plain)
    zestTableView.delegate = self
    zestTableView.dataSource = self
    zestTableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellIdentifier")
    self.view.addSubview(zestTableView)
  }
    
  func setupModel() {
    zestModel = ZestModel()
  }
  
  // MARK: - operation management
  
  func suspendAllOperations() {
    pendingOperations.downloadQueue.isSuspended = true
    pendingOperations.filtrationQueue.isSuspended = true
  }
  
  func resumeAllOperations() {
    pendingOperations.downloadQueue.isSuspended = false
    pendingOperations.filtrationQueue.isSuspended = false
  }
  
  func loadImagesForOnscreenCells() {
    if let pathsArray = zestTableView?.indexPathsForVisibleRows {
      var allPendingOperations = Set(pendingOperations.downloadsInProgress.keys)
      allPendingOperations.formUnion(pendingOperations.filtrationsInProgress.keys)

      var toBeCancelled = allPendingOperations
      let visiblePaths = Set(pathsArray)
      toBeCancelled.subtract(visiblePaths)

      var toBeStarted = visiblePaths
      toBeStarted.subtract(allPendingOperations)

      for indexPath in toBeCancelled {
        if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
          pendingDownload.cancel()
        }
        
        pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
        if let pendingFiltration = pendingOperations.filtrationsInProgress[indexPath] {
          pendingFiltration.cancel()
        }
        
        pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
      }

      for indexPath in toBeStarted {
        let recordToProcess = zestModel.photos[indexPath.row]
        startOperations(for: recordToProcess, at: indexPath)
      }
    }
  }

    func startOperations(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        switch (photoRecord.state) {
        case .new:
            startDownload(for: photoRecord, at: indexPath)
        case .downloaded:
            startFiltration(for: photoRecord, at: indexPath)
        default:
            NSLog("do nothing")
        }
    }
    
    func startDownload(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        
        guard pendingOperations.downloadsInProgress[indexPath] == nil else {
            return
        }
        
        let downloader = ImageDownloader(photoRecord)
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                self.zestTableView?.reloadRows(at: [indexPath], with: .fade)
            }
        }
        
        pendingOperations.downloadsInProgress[indexPath] = downloader
        
        pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    func startFiltration(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        guard pendingOperations.filtrationsInProgress[indexPath] == nil else {
            return
        }
        
        let filterer = ImageFiltration(photoRecord)
        filterer.completionBlock = {
            if filterer.isCancelled {
                return
            }
            DispatchQueue.main.async {
                self.pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
                self.zestTableView?.reloadRows(at: [indexPath], with: .fade)
            }
        }
        
        pendingOperations.filtrationsInProgress[indexPath] = filterer
        pendingOperations.filtrationQueue.addOperation(filterer)
    }
}

extension ZestViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return zestModel.photos.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(cellHeight)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
        
        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(style: .gray)
            cell.accessoryView = indicator
        }
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        
        let photoDetails = zestModel.photos[indexPath.row]
        
        cell.textLabel?.text = photoDetails.name
        cell.imageView?.image = photoDetails.image
        
        switch (photoDetails.state) {
        case .filtered:
            indicator.stopAnimating()
        case .failed:
            indicator.stopAnimating()
            cell.textLabel?.text = "Failed to load"
        case .new, .downloaded:
            indicator.startAnimating()
            if !tableView.isDragging && !tableView.isDecelerating {
                startOperations(for: photoDetails, at: indexPath)
            }
        }
        
        return cell
    }
    
    // MARK: - scrollview delegate methods
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        suspendAllOperations()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadImagesForOnscreenCells()
        resumeAllOperations()
    }
    
}
