# ResourcePackage

[![CI Status](http://img.shields.io/travis/1Fr3dG/ResourcePackage.svg?style=flat)](https://travis-ci.org/1Fr3dG/ResourcePackage)
[![Version](https://img.shields.io/cocoapods/v/ResourcePackage.svg?style=flat)](http://cocoapods.org/pods/ResourcePackage)
[![License](https://img.shields.io/cocoapods/l/ResourcePackage.svg?style=flat)](http://cocoapods.org/pods/ResourcePackage)
[![Platform](https://img.shields.io/cocoapods/p/ResourcePackage.svg?style=flat)](http://cocoapods.org/pods/ResourcePackage)

将 app 资源打包加密进行管理。

Package resources to a single file, and access them via file name as key.

## Requirements

* iOS 9.0+, OSX 10.12+

## Installation

TextFormater 可通过[CocoaPods](http://cocoapods.org)安装：

ResourcePackage is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "ResourcePackage"
```
## Structure
![Structure](structure.png)

## Usage

### Packager - 打包工具

~~~bash
git clone https://github.com/1Fr3dG/ResourcePackage.git
cd ResourcePackage
cd packager
swift build -c release
.build/release/packager
~~~

可使用该打包工具将资源目录打包为单个文件供 app 使用。

This tool designed to package a resource folder to a single file, for used by app.

**Note:** This tool support only gzip as compress algorithm, you can build your own tool to support more.

### Open a package

~~~swift
let _compress: SimpleEncrypter = EncrypterCompress(with: "gzip")
let _encrypt: SimpleEncrypter = EncrypterXor(with: "password12345")
let _pkgfile: String = "filename"
let pkg = ResourcePackage(with: _pkgfile, encrypter: _encrypt, compressor: _compress)
~~~

### Open packages with package reader

~~~swift
let pkgReader = ResourcePackageReader(
        withCache: false,
        useTwoStepLocating: false,
        autoDeviceCustomization: false,
        useKeyPrefix: false)
pkgReader.packages["pkg1"] = pkg

let themePkgReader = ResourcePackageReader(withTheme theme: String,
                            FromThemePackages respkg: ["themePkg1" : themePkg],
                            withBackwardTheme backward: "default")
~~~

### Read data

~~~swift
let stringValue = String(data:pkgReader[keyofString], encoding: .utf8)
let imageValue = UIImage(data:pkgReader[keyofImage])
~~~

### Use UIExtensions

~~~swift
uibutton.loadTheme(from: themePkgReader, key: "button1")
uilable.setText(from: themePkgReader, key: "labeltext")
uiimageview.setImage(from: themePkgReader, key: "image1")
~~~

* uibutton.loadTheme
	* key.title -> uibutton.attributedTitle
	* key.image -> uibutton.image
	* key.bgimg -> uibutton.backgroundImage
	* key.disabled.above
	* key.highlighted.above
	* key.selected.above
	* key.focused.above
* uilabel.setText
	* key -> uilabel.attributedText
* uiimageview.setImage
	* key -> uiimageview.image
	* key.highlighted -> uiimageview.highlightedImage

### Sounds

~~~swift
pkgReader.playSound(key: "asound", withVibrate: false)
pkgReader.playMusic("bgmusic.mp3", loops: 1, volume: 0.8)
~~~ 

## Author

[Alfred Gao](http://alfredg.org), [alfredg@alfredg.cn](mailto:alfredg@alfredg.cn)

## License

ResourcePackage is available under the MIT license. See the LICENSE file for more info.
