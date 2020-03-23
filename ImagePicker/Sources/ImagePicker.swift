//
//  ImagePicker.swift
//  ImagePicker
//
//  Created by Dennis Collaris on 08/09/2019.
//  Copyright © 2019 Cocode. All rights reserved.
//

import UIKit
import Photos
import OrderedSet_swift


var previewInset: CGFloat = 8
let previewHeight: CGFloat = 100
var expandedPreviewHeight: CGFloat = 200


public enum ImagePickerMediaType {
  case image
  case video
  case imageAndVideo
}


@objc public protocol ImagePickerDelegate {
    @objc optional func imagePicker(_ alertController: UIAlertController, didUpdateSelection assets: [PHAsset])
}


public class ImagePicker: UICollectionView {
  var layout: ImagePickerLayout {
    return collectionViewLayout as! ImagePickerLayout
  }

  weak var alertController: UIAlertController?

  weak var previewHeightConstraint: NSLayoutConstraint!

  weak var alertHeightConstraint: NSLayoutConstraint!

  weak var landscapeConstraint: NSLayoutConstraint?

  public var pickerDelegate: ImagePickerDelegate?

  public var maximumSelection: Int = 1

  public var mediaType: ImagePickerMediaType = .image

  public fileprivate(set) var previewsExpanded = false

  fileprivate var provider: ImageProvider?

  fileprivate var selection: OrderedSet<IndexPath> = []

  public var selectedAssets: [PHAsset] {
    return selection.compactMap { provider?.asset(for: $0) }
  }

  var bouncing: Bool {
    if contentOffset.x < -contentInset.left { return true }
    if contentOffset.x + frame.width > contentSize.width + contentInset.right { return true }
    return false
  }

  var isLandscape: Bool {
    let orientation = UIDevice.current.orientation

    if orientation == .unknown {
      if #available(iOS 13, *) {
        return window?.windowScene?.interfaceOrientation.isLandscape ?? false
      } else {
        return UIApplication.shared.statusBarOrientation.isLandscape
      }
    }

    return orientation.isLandscape
  }

  public required convenience init(alertController: UIAlertController) {
    self.init(frame: .zero, collectionViewLayout: ImagePickerLayout())
    self.alertController = alertController
    delegate = self
    dataSource = self
    provider = ImageProvider()
  }

  deinit {
    provider = nil
  }

  override public func didMoveToWindow() {
    super.didMoveToWindow()
    configureView()
  }

  private func configureView() {
    guard let alertController = alertController, alertHeightConstraint == nil else { return }

    translatesAutoresizingMaskIntoConstraints = false
    alertController.view.translatesAutoresizingMaskIntoConstraints = false

    backgroundColor = .clear
    allowsMultipleSelection = true
    contentInset = UIEdgeInsets(top: previewInset, left: previewInset, bottom: previewInset, right: previewInset)
    showsHorizontalScrollIndicator = false
    alwaysBounceHorizontal = true
    register(ImagePickerCell.self, forCellWithReuseIdentifier: NSStringFromClass(ImagePickerCell.self))

    topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 0).isActive = true
    if let view = alertController.view.subviews.first?.subviews.first {
      rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
    } else {
      rightAnchor.constraint(equalTo: alertController.view.rightAnchor, constant: 0).isActive = true
    }
    leftAnchor.constraint(equalTo: alertController.view.leftAnchor, constant: 0).isActive = true
    let height = previewsExpanded ? expandedPreviewHeight : previewHeight
    previewHeightConstraint = heightAnchor.constraint(equalToConstant: height)
    previewHeightConstraint.isActive = true
    let alertHeight = previewHeightConstraint.constant + calcHeight(for: alertController)
    alertHeightConstraint = alertController.view.heightAnchor.constraint(equalToConstant: alertHeight)
    alertHeightConstraint.priority = .defaultHigh + 1
    alertHeightConstraint.isActive = true

    landscapeConstraint = alertController.view.subviews.first?.subviews.first?.bottomAnchor.constraint(equalTo: alertController.view.bottomAnchor)
    landscapeConstraint?.priority = isLandscape ? .defaultHigh : .defaultLow
    landscapeConstraint?.isActive = true

    NotificationCenter.default.addObserver(self, selector: #selector(ImagePicker.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)

    provider?.fetchAssets(for: mediaType)
    reloadData()
  }

  @objc func rotated() {
    updatePreviewHeight()

    landscapeConstraint?.priority = isLandscape ? .defaultHigh : .defaultLow
  }

  func expandPreview(for indexPath: IndexPath, completion: (() -> ())? = nil) {
      previewsExpanded = true
      layout.selectedCellIndexPath = indexPath

      setNeedsLayout()

      UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.92, initialSpringVelocity: 1, options: .curveLinear, animations: { [unowned self] in
        self.setNeedsLayout()
        self.updatePreviewHeight()
        self.updateVisibleArea()
      }, completion: { _ in
          completion?()
      })
  }

  func shrinkPreview(for indexPath: IndexPath, completion: (() -> ())? = nil) {
    previewsExpanded = false
    layout.selectedCellIndexPath = indexPath

    setNeedsLayout()
    layoutIfNeeded()

    UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .curveLinear, animations: { [unowned self] in
      self.setNeedsLayout()
      self.updatePreviewHeight()
      self.updateVisibleArea()
    }, completion: { _ in
        completion?()
    })
  }

  func updatePreviewHeight() {
    let height = previewsExpanded ? expandedPreviewHeight : previewHeight
    previewHeightConstraint.constant = height
    alertHeightConstraint.constant = height + calcHeight(for: alertController)
    alertHeightConstraint.priority = .defaultHigh + 1

    alertController?.view.superview?.layoutIfNeeded()
  }

  func calcHeight(for alertController: UIAlertController?) -> CGFloat {
    guard let alertController = alertController else { return 0 }

    if UIDevice.current.userInterfaceIdiom == .phone && isLandscape {
      return 65
    }

    var height = alertController.actions.filter { $0.style != .cancel }.map { _ in CGFloat(58) }.reduce(0, +)
    if alertController.actions.contains(where: { $0.style == .cancel }) && UIDevice.current.userInterfaceIdiom == .phone  {
      height += 65
    }
    return height
  }
}

