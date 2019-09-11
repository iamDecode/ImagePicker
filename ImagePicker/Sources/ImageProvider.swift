//
//  ImageProvider.swift
//  ImagePicker
//
//  Created by Dennis Collaris on 08/09/2019.
//  Copyright © 2019 Cocode. All rights reserved.
//

import UIKit
import Photos


class ImageProvider {
  private var fetchedResults: PHFetchResult<PHAsset>?

  fileprivate lazy var requestOptions: PHImageRequestOptions = {
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.isNetworkAccessAllowed = true
    options.resizeMode = .fast

    return options
  }()

  fileprivate let imageManager = PHCachingImageManager()

  deinit {
    imageManager.stopCachingImagesForAllAssets()
    fetchedResults = nil
  }

  var numberOfAssets: Int {
    return fetchedResults?.count ?? 0
  }

  func asset(for indexPath: IndexPath) -> PHAsset? {
    return fetchedResults?[indexPath.row]
  }

  func image(for asset: PHAsset, completion: @escaping (_ image: UIImage?) -> ()) {
    let targetSize = size(for: asset)
    requestOptions.isSynchronous = true

    // Workaround because PHImageManager.requestImageForAsset doesn't work for burst images
    if asset.representsBurst {
      if #available(iOS 13, *) {
        imageManager.requestImageDataAndOrientation(for: asset, options: requestOptions) { data, _, _, _ in
          let image = data.flatMap { UIImage(data: $0) }
          completion(image)
        }
      } else {
        imageManager.requestImageData(for: asset, options: requestOptions) { data, _, _, _ in
          let image = data.flatMap { UIImage(data: $0) }
          completion(image)
        }
      }
    }
    else {
      imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
        completion(image)
      }
    }
  }

  func size(for asset: PHAsset) -> CGSize {
    let proportion = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)

    let imageHeight = expandedPreviewHeight - 2 * previewInset
    let imageWidth = floor(proportion * imageHeight)

    return CGSize(width: imageWidth * UIScreen.main.scale, height: imageHeight * UIScreen.main.scale)
  }

  func fetchAssets(for mediaType: ImagePickerMediaType) {
    let options = PHFetchOptions()
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

    switch mediaType {
    case .image:
      options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
    case .video:
      options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
    case .imageAndVideo:
      options.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
    }

    let fetchLimit = 50
    options.fetchLimit = fetchLimit

    let result = PHAsset.fetchAssets(with: options)
    fetchedResults = result
    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = true
    requestOptions.deliveryMode = .fastFormat
    requestOptions.isNetworkAccessAllowed = true

    result.enumerateObjects(options: [], using: { asset, index, stop in
      if index == fetchLimit {
        stop.initialize(to: true)
      }

      self.prefetchImages(for: asset)
    })
  }

  fileprivate func prefetchImages(for asset: PHAsset) {
    let targetSize = size(for: asset)
    imageManager.startCachingImages(for: [asset], targetSize: targetSize, contentMode: .aspectFill, options: requestOptions)
  }
}

