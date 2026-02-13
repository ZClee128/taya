
import Foundation

struct StringObfuscation {
    /// De-obfuscate a string using XOR and a salt
    /// - Parameters:
    ///   - bytes: The encrypted bytes
    ///   - salt: The salt used for XOR
    /// - Returns: The original string
    static func deobfuscate(bytes: [UInt8], salt: UInt8) -> String {
        let decoded = bytes.map { $0 ^ salt }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
}
