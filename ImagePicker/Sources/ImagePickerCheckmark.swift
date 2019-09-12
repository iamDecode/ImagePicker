//
//  ImagePickerCheckmark.swift
//  ImagePicker
//
//  Created by Dennis Collaris on 08/09/2019.
//  Copyright © 2019 Cocode. All rights reserved.
//

import UIKit

class ImagePickerCheckmark: UIButton {
  override var isSelected: Bool {
    didSet {
      reloadButtonBackgroundColor()
    }
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
    tintColor = .white
    layer.cornerRadius = frame.height / 2
    isUserInteractionEnabled = false

    let bundle = Bundle(for: ImagePicker.self)
    let checkmarkImage = UIImage(named: "checkmark", in: bundle, compatibleWith: nil)
    let selectedCheckmarkImage = UIImage(named: "checkmark-selected", in: bundle, compatibleWith: nil)

    setImage(checkmarkImage, for: UIControl.State())
    setImage(selectedCheckmarkImage, for: .selected)
  }

  override func tintColorDidChange() {
    super.tintColorDidChange()
    reloadButtonBackgroundColor()
  }

  fileprivate func reloadButtonBackgroundColor() {
    backgroundColor = isSelected ? superview?.tintColor : .clear
  }
}
