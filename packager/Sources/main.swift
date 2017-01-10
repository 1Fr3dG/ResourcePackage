import Foundation
import ResourcePackage
import SimpleEncrypter

import CommandLineKit
import Rainbow

let versionString = "Ver 0.2.0\n"
let _usageTitle = "Usage: packager operation <packageName> [path|resource] [options]\n\n".bold
let _usageOperations = "  " + "operation: create|list|extract \n".green.bold.underline +
    "    " + "packager create <packageName> <path> [options] \n".blue +
    "    " + "packager list <packageName> [options] \n".blue +
    "    " + "packager extract <packageName> <resourceName> [options] \n".blue
let _usageOptions =  "\n  " + "options:".green.bold.underline
let usageString = _usageTitle + _usageOperations + _usageOptions

print("Resource packager")
print(versionString)

let cli = CommandLineKit.CommandLine()

let compress : StringOption
if #available(iOS 9.0, OSX 10.11, watchOS 2.0, tvOS 9.0, *) {
    compress = StringOption(longFlag: "compress", required: false,
                            helpMessage: "Algorithm for compress - none/lz4/lzma/zlib/lzfse/gzip")
}
else {
    compress = StringOption(longFlag: "compress", required: false,
                            helpMessage: "Algorithm for compress - none/lz4/lzma/zlib/lzfse/gzip" + "\n" + "This version support only none & gzip".blink)
}
let encrypt = StringOption(longFlag: "encrypt", required: false,
                            helpMessage: "Algorithm for encryption - none/xor/aes")
let password = StringOption(longFlag: "password", required: false,
                           helpMessage: "Password for encryption")

let help = BoolOption(shortFlag: "h", longFlag: "help",
                      helpMessage: "Prints a help message.")
let verbosity = CounterOption(shortFlag: "v", longFlag: "verbose",
                              helpMessage: "Print verbose messages.")


cli.addOptions(compress, encrypt, password, verbosity)

// format help message
cli.formatOutput = { s, type in
    var str: String
    switch(type) {
    case .about:
        str = usageString
    case .error:
        str = s.red.bold
    case .optionFlag:
        str = s.green.underline
    case .optionHelp:
        str = s.blue
    }
    
    return cli.defaultFormat(s: str, type: type)
}

// parse command line
do {
    try cli.parse()
} catch {
    cli.printUsage()
    exit(EX_USAGE)
}

guard cli.unparsedArguments.count >= 2 else {
    cli.printUsage()
    exit(EX_USAGE)
}

// compress & encrypt parameter
var _compress: SimpleEncrypter = EncrypterNone(with: "")
var _encrypt: SimpleEncrypter = EncrypterNone(with: "")
var _password = ""

if compress.value != nil {
    print("Building compressor...".green)
    switch compress.value!.lowercased() {
    case "none":
        print("  Use ".green + "EncrypterNone".blue)
        _compress = EncrypterNone(with: "")
    case "gzip":
        print("  Use ".green + "EncrypterCompress(with: gzip)".blue)
        _compress = EncrypterCompress(with: "gzip")
    case "lz4":
        print("  Use ".green + "EncrypterCompress(with: lz4)".blue)
        _compress = EncrypterCompress(with: "lz4")
    case "lzma":
        print("  Use ".green + "EncrypterCompress(with: lzma)".blue)
        _compress = EncrypterCompress(with: "lzma")
    case "zlib":
        print("  Use ".green + "EncrypterCompress(with: zlib)".blue)
        _compress = EncrypterCompress(with: "zlib")
    case "lzfse":
        print("  Use ".green + "EncrypterCompress(with: lzfse)".blue)
        _compress = EncrypterCompress(with: "lzfse")
    default:
        print("  " + compress.value!.blue.bold.onYellow + " is not available, use ".red + "EncrypterNone".green.blink)
        _compress = EncrypterNone(with: "")
    }
    if #available(iOS 9.0, OSX 10.11, watchOS 2.0, tvOS 9.0, *) {
        
    } else {
        if compress.value!.lowercased() != "none" && compress.value!.lowercased() != "gzip" {
            print("This version support only none & gzip".blink)
            print("Force using gzip".blink)
            _compress = EncrypterCompress(with: "gzip")
        }
    }
}

if password.value != nil {
    _password = password.value!
}

if encrypt.value != nil {
    print("Building encrypter...".green)
    switch encrypt.value!.lowercased() {
    case "none":
        print("  Use ".green + "EncrypterNone".blue)
        _encrypt = EncrypterNone(with: "")
    case "xor":
        print("  Use ".green + "EncrypterXor".blue + " with key " + _password.green)
        _encrypt = EncrypterNone(with: _password)
    case "aes":
        print("  Use ".green + "EncrypterAES".blue + " with key " + _password.green)
        _encrypt = EncrypterNone(with: _password)
    default:
        print("  " + encrypt.value!.blue.bold.onYellow + " is not available, use ".red + "EncrypterNone".green.blink)
        _encrypt = EncrypterNone(with: "")
    }
}