// MARK: UICollectionViewDataSource

extension ImagePicker: UICollectionViewDataSource {
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return provider?.numberOfAssets ?? 0
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ImagePickerCell.self), for: indexPath) as! ImagePickerCell

    if let asset = provider?.asset(for: indexPath) {
      cell.videoIndicatorView.isHidden = asset.mediaType != .video

      provider?.image(for: asset) { image in
        cell.imageView.image = image
      }
    }

    cell.checkmark.isSelected = selection.contains(indexPath)

    return cell
  }
}


// MARK: UICollectionViewDelegate

extension ImagePicker: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if selection.count >= maximumSelection, let deselectedIndexPath = selection.first {
      if let cell = cellForItem(at: deselectedIndexPath) as? ImagePickerCell {
        cell.updateSelection(isSelected: false)
      }
      let _ = selection.removeFirst()
    }

    selection.append(indexPath)

    if !previewsExpanded {
      expandPreview(for: indexPath)
    }
    else {
      // scrollToItemAtIndexPath doesn't work reliably
      if let cell = collectionView.cellForItem(at: indexPath) {
        var contentOffset = CGPoint(x: cell.frame.midX - collectionView.frame.width / 2.0, y: -previewInset)
        contentOffset.x = max(contentOffset.x, -collectionView.contentInset.left)
        contentOffset.x = min(contentOffset.x, collectionView.contentSize.width - collectionView.frame.width + collectionView.contentInset.right)

        collectionView.setContentOffset(contentOffset, animated: true)
      }
    }

    if let cell = cellForItem(at: indexPath) as? ImagePickerCell {
      cell.updateSelection(isSelected: true)
    }

    if let alertController = alertController {
      let assets = selection.compactMap { provider?.asset(for: $0) }
      pickerDelegate?.imagePicker?(alertController, didUpdateSelection: assets)
    }
  }

  public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    if selection.remove(indexPath) != nil {
      if selection.isEmpty {
        shrinkPreview(for: indexPath)
      }

      if let cell = cellForItem(at: indexPath) as? ImagePickerCell {
        cell.updateSelection(isSelected: false)
      }

      if let alertController = alertController {
        let assets = selection.compactMap { provider?.asset(for: $0) }
        pickerDelegate?.imagePicker?(alertController, didUpdateSelection: assets)
      }
    }
  }

  public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    updateVisibleArea(for: cell, at: indexPath)
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView === self else {
      return
    }

    updateVisibleArea()
  }

  private func updateVisibleArea() {
    for indexPath in indexPathsForVisibleItems {
      if let cell = cellForItem(at: indexPath) {
        updateVisibleArea(for: cell, at: indexPath)
      }
    }
  }

  private func updateVisibleArea(for cell: UICollectionViewCell, at indexPath: IndexPath) {
    guard let cell = cell as? ImagePickerCell else {
      return
    }

    let cellVisibleRectInCollectionView = cell.convert(cell.bounds, to: self)
    let cellVisibleAreaInCollectionView = cellVisibleRectInCollectionView.intersection(bounds)
    let cellVisibleRect = cell.convert(cellVisibleAreaInCollectionView, from: self)

    layout.updateVisibleArea(cellVisibleRect, itemAt: indexPath, cell: cell)
  }
}


// MARK: UICollectionViewDelegateFlowLayout

extension ImagePicker: ImagePickerLayoutDelegate {
  public func collectionView(_ aCollectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if previewsExpanded {
      return collectionView(aCollectionView, layout: layout, largeSizeForItemAt: indexPath)
    }

    let size = previewHeight - 2 * previewInset
    return CGSize(width: size, height: size)
  }

  func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, largeSizeForItemAt indexPath: IndexPath) -> CGSize {
    guard let asset = provider?.asset(for: indexPath), let size = provider?.size(for: asset) else {
      return .zero
    }

    let currentImagePreviewHeight = expandedPreviewHeight - 2 * previewInset
    let scale = currentImagePreviewHeight / size.height

    return CGSize(width: size.width * scale, height: currentImagePreviewHeight)
  }
}
