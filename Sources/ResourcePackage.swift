//
//  ResourcePackage.swift
//
//  Created by Alfred Gao on 2016/10/28.
//  Copyright © 2016年 Alfred Gao. All rights reserved.
//

import Foundation
import SimpleEncrypter

/// 资源文件管理
///
/// Manage one packagefile
public class ResourcePackage: NSObject {
    static public var _logger : (String) -> Void = {_ in }
    let resourcePackageFileName: String
    private var resourcefile: Data
    private var resourcelist: [String : [Int]]
    
    private var isWritable: Bool
    
    /// 加密方法
    ///
    /// SimpleEncrypter instence for entryption
    private let cypherDeligate: SimpleEncrypter
    /// 压缩方法
    ///
    /// SimpleEncrypter instence for compress
    private let compressDeligate: SimpleEncrypter
    
    private func encode(_ _data: Data) -> Data {
        return cypherDeligate.encrypt(compressDeligate.encrypt(_data))
    }
    private func decode(_ _data: Data) -> Data {
        return compressDeligate.decrypt(cypherDeligate.decrypt(_data))
    }
    
    /// 打开文件准备读取
    ///
    /// Open file for reading
    required public init?(with file: String,
                          encrypter: SimpleEncrypter = EncrypterXor(with: "passw0rdpassw0rd"),
                          compressor: SimpleEncrypter = EncrypterCompress(with: "lzfse")) {
        cypherDeligate = encrypter
        compressDeligate = compressor
        
        ResourcePackage._logger("Loading resource file: \(file) ...")
        isWritable = false
        
        do {
            // open file
            try resourcefile = Data(contentsOf: URL(fileURLWithPath: file), options: Data.ReadingOptions.alwaysMapped)
            resourcePackageFileName = file
            ResourcePackage._logger("  Resource file [\(file)] loading succeed")
        } catch {
            ResourcePackage._logger("  ERROR: Resource file [\(file)] loading failed")
            return nil
        }
        
        // file length should > sum of keys
        guard resourcefile.count > 40 else {
            let _fileLength = resourcefile.count
            ResourcePackage._logger("  ERROR: Resource file [\(file)] format incorrect: File length [\(_fileLength)] to small")
            return nil
        }
        
        // signature == RSPK
        guard resourcefile.subdata(in: 0..<4) == Data(bytes: [82, 83, 80, 75]) else {
            let _signature = resourcefile.subdata(in: 0..<4)
            ResourcePackage._logger("  ERROR: Resource file [\(file)] format incorrect: Illegal signature: \(_signature.toHexString())")
            return nil
        }
        
        // double check resource list address
        guard resourcefile.subdata(in: 8..<16) == resourcefile.subdata(in: resourcefile.count-24..<resourcefile.count-16) else {
            ResourcePackage._logger("  ERROR: Resource file [\(file)] format incorrect: Index address incorrect")
            return nil
        }
        
        // load resource list
        let resourcelistAddress: Int32 = resourcefile.subdata(in: 8..<12).withUnsafeBytes { $0.pointee }
        let resourcelistEnd: Int32 = resourcefile.subdata(in: 12..<16).withUnsafeBytes { $0.pointee }
        
        ResourcePackage._logger("-> Resource list loaded: \(file) [\(resourcelistAddress) - \(resourcelistEnd)]")
        let resourcelistRange: Range<Data.Index> = Int(resourcelistAddress) ..< Int(resourcelistEnd)
        let listdata = compressDeligate.decrypt(cypherDeligate.decrypt(resourcefile.subdata(in: resourcelistRange)))
        resourcelist = NSKeyedUnarchiver.unarchiveObject(with: listdata) as! [String : [Int]]
        
        guard resourcelist.count > 0 else {
            ResourcePackage._logger("  ERROR: Resource file \(file) has no resource")
            return nil
        }
        let _resourceCount = resourcelist.count
        ResourcePackage._logger("-> Resource file \(file) has \(_resourceCount) resources")
    }
    
