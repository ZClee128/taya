#!/usr/bin/env python3
"""
Enhanced Swift Code Obfuscation Generator
Generates realistic-looking Swift code to make binary analysis harder
"""

import os
import random
import string
import hashlib
import time

# ============================================
# Realistic Naming Pools
# ============================================

CLASS_PREFIXES = [
    "User", "Network", "Data", "Image", "Cache", "Session", "Auth", 
    "Profile", "Content", "Media", "Storage", "Sync", "Cloud", "Local",
    "Remote", "API", "Database", "Model", "View", "Controller"
]

CLASS_SUFFIXES = [
    "Manager", "Service", "Handler", "Provider", "Controller", "Processor",
    "Coordinator", "Helper", "Utility", "Adapter", "Builder", "Factory",
    "Validator", "Parser", "Mapper", "Repository", "Store"
]

METHOD_VERBS = [
    "fetch", "load", "save", "update", "delete", "process", "validate",
    "parse", "transform", "handle", "configure", "initialize", "prepare",
    "execute", "perform", "manage", "sync", "cache", "clear", "refresh"
]

METHOD_OBJECTS = [
    "User", "Data", "Profile", "Content", "Image", "Token", "Session",
    "Settings", "Preferences", "Cache", "Request", "Response", "Model",
    "Configuration", "State", "Event", "Notification", "Resource"
]

PROPERTY_NAMES = [
    "isActive", "isEnabled", "isLoading", "isValid", "isCached",
    "userId", "sessionId", "timestamp", "expiresAt", "createdAt",
    "cache", "queue", "storage", "configuration", "settings",
    "dataSource", "delegate", "observers", "listeners"
]

# ============================================
# Code Generation Templates
# ============================================

def random_class_name():
    """Generate realistic class name"""
    prefix = random.choice(CLASS_PREFIXES)
    suffix = random.choice(CLASS_SUFFIXES)
    # Sometimes add a qualifier
    if random.random() < 0.3:
        qualifier = random.choice(["Secure", "Fast", "Smart", "Advanced", "Custom"])
        return f"{qualifier}{prefix}{suffix}"
    return f"{prefix}{suffix}"

def random_method_name():
    """Generate realistic method name"""
    verb = random.choice(METHOD_VERBS)
    obj = random.choice(METHOD_OBJECTS)
    # Sometimes add parameters suggestion
    if random.random() < 0.5:
        return f"{verb}{obj}WithCompletion"
    return f"{verb}{obj}"

def random_property_name():
    """Generate realistic property name"""
    return random.choice(PROPERTY_NAMES) + random.choice(["", str(random.randint(1, 9))])

def random_string_literal():
    """Generate random string for literals"""
    words = ["error", "success", "warning", "info", "data", "user", "session", "token", "cache", "sync"]
    return random.choice(words) + "_" + ''.join(random.choices(string.ascii_lowercase, k=6))

# ============================================
# Realistic Code Patterns
# ============================================

def generate_network_service_class():
    """Generate a realistic network service class"""
    class_name = random_class_name()
    
    code = f'''
import Foundation

/// {class_name} handles network operations
class {class_name} {{
    private let baseURL: String
    private var cache: [String: Any] = [:]
    private let session: URLSession
    
    init(baseURL: String = "https://api.example.com") {{
        self.baseURL = baseURL
        self.session = URLSession.shared
    }}
    
    func fetchData(endpoint: String, completion: @escaping (Result<Data, Error>) -> Void) {{
        guard let url = URL(string: baseURL + endpoint) else {{
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }}
        
        session.dataTask(with: url) {{ data, response, error in
            if let error = error {{
                completion(.failure(error))
                return
            }}
            
            if let data = data {{
                completion(.success(data))
            }}
        }}.resume()
    }}
    
    func cacheData(_ data: Any, forKey key: String) {{
        cache[key] = data
    }}
    
    func getCachedData(forKey key: String) -> Any? {{
        return cache[key]
    }}
}}
'''
    return code