// begin task
print("Begin".bold)
let fileManager = FileManager.default

// check operation
switch cli.unparsedArguments[0].lowercased() {
case "c", "create" :
    
    guard cli.unparsedArguments.count >= 3 else {
        print("Creation of package require a path parameter of resources".red.bold)
        exit(EX_USAGE)
    }
    // check path
    if !fileManager.fileExists(atPath: cli.unparsedArguments[2]) {
        print("ERROR: ".red.bold + "Resource path ".red + "\(cli.unparsedArguments[2])".red.bold.onYellow + " doesn't exists.".red)
        exit(EX_USAGE)
    }
    // check package
    if fileManager.fileExists(atPath: cli.unparsedArguments[1]) {
        print("ERROR: ".red.bold + "Package file ".red + "\(cli.unparsedArguments[2])".red.bold.onYellow + " already exists".red)
        exit(EX_CANTCREAT)
    }
    
    
    // creating package file
    let path = cli.unparsedArguments[2]
    print("  Begin creating package".green)
    if let pkg = ResourcePackage(to: cli.unparsedArguments[1]) {
        for file in fileManager.enumerator(atPath: path)! {
            let fullpath = path + "/" + (file as! String)
            if verbosity.value > 0 {
                print("    Appending ".green + "\(fullpath)".blue.onYellow)
            }
            if let _data = try? Data(contentsOf: URL(fileURLWithPath: fullpath)) {
                _ = pkg.append(with: file as! String, value: _data)
            }
        }
        if pkg.save() {
            print("  Package saved".green)
        } else {
            print("ERROR: Package saving failed".red.bold.blink)
        }
    }
    
case "l", "list" :
    // check package parameter
    if !fileManager.fileExists(atPath: cli.unparsedArguments[1]) {
        print("ERROR: ".red.bold + "Package file ".red + "\(cli.unparsedArguments[1])".red.bold.onYellow + " not exists.".red)
        exit(EX_OSFILE)
    }
    
    // reading package
    print("  Loading package file".green)
    if let pkg = ResourcePackage(with: cli.unparsedArguments[1]) {
        print("  Package ".green + "\(cli.unparsedArguments[1])".blue.onYellow + " contents ".green + "\(pkg.ResourceList.count)".red.onYellow + " resources".green)
        for _res in pkg.ResourceList {
            print("    " + "\(_res)".green)
        }
    } else {
        print("ERROR: Cannot open package".red.bold.blink)
        exit(EX_DATAERR)
    }
    
case "x", "extract" :
    guard cli.unparsedArguments.count >= 3 else {
        print("Resource name required for extracting from package.".red.bold)
        exit(EX_USAGE)
    }
    
    // check package parameter
    if !fileManager.fileExists(atPath: cli.unparsedArguments[1]) {
        print("ERROR: ".red.bold + "Package file ".red + "\(cli.unparsedArguments[1])".red.bold.onYellow + " not exists.".red)
        exit(EX_OSFILE)
    }
    // reading package
    print("  Loading package file".green)
    if let pkg = ResourcePackage(with: cli.unparsedArguments[1]) {
        // resource
        if let _res = pkg[cli.unparsedArguments[2]] {
            print("  Resource ".green + "\(cli.unparsedArguments[2])".blue.onYellow + " has ".green + "\(_res.count)".red.onYellow + " bytes".green)
            print("⬇︎⬇︎⬇︎⬇︎⬇︎ ⬇︎⬇︎⬇︎⬇︎⬇︎".green.blink)
            if let _text = String(data:_res, encoding: String.Encoding.utf8) {
                print(_text)
                //print(String(data:_res as! Data, encoding: String.Encoding.utf8))
            } else {
                switch verbosity.value {
                case 0:
                    print(_res.subdata(in:0..<16).toHexString())
                case 1:
                    for i in 0..<16 {
                        print("\(i)".bold, terminator: "\t")
                        for j in 0..<4 {
                            print(_res.subdata(in:i*16+j*4..<i*16+j*4+4).toHexString().blue, terminator: " ")
                        }
                        print()
                    }
                default:
                    print(_res.toHexString())
                }
            }
            print("⬆︎⬆︎⬆︎⬆︎⬆︎ ⬆︎⬆︎⬆︎⬆︎⬆︎".green.blink)
        } else {
            print("  Resource not exists.".red)
        }
    } else {
        print("ERROR: Cannot open package".red.bold.blink)
        exit(EX_DATAERR)
    }
    
default:
    cli.printUsage()
    exit(EX_USAGE)
}
