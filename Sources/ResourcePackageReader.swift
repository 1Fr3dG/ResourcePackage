//
//  ResourcePackageReader.swift
//
//  Created by Alfred Gao on 2016/10/28.
//
//

import Foundation
import TextFormater
import AVFoundation

#if os(iOS)
    import DeviceKit
#endif

/// 资源文件叠加包，按照优先级返回数据
///
/// Multi-packages, get data by priority (by name)
public class ResourcePackageReader: NSObject {
    public var _logger : (String) -> Void = {_ in }
    
    /// 资源包列表，资源包按照 key 排定优先级
    ///
    /// Package list, priority counted by key of this list
    public var packages: [String : ResourcePackage] = [:]
    
    /// 资源包显示名
    ///
    /// display name of this reader by add names of all packages
    public var resourcePackageFileName: String {
        var _name = ""
        for (key, _) in packages.sorted(by: {$0.0 > $1.0}) {
            _name += "[\(key)] >>> "
        }
        return _name
    }
    
    /// 数据是否缓存
    ///
    /// use memory cache for data
    var _usecache = false
    /// cache
    private var _data = [String : Data]()
    public func cleanCache() {
        _data = [String : Data]()
    }
    
    /// 两段式访问
    ///
    /// use two step locating
    let _twosteplocating: Bool
    
    /// 设备类型 (仅在两段式访问中使用)
    ///
    /// only chack this during 2 step loacting
    #if os(iOS)
        var _devicecustimizable = true
        var _deviceType = ".ipad"
        var _deviceModel = ".ipadmini"
    #elseif os(OSX)
        var _devicecustimizable = false
        var _deviceType = ""
        var _deviceModel = ""
    #endif
    
    /// 语言: 优先使用带有语言后缀的资源
    ///
    /// Language: Resource with lauchage sufix has higher priority
    public var language = ""
    
    public override var description : String {
        var descString = "ResourcePackageReader: [\(resourcePackageFileName)]\n"
        descString += "  Cache: \(_usecache)\n"
        descString += "  Two Step Locating: \(_twosteplocating)\n"
        descString += "  Device Custimizable: \(_devicecustimizable)\n"
        descString += "    Device Type: \(_deviceType)\n"
        descString += "    Device Model: \(_deviceModel)\n"
        descString += "  Language: \(language)\n"
        descString += "  Use Prefix: \(_useprefix)\n"
        descString += "    Prefix: \(_keyprefix)\n"
        descString += "    Backward Prefix: \(_keyprefixbackward)\n"
        
        return descString
    }
    
    /// read data from package
    internal func getData(key: String?, isCacheable: Bool = true) -> Data? {
        guard key != nil else {
            return nil
        }
        _logger("Locating: \(key)")
        // cache
        if let _cachedvalue = _data[key!] {
            _logger("  cache hit: \(key)")
            return _cachedvalue
        }
        // search
        for (_, pkg) in packages.sorted(by: {$0.0 > $1.0}) {
            if let _pkgData = pkg[key!] {
                var _returnData = _pkgData
                _logger("  Found base resource [\(key)] from [\(pkg.resourcePackageFileName)]")
                if _devicecustimizable {
                    if let _typeData = pkg[key! + _deviceType] {
                        _returnData = _typeData
                    }
                    
                    if let _typeData = pkg[key! + _deviceType + language] {
                        _returnData = _typeData
                    }
                    
                    if let _modelData = pkg[key! + _deviceModel] {
                        _returnData = _modelData
                    }
                    
                    if let _modelData = pkg[key! + _deviceModel + language] {
                        _returnData = _modelData
                    }
                } else {
                    if let _locData = pkg[key! + language] {
                        _returnData = _locData
                    }
                }
                
                
                if _twosteplocating {
                    let _pointText = String(data: _returnData, encoding: String.Encoding.utf8)!
                    var _pointer = String(_pointText.characters.filter { !"\n\r".characters.contains($0) })
                    if _pointer.hasPrefix("/") {
                        _pointer.remove(at: _pointer.startIndex)
                        _logger("    Inline Text: [\(_pointer)]")
                        let value = _pointer.data(using: String.Encoding.utf8)
                        if _usecache && isCacheable {
                            _data[key!] = value
                        }
                        return value
                    } else {
                        _logger("    Resource: [\(_pointer)]")
                        for (_, vpkg) in packages.sorted(by: {$0.0 > $1.0}) {
                            if let value = vpkg[_pointer] {
                                _logger("  Found @[\(vpkg.resourcePackageFileName)] for [\(key)]")
                                if _usecache && isCacheable {
                                    _data[key!] = value
                                }
                                return value
                            }
                        }
                        _logger("  Cannot locate resource pointed by [\(_pointer)]")
                        return nil
                    }
                } else {
                    // false == _twosteploacting
                    if _usecache && isCacheable {
                        _data[key!] = _returnData
                    }
                    return _returnData
                }
            }
            _logger("Cannot locate key [\(key)]")
        }
        return nil
    }
    
    /// 资源 key 前缀
    ///
    /// prefix of key
    /// when use folder name as prefilx, must include the end slash "/"
    var _useprefix = false
    var _keyprefix = ""
    var _keyprefixbackward = ""
    
    /// 获取数据
    ///
    /// get resource data
    public subscript(key: String) -> Data? {
        get {
            if !_useprefix {
                return getData(key: key)
            } else {
                if let _value = getData(key: _keyprefix + "/" + key) {
                    return _value
                } else {
                    return getData(key: _keyprefixbackward + "/" + key)
                }
            }
        }
    }
    
    public init(
        withCache: Bool = false,
        useTwoStepLocating: Bool = false,
        autoDeviceCustomization: Bool = false,
        useKeyPrefix: Bool = false,
        withPrefix: String = "",
        withPrefixBackward: String = "") {
        
        _usecache = withCache
        _twosteplocating = useTwoStepLocating
        _devicecustimizable = autoDeviceCustomization
        _useprefix = useKeyPrefix
        _keyprefix = withPrefix
        _keyprefixbackward = withPrefixBackward
        
        #if os(iOS)
            if Device().isPad {
                _deviceType = ".ipad"
            } else if Device().isPhone {
                _deviceType = ".iphone"
            } else if Device().isPod {
                _deviceType = ".iphone"
            }
            
            let _modeltext = "." + Device().description.replacingOccurrences(of: "Simulator (", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "").lowercased()
            _deviceModel = _modeltext
        #endif
        
        super.init()
    }
    
    deinit {
        for (_, soundid) in sounds {
            AudioServicesDisposeSystemSoundID(soundid)
        }
    }
    
    /// used by sounds extension
    var musicPlayer : AVAudioPlayer?
    var sounds: [String : SystemSoundID] = [:]
    
}
