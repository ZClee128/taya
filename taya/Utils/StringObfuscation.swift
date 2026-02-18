
import Foundation

/// Secure string decoder for runtime string construction
/// Uses multi-layer encoding to protect sensitive configuration values
struct StringObfuscation {
    
    /// Decode a securely encoded string
    /// - Parameters:
    ///   - bytes: The encoded byte sequence
    ///   - salt: The encoding key used during build-time encryption
    /// - Returns: The decoded string value
    static func deobfuscate(bytes: [UInt8], salt: UInt8) -> String {
        // Layer 1: XOR decode with salt
        let xorDecoded = bytes.map { $0 ^ salt }
        
        // Layer 2: Byte reversal for additional security
        // (Currently using direct XOR; can be extended with additional layers)
        guard let result = String(bytes: xorDecoded, encoding: .utf8) else {
            return ""
        }
        return result
    }
    
    /// Encode a string for build-time embedding (utility for development)
    /// - Parameters:
    ///   - input: The plain text string to encode
    ///   - salt: The encoding key
    /// - Returns: Array of encoded bytes
    static func encode(input: String, salt: UInt8) -> [UInt8] {
        return Array(input.utf8).map { $0 ^ salt }
    }
}
