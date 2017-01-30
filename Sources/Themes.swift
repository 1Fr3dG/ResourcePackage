//
//  Themes.swift
//
//  Created by Alfred Gao on 2016/10/28.
//
//

import Foundation
import TextFormater
#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

extension ResourcePackageReader {
    /// 主题前缀，通常为资源包中的目录名
    ///
    /// key prefix of theme, normally was folder name of a package
    public var theme: String? {
        get {
            guard _useprefix else {
                return nil
            }
            
            var _themekey = _keyprefix
            guard _themekey.characters.count > 0 else {
                return ""
            }
            if _themekey.substring(from: _themekey.endIndex) == "/" {
                _themekey.remove(at: _themekey.endIndex)
            }
            
            return _themekey
        }
        
        set {
            if newValue == nil {
                _keyprefix = ""
            } else {
                if themesList[newValue] != nil {
                    _keyprefix = newValue!
                    cleanCache()
                } else {
                    _keyprefix = _keyprefixbackward
                    _logger("Theme \(newValue) not exists, use \(_keyprefix)")
                }
            }
            _textFormater = themeTextFormater
        }
    }
    
    /// Get theme name of a key
    /// - the name should be stored on `name.text` file in theme folder
    public func getThemeName(theme key: String? = nil) -> String? {
        guard _useprefix else {
            return nil
        }
        
        let _key = key ?? _keyprefix
        
        if let _nameData = getData(key: _key + "/name.text"),
            let _nameString = String(data: _nameData, encoding: .utf8) {
            var _name = _nameString
            if _name.characters.first == "/" {
                _name.remove(at: _name.startIndex)
            }
            return _name
        } else {
            return ""
        }
    }
    
    /// 可用主题列表
    ///
    /// List themes of packages
    /// `/themes.list` contains the key list of themes, one per line
    public var themesList : [String : String] {
        get {
            var themes: [String : String] = [:]
            _logger("Building theme list")
            for (_, _pkg) in packages {
                _logger("  Getting theme list from: [\(_pkg.resourcePackageFileName)]")
                if let _themeListData = _pkg["themes.list"],
                    let _themeList = String(data: _themeListData, encoding: .utf8) {
                    _logger("    \(_themeList)")
                    let _themes = _themeList.components(separatedBy: .newlines)
                    for _theme in _themes {
                        if let _themeName = getThemeName(theme: _theme) {
                            themes[_theme] = _themeName
                        }
                    }
                }
            }
            return themes
        }
    }
    
    /// 主题定制文本格式化器
    ///
    /// Theme custimized TextFormater
    /// configuration in `[theme]/textformat/` folder
    public var themeTextFormater: TextFormater {
        get {
            let _f = TextFormater()
            // build formater
            // seperator
            if let _sd = self["textformat/begincharacter"],
                let _bc = String(data: _sd, encoding: .utf8) {
                    _f._cs = _bc
            }
            if let _sd = self["textformat/endcharacter"],
                let _ec = String(data: _sd, encoding: .utf8) {
                _f._ce = _ec
            }
            // color
            if let _sd = self["textformat/colors"],
                let _colorlist = String(data: _sd, encoding: .utf8) {
                for _color in _colorlist.components(separatedBy: .newlines) {
                    // blank
                    guard _color.characters.count > 0 else {
                        continue
                    }
                    // comments
                    guard _color.characters.first != "#" else {
                        continue
                    }
                    let _column = _color.components(separatedBy: .whitespaces)
                    // format: key R G B Alpha comments
                    guard _column.count >= 4 else {
                        continue
                    }
                    let colorKey = _column[0]
                    let R = (_column[1] as NSString).floatValue
                    let G = (_column[2] as NSString).floatValue
                    let B = (_column[3] as NSString).floatValue
                    let Alpha = _column.count == 4 ? 1 : (_column[4] as NSString).floatValue
                    _f.setColor(name: colorKey, color: UIColor(red: CGFloat(R), green: CGFloat(G), blue: CGFloat(B), alpha: CGFloat(Alpha)))
                }
            }
            // font size
            if let _sd = self["textformat/normalfontsize"],
                let _fsz = String(data: _sd, encoding: .utf8) {
                let fontSize = (_fsz as NSString).floatValue
                _f.normalFontSize = CGFloat(fontSize)
            }
            // fonts
            if let _sd = self["textformat/fonts"],
                let _fontlist = String(data: _sd, encoding: .utf8) {
                for _font in _fontlist.components(separatedBy: .newlines) {
                    // blank
                    guard _font.characters.count > 0 else {
                        continue
                    }
                    // comments
                    guard _font.characters.first != "#" else {
                        continue
                    }
                    let _column = _font.components(separatedBy: .whitespaces)
                    // format: key fontName comments
                    guard _column.count >= 2 else {
                        continue
                    }
                    let fontKey = _column[0]
                    // Note: size will be ignored
                    if let font = UIFont(name: _column[1], size: 1) {
                        _f.setFont(name: fontKey, font: font)
                    }
                }
            }
            // defautl format
            if let _sd = self["textformat/defaultformatstring"],
                let _fs = String(data: _sd, encoding: .utf8) {
                _f.defaultFormat = _fs
            }
            
            return _f
        }
    }
    
    /// 加载主题资源包
    ///
    /// Load resourcepackage as theme package
    convenience public init(withTheme theme: String,
                            FromThemePackages respkg: [String : ResourcePackage],
                            withBackwardTheme backward: String = "default") {
        self.init(withCache: true,
                  useTwoStepLocating: true,
                  autoDeviceCustomization: true,
                  useKeyPrefix: true,
                  withPrefix: theme,
                  withPrefixBackward: backward)
        packages = respkg
        _textFormater = themeTextFormater
    }
    
    /// 获取主题文本
    ///
    /// get text from theme
    /// - returns String or nil if key not found or resource cannot be converted to string
    public func getString(_ key: String) -> String? {
        if let _sd = self[key],
            let _string = String(data: _sd, encoding: .utf8) {
            return _string
        } else {
            return nil
        }
    }
    /// 获取格式化主题文本
    ///
    /// get formatted text from theme
    /// - returns NSAttributedString or nil if key not found or resource cannot be converted to string
    public func getFormatedString(_ key: String, formater: TextFormater? = nil) -> NSAttributedString? {
        let _f = formater ?? self._textFormater
        return _f.format(getString(key))
    }
    /// 获取主题图片
    ///
    /// get image from theme
    #if os(iOS)
    public func getImage(_ key: String) -> UIImage? {
        if let _data = self[key],
            let img = UIImage(data: _data) {
            return img
        } else {
            return nil
        }
    }
    #elseif os(OSX)
    public func getImage(_ key: String) -> NSImage? {
        if let _data = self[key],
            let img = NSImage(data: _data) {
            return img
        } else {
            return nil
        }
    }
    #endif
}