    /// 创建空文件准备写入
    ///
    /// Create new file for writing
    required public init?(to file: String,
                          encrypter: SimpleEncrypter = EncrypterXor(with: "passw0rdpassw0rd"),
                          compressor: SimpleEncrypter = EncrypterCompress(with: "lzfse")) {
        cypherDeligate = encrypter
        compressDeligate = compressor
        ResourcePackage._logger("Creating resource package file: \(file) ...")
        isWritable = true
        
        let fileManager = FileManager.default
        // 文件已存在 - file exists
        guard !fileManager.fileExists(atPath: file) else {
            ResourcePackage._logger("  ERROR: File \(file) exists")
            return nil
        }
        resourcePackageFileName = file
        
        // 构造空文件 - build structure
        resourcefile = Data(bytes: [82, 83, 80, 75])    // RSPK
        resourcefile.append(Data(bytes: [0, 2, 0, 0]))  // Version
        resourcefile.append(Data(count: 8)) // space for resourcelist pointer
        
        let _info: [String: Any] = [ "Compressor" : compressDeligate.description,
                                     "Encrypter" : cypherDeligate.description]
        let infoData = NSKeyedArchiver.archivedData(withRootObject: _info)
        resourcefile.append(infoData)
        
        let _pkgShortName = URL(fileURLWithPath: resourcePackageFileName).lastPathComponent
        let pkgName = NSKeyedArchiver.archivedData(withRootObject: _pkgShortName.data(using: .utf8)!)
        let encodedName = cypherDeligate.encrypt(compressDeligate.encrypt(pkgName))
        resourcefile.append(encodedName)
        resourcelist = ["_packageName": [16,16+encodedName.count]]
        
        // 尝试写入文件 - try create real file
        do {
            try resourcefile.write(to: URL(fileURLWithPath: file))
            ResourcePackage._logger("  Resource file \(file) created")
        } catch {
            ResourcePackage._logger("  ERROR: File \(file) is not writable")
            return nil
        }
    }
    
    /// 生成文件尾部数据并存储到磁盘
    ///
    /// Generate tail structure
    public func save() -> Bool {
        ResourcePackage._logger("  Creating tail structure for: \(self.resourcePackageFileName)")
        guard isWritable else {
            ResourcePackage._logger("ERROR: ReWrite is not allowed")
            return false
        }
        isWritable = false  // 只允许一次写入
        
        // 附加目录信息 - index
        var resourcelistAddress = Int32(resourcefile.count)
        resourcefile.append(encode(NSKeyedArchiver.archivedData(withRootObject: resourcelist)))
        var resourcelistEnd = Int32(resourcefile.count)
        ResourcePackage._logger("  Package includes \(resourcelist.count) resources, index structure uses \((resourcelistEnd - resourcelistAddress)/1024)KB")
        // count index pointer & md5
        resourcefile.append(Data(bytes: &resourcelistAddress, count: 4))
        resourcefile.append(Data(bytes: &resourcelistEnd, count: 4))
        resourcefile.replaceSubrange(8..<16, with: resourcefile.subdata(in: resourcefile.count-8..<resourcefile.count))
        let md5 = resourcefile.md5()
        ResourcePackage._logger("  MD5: \(md5.toHexString())")
        resourcefile.append(md5)
        
        // 尝试写入文件 - try write file
        do {
            try resourcefile.write(to: URL(fileURLWithPath: resourcePackageFileName))
            ResourcePackage._logger("  \(resourcelist.count) resources packaged to: \(resourcePackageFileName)")
            return true
        } catch {
            ResourcePackage._logger("  ERROR: File \(resourcePackageFileName) is not writable")
            return false
        }
    }
    
    /// 数据读取
    ///
    /// Read resource
    public subscript(key: String) -> Data? {
        get {
            var _key = key
            while _key.lengthOfBytes(using: .utf8) > 0 && _key[..<_key.index(after: _key.startIndex)] == "/" {
                _key.remove(at: _key.startIndex)
            }
            ResourcePackage._logger("Locating resource: [\(resourcePackageFileName)].[\(_key)]")
            if let _range = resourcelist[_key] {
                return NSKeyedUnarchiver.unarchiveObject(with: decode(resourcefile.subdata(in: _range[0]..<_range[1]))) as! Data?
            } else {
                return nil
            }
        }
    }
    
    /// 数据列表
    ///
    /// List of resources
    public var ResourceList: [String] {
        get {
            return [String](resourcelist.keys).sorted()
        }
    }
    
    /// 追加数据
    ///
    /// Append resource
    public func append(with key: String, value: Data) -> Bool {
        var _key = key
        while _key.lengthOfBytes(using: .utf8) > 0 && _key[..<_key.index(after: _key.startIndex)] == "/" {
            _key.remove(at: _key.startIndex)
        }
        guard isWritable else {
            ResourcePackage._logger("ERROR: Package in readonly mode")
            return false
        }
        
        if resourcelist[_key] != nil {
            ResourcePackage._logger("ERROR: Duplicated key [\(_key)]")
            return false
        }
        
        let _oldfiletail = resourcefile.count
        resourcefile.append(encode(NSKeyedArchiver.archivedData(withRootObject: value)))
        let _newfiletail = resourcefile.count
        
        resourcelist[_key] = [_oldfiletail,_newfiletail]
        return true
    }
}
