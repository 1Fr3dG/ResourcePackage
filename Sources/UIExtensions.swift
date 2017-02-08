//
//  UIExtensions.swift
//
//  Created by Alfred Gao on 2017/1/6.
//
//

//  This is using package as theme and providing extensions for UIClasses

#if os(iOS)
    import UIKit
    import TextFormater
    
    extension UIButton {
        
        /// 设置主题参数
        ///
        /// Config UIButton with theme
        ///
        /// - parameter reader: ResourcePackageReader which includes the theme
        /// - parameter key: key for the UIView
        /// - parameter formater: TextFormater for texts, `nil` will use theme default setting
        public func loadTheme(from reader: ResourcePackageReader, key: String, with formater: TextFormater? = nil) {
            
            let textFormater = formater ?? reader.themeTextFormater
            
            self.layoutIfNeeded()
            let _width = self.bounds.size.width
            let _height = self.bounds.size.height
            
            for (_sname, _state) in [
                (key, UIControlState.normal),
                (key + ".disabled", UIControlState.disabled),
                (key + ".highlighted", UIControlState.highlighted),
                (key + ".selected", UIControlState.selected),
                (key + ".focused", UIControlState.focused),
                ] {
                    setAttributedTitle(textFormater.format(reader.getString(_sname + ".title"), imgWidth: _width, imgHeight: _height), for: _state)
                    setImage(reader.getImage(_sname + ".image"), for: _state)
                    setBackgroundImage(reader.getImage(_sname + ".bgimg"), for: _state)
            }
            
        }
        
    }
    
    
    extension UILabel {
        
        /// 设置主题参数
        ///
        /// Config UILabel text with theme
        ///
        /// - parameter reader: ResourcePackageReader which includes the theme
        /// - parameter key: key for the UIView
        /// - parameter formater: TextFormater for texts, `nil` will use theme default setting
        public func setText(from reader: ResourcePackageReader, key: String, with formater: TextFormater? = nil) {
            
            let textFormater = formater ?? reader.themeTextFormater
            
            self.layoutIfNeeded()
            let _width = self.bounds.size.width
            let _height = self.bounds.size.height
            
            attributedText = textFormater.format(reader.getString(key), imgWidth: _width, imgHeight: _height)
            
        }
    }
    
    
    extension UIImageView {
        
        /// 设置主题参数
        ///
        /// Config UILabel text with theme
        ///
        /// - parameter reader: ResourcePackageReader which includes the theme
        /// - parameter key: key for the UIView
        public func setImage(from reader: ResourcePackageReader, key: String) {
            
            image = reader.getImage(key)
            highlightedImage = reader.getImage(key + ".highlighted")
            
        }
        
    }
    
    
    
#endif