def generate_data_manager_class():
    """Generate a data management class"""
    class_name = random_class_name()
    
    code = f'''
import Foundation

/// Manages local data persistence
class {class_name} {{
    private var storage: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.app.data.{random.randint(1000, 9999)}")
    
    func save(_ object: Any, forKey key: String) {{
        queue.async {{
            self.storage[key] = object
            UserDefaults.standard.set(object, forKey: key)
        }}
    }}
    
    func load(forKey key: String) -> Any? {{
        if let cached = storage[key] {{
            return cached
        }}
        return UserDefaults.standard.object(forKey: key)
    }}
    
    func remove(forKey key: String) {{
        queue.async {{
            self.storage.removeValue(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }}
    }}
    
    func clearAll() {{
        queue.async {{
            self.storage.removeAll()
        }}
    }}
}}
'''
    return code

def generate_ui_helper_class():
    """Generate a UI helper class"""
    class_name = random_class_name()
    
    code = f'''
import UIKit

/// Helper for UI operations
class {class_name} {{
    static let shared = {class_name}()
    
    private init() {{}}
    
    func createLabel(text: String, fontSize: CGFloat = 14) -> UILabel {{
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.textColor = .black
        return label
    }}
    
    func createButton(title: String, target: Any?, action: Selector) -> UIButton {{
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }}
    
    func showAlert(title: String, message: String, on viewController: UIViewController) {{
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }}
}}
'''
    return code

def generate_json_parser_class():
    """Generate a JSON parsing class"""
    class_name = random_class_name()
    
    code = f'''
import Foundation

/// Handles JSON parsing operations
class {class_name} {{
    
    func parseJSON<T: Decodable>(_ data: Data, as type: T.Type) -> T? {{
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {{
            return try decoder.decode(type, from: data)
        }} catch {{
            print("JSON parsing error: \\(error)")
            return nil
        }}
    }}
    
    func encodeToJSON<T: Encodable>(_ object: T) -> Data? {{
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {{
            return try encoder.encode(object)
        }} catch {{
            print("JSON encoding error: \\(error)")
            return nil
        }}
    }}
    
    func parseDictionary(_ data: Data) -> [String: Any]? {{
        do {{
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        }} catch {{
            return nil
        }}
    }}
}}
'''
    return code

def generate_validation_class():
    """Generate a validation utility class"""
    class_name = random_class_name()
    
    code = f'''
import Foundation

/// Provides validation utilities
class {class_name} {{
    
    func validateEmail(_ email: String) -> Bool {{
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{{2,64}}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }}
    
    func validateURL(_ urlString: String) -> Bool {{
        guard let url = URL(string: urlString) else {{ return false }}
        return UIApplication.shared.canOpenURL(url)
    }}
    
    func validateLength(_ string: String, min: Int, max: Int) -> Bool {{
        let length = string.count
        return length >= min && length <= max
    }}
    
    func sanitizeInput(_ input: String) -> String {{
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }}
}}
'''
    return code

def generate_cache_manager_class():
    """Generate a cache management class"""
    class_name = random_class_name()
    
    code = f'''
import Foundation

/// Manages in-memory and disk cache
class {class_name} {{
    static let shared = {class_name}()
    
    private var memoryCache: NSCache<NSString, AnyObject> = NSCache()
    private let fileManager = FileManager.default
    private var cacheDirectory: URL?
    
    private init() {{
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 1024 * 1024 * 50 // 50MB
        setupCacheDirectory()
    }}
    
    private func setupCacheDirectory() {{
        if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {{
            cacheDirectory = cacheDir.appendingPathComponent("AppCache")
            try? fileManager.createDirectory(at: cacheDirectory!, withIntermediateDirectories: true)
        }}
    }}
    
    func store(_ object: AnyObject, forKey key: String) {{
        memoryCache.setObject(object, forKey: key as NSString)
    }}
    
    func retrieve(forKey key: String) -> AnyObject? {{
        return memoryCache.object(forKey: key as NSString)
    }}
    
    func clearCache() {{
        memoryCache.removeAllObjects()
        if let cacheDir = cacheDirectory {{
            try? fileManager.removeItem(at: cacheDir)
            setupCacheDirectory()
        }}
    }}
}}
'''
    return code

# ============================================
# Template Selection
# ============================================

CODE_TEMPLATES = [
    generate_network_service_class,
    generate_data_manager_class,
    generate_ui_helper_class,
    generate_json_parser_class,
    generate_validation_class,
    generate_cache_manager_class,
]

def generate_realistic_class():
    """Generate a random realistic class"""
    template = random.choice(CODE_TEMPLATES)
    return template()

# ============================================
# File Generation
# ============================================

def generate_realistic_filename():
    """Generate a realistic filename that doesn't look like junk"""
    prefix = random.choice(CLASS_PREFIXES)
    suffix = random.choice(CLASS_SUFFIXES)
    # Add some randomness but keep it looking professional
    if random.random() < 0.4:
        qualifier = random.choice(["Helper", "Extension", "Utils"])
        return f"{prefix}{suffix}{qualifier}.swift"
    return f"{prefix}{suffix}.swift"

def create_obfuscation_files(target_dir, count=15):
    """Create multiple obfuscation files with realistic code"""
    
    # Ensure target directory exists
    if not os.path.exists(target_dir):
        print(f"Error: Directory {target_dir} does not exist")
        return
    
    created_files = []
    
    for i in range(count):
        filename = generate_realistic_filename()
        filepath = os.path.join(target_dir, filename)
        
        # Avoid overwriting existing important files
        if os.path.exists(filepath):
            timestamp = int(time.time() * 1000) % 10000
            filename = f"{filename[:-6]}_{timestamp}.swift"
            filepath = os.path.join(target_dir, filename)
        
        code = generate_realistic_class()
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(code)
        
        created_files.append(filename)
        print(f"✓ Created: {filename}")
    
    print(f"\n✓ Successfully created {len(created_files)} obfuscation files")
    return created_files

def cleanup_old_junk_files(target_dir):
    """Remove old obvious junk files"""
    patterns = ["Junk*.swift", "Manager*.swift"]
    removed = 0
    
    for pattern in patterns:
        # Use simple glob pattern matching
        for filename in os.listdir(target_dir):
            if filename.startswith("Junk") and filename.endswith(".swift"):
                filepath = os.path.join(target_dir, filename)
                try:
                    os.remove(filepath)
                    print(f"Removed old junk file: {filename}")
                    removed += 1
                except Exception as e:
                    print(f"Failed to remove {filename}: {e}")
    
    if removed > 0:
        print(f"\n✓ Cleaned up {removed} old junk files")
    return removed

# ============================================
# Main Execution
# ============================================

if __name__ == "__main__":
    # Configuration
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    target_dir = os.path.join(project_root, "taya")
    bundle_file = os.path.join(target_dir, "ObfuscationBundle.swift")
    
    print("=" * 60)
    print("Enhanced Swift Obfuscation Generator")
    print("=" * 60)
    print(f"Target directory: {target_dir}")
    print(f"Bundle file: ObfuscationBundle.swift")
    print()
    
    # Step 1: Clean up ONLY old Junk files (safe cleanup)
    print("Step 1: Cleaning up old junk files...")
    cleanup_old_junk_files(target_dir)  # This only removes Junk*.swift files
    print()
    
    # Step 2: Generate obfuscation classes
    print("Step 2: Generating obfuscation code...")
    file_count = random.randint(12, 20)  # Random count each time
    
    generated_classes = []
    for i in range(file_count):
        code = generate_realistic_class()
        generated_classes.append(code)
        print(f"✓ Generated class {i+1}/{file_count}")
    
    # Step 3: Create bundle file
    print()
    print("Step 3: Creating ObfuscationBundle.swift...")
    
    bundle_content = f"""//
//  ObfuscationBundle.swift
//  Auto-generated obfuscation code
//
//  Generated at: {time.strftime('%Y-%m-%d %H:%M:%S')}
//  This file contains realistic-looking code for binary obfuscation
//

import Foundation
import UIKit

// MARK: - Obfuscation Classes
// The following classes are for obfuscation purposes only
// They contain realistic Swift code patterns to make binary analysis harder

"""
    
    # Add all generated classes to the bundle
    for i, class_code in enumerate(generated_classes):
        bundle_content += f"\n// MARK: - Obfuscation Class {i+1}\n"
        bundle_content += class_code
        bundle_content += "\n"
    
    # Write the bundle file
    with open(bundle_file, 'w', encoding='utf-8') as f:
        f.write(bundle_content)
    
    print(f"✓ Created bundle with {file_count} classes")
    print(f"✓ File: {os.path.basename(bundle_file)}")
    print(f"✓ Size: {len(bundle_content)} bytes")
    print()
    
    print("=" * 60)
    print("✓ Obfuscation complete!")
    print("=" * 60)
    print()
    print("IMPORTANT: Add ObfuscationBundle.swift to your Xcode project")
    print("if it's not already included.")


