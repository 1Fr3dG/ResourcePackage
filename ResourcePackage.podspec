Pod::Spec.new do |s|
  s.name             = 'ResourcePackage'
  s.version          = '1.0.2'
  s.summary          = 'Manage resources for application.'

  s.description      = <<-DESC
Package resources to a single file, and access them via file name as key.

So resources can be easily managemented as well as encrypted. 
                       DESC

  s.homepage         = 'https://github.com/1fr3dg/ResourcePackage'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alfred Gao' => 'alfredg@alfredg.cn' }
  s.source           = { :git => 'https://github.com/1fr3dg/ResourcePackage.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.12'

  s.source_files = 'Sources/*'
  
  s.dependency 'SimpleEncrypter'
  s.dependency 'TextFormater'
  s.ios.dependency 'DeviceKit'
end
