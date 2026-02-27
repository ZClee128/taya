import Foundation

/// Utility for decoding protected configuration strings at runtime.
/// Applies XOR cipher to reconstruct sensitive values from encoded byte arrays.
enum StringCipher {

    /// Decodes an encoded byte sequence using XOR with the provided key.
    /// - Parameters:
    ///   - data: Encoded byte array
    ///   - key: XOR key used during encoding
    /// - Returns: Decoded UTF-8 string, or empty string on failure
    static func decode(data: [UInt8], key: UInt8) -> String {
        let decoded = data.map { $0 ^ key }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }

    /// Encodes a plain text string into an XOR-protected byte array.
    /// Used at development time to generate encoded constants.
    /// - Parameters:
    ///   - text: Plain text to encode
    ///   - key: XOR key for encoding
    /// - Returns: Encoded byte array
    static func encode(text: String, key: UInt8) -> [UInt8] {
        return Array(text.utf8).map { $0 ^ key }
    }
}

// MARK: - Legacy Compatibility

/// Maintains backward compatibility with existing encoded values throughout the project.
/// Routes all calls to `StringCipher` internally.
struct StringObfuscation {
    static func deobfuscate(bytes: [UInt8], salt: UInt8) -> String {
        return StringCipher.decode(data: bytes, key: salt)
    }

    static func encode(input: String, salt: UInt8) -> [UInt8] {
        return StringCipher.encode(text: input, key: salt)
    }
}
