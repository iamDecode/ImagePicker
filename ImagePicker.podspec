Pod::Spec.new do |spec|
  spec.name = 'CCLImagePicker'
  spec.version = '0.0.1'
  spec.summary = 'CCLImagePicker allows you to preview and select photos right from a native UIAlertController.'
  spec.homepage = 'https://github.com/iamDecode/ImagePicker'
  spec.license = { :type => 'BSD', :file => 'LICENSE' }
  spec.author = { 'Dennis Collaris' => 'd.collaris@me.com' }
  spec.source = { :git => 'https://github.com/iamDecode/ImagePicker.git', :tag => "#{spec.version}" }
  spec.source_files = 'ImagePicker/Sources/*.swift'
  spec.resource  = "ImagePicker/Sources/Resources/Assets.xcassets"
  spec.framework = "Photos"
  spec.requires_arc = true
  spec.ios.deployment_target = '10.2'
  spec.dependency 'OrderedSet.swift', '~> 0.1'
  spec.swift_version = '5.0'
end