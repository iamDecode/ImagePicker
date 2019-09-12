//
//  ImagePickerCell.swift
//  ImagePicker
//
//  Created by Dennis Collaris on 08/09/2019.
//  Copyright © 2019 Cocode. All rights reserved.
//

import UIKit

class ImagePickerCell: UICollectionViewCell {
  public let checkmark = ImagePickerCheckmark(frame: CGRect(origin: .zero, size: CGSize(width: 22, height: 22)))

  private var checkmarkCenter: CGPoint = .zero {
    didSet {
      if checkmarkCenter != oldValue {
        setNeedsLayout()
      }
    }
  }

  public var showCheckmarks: Bool = true {
    didSet {
      if showCheckmarks != oldValue {
        checkmark.center = checkmarkCenter
        checkmark.isHidden = !showCheckmarks
      }
    }
  }

  let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 8 // TODO: make configurable?

    return imageView
  }()

  let videoIndicatorView: UIImageView = {
    let bundle = Bundle(for: ImagePicker.self)
    let videoImage = UIImage(named: "video", in: bundle, compatibleWith: nil)

    let imageView = UIImageView(image: videoImage)
    imageView.tintColor = .white
    imageView.isHidden = true
    return imageView
  }()

  public func updateSelection(isSelected: Bool) {
    checkmark.isSelected = isSelected
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  fileprivate func configureView() {
    addSubview(imageView)
    addSubview(videoIndicatorView)
    addSubview(checkmark)
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    imageView.image = nil
    videoIndicatorView.isHidden = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    imageView.frame = bounds

    let videoIndicatViewSize = videoIndicatorView.image?.size ?? CGSize()
    let videoIndicatorViewOrigin = CGPoint(x: bounds.minX + previewInset, y: bounds.maxY - previewInset - videoIndicatViewSize.height)
    videoIndicatorView.frame = CGRect(origin: videoIndicatorViewOrigin, size: videoIndicatViewSize)

    checkmark.center = checkmarkCenter
  }

  override public func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    if let attributes = layoutAttributes as? ImagePickerLayout.Attributes {
      checkmarkCenter = attributes.selectionCenter
    }
    layoutIfNeeded()
  }
}

