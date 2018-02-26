import Foundation
import ResourcePackage
import SimpleEncrypter

import CommandLineKit
import Rainbow

let versionString = "Ver 1.4.0\n"
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

let compress = StringOption(longFlag: "compress", required: false,
                            helpMessage: "Algorithm for compress - none/lzfse/lz4/lzma")
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

if verbosity.value > 0 {
    ResourcePackage._logger = {str in print("PKG=> ".blue.onYellow + str)}
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
    case "lz4":
        print("  Use ".green + "EncrypterCompress(with: lz4)".blue)
        _compress = EncrypterCompress(with: "lz4")
    case "lzma":
        print("  Use ".green + "EncrypterCompress(with: lzma)".blue)
        _compress = EncrypterCompress(with: "lzma")
    case "lzfse":
        print("  Use ".green + "EncrypterCompress(with: lzfse)".blue)
        _compress = EncrypterCompress(with: "lzfse")
    default:
        print("  " + compress.value!.blue.bold.onYellow + " is not available, use ".red + "EncrypterNone".green.blink)
        _compress = EncrypterNone(with: "")
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
        _encrypt = EncrypterXor(with: _password)
    case "aes":
        print("  Use ".green + "EncrypterAES".blue + " with key " + _password.green)
        _encrypt = EncrypterAES(with: _password)
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
        print("ERROR: ".red.bold + "Package file ".red + "\(cli.unparsedArguments[1])".red.bold.onYellow + " already exists".red)
        exit(EX_CANTCREAT)
    }
    
    
    // creating package file
    let path = cli.unparsedArguments[2]
    print("  Begin creating package".green)
    if let pkg = ResourcePackage(to: cli.unparsedArguments[1], encrypter: _encrypt, compressor: _compress) {
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
    if let pkg = ResourcePackage(with: cli.unparsedArguments[1], encrypter: _encrypt, compressor: _compress) {
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
    if let pkg = ResourcePackage(with: cli.unparsedArguments[1], encrypter: _encrypt, compressor: _compress) {
        // resource
        if let _res = pkg[cli.unparsedArguments[2]] {
            print("  Resource ".green + "\(cli.unparsedArguments[2])".blue.onYellow + " has ".green + "\(_res.count)".red.onYellow + " bytes".green)
            print("⬇︎⬇︎⬇︎⬇︎⬇︎ ⬇︎⬇︎⬇︎⬇︎⬇︎".green.blink)
            if let _text = String(data:_res, encoding: String.Encoding.utf8) {
                switch verbosity.value {
                case 0:
                    print(_text.substring(to: _text.index(_text.startIndex, offsetBy: 32, limitedBy: _text.endIndex) ?? _text.endIndex))
                default:
                    print(_text)
                }
            } else {
                switch verbosity.value {
                case 0:
                    let _outputLength = _res.count > 16 ? 16 : _res.count
                    print(_res.subdata(in:0..<_outputLength).toHexString())
                case 1:
                    let _output = _res.subdata(in: 0..<(_res.count > 256 ? 256 : _res.count))
                    var _tmpascii = ""
                    print("--\t00010203 04050607 08090A0B 0C0D0E0F".bold)
                    for i in 0..<_output.count {
                        if i % 16 == 0 {
                            print(String(format:"%02X", i / 16).bold, terminator: "\t")
                        }
                        
                        print(String(format:"%02X", _output[i]).blue, terminator: "")
                        
                        if (i + 1) % 4 == 0 {
                            print(" ", terminator: "")
                        }
                        
                        if _output[i] >= 32 && _output[i] <= 127 {
                            _tmpascii.append(Character(UnicodeScalar(_output[i])))
                        } else {
                            _tmpascii.append(" ")
                        }
                        
                        if (i + 1) % 16 == 0 {
                            print("\t" + _tmpascii.green.onBlue)
                            _tmpascii = ""
                        }
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
