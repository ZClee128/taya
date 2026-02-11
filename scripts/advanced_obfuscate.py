
import os
import random
import string

def random_string(length=10):
    return ''.join(random.choices(string.ascii_letters, k=length))

def random_int():
    return random.randint(100, 9999)

def generate_junk_code_swift():
    class_name = "Manager" + random_string(5)
    methods = []
    for _ in range(random.randint(3, 7)):
        method_name = "process" + random_string(5)
        var_name = "var" + random_string(3)
        operation = random.choice(["+", "-", "*"])
        methods.append(f"""
    func {method_name}() {{
        let {var_name} = {random_int()} {operation} {random_int()}
        print("{var_name} result: \({var_name})")
    }}
""")
    
    code = f"""
// Junk Code Generated
import Foundation

class {class_name} {{
    var id: String = "{random_string()}"
    
    {''.join(methods)}
}}
"""
    return code

def inject_junk_to_files(root_dir):
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(".swift") and "AppConfig" not in filename and "AppWebViewController" not in filename:
                # randomly inject extension
                if random.random() < 0.1: # 10% chance
                    filepath = os.path.join(dirpath, filename)
                    with open(filepath, "r+") as f:
                        content = f.read()
                        if "class " in content:
                            class_name_match = content.split("class ")[1].split(":")[0].strip().split("{")[0].strip()
                            junk_method = f"""
    // Injected Junk
    func {random_string(8)}() -> Int {{
        let x = {random_int()}
        let y = {random_int()}
        return x + y
    }}
"""
                            # This is a bit risky doing simple string append, better to append extension at end
                            extension_code = f"""
// MARK: - Extension {class_name_match} Junk
extension {class_name_match} {{
    func {random_string(8)}_junk() {{
        print("{random_string(20)}")
    }}
}}
"""
                            if extension_code not in content:
                                f.write(extension_code)
                                print(f"Injected extension to {filepath}")

def create_junk_files(output_dir, count=5):
    for i in range(count):
        filename = f"Junk{random_string(5)}.swift"
        filepath = os.path.join(output_dir, filename)
        with open(filepath, "w") as f:
            f.write(generate_junk_code_swift())
        print(f"Created junk file: {filepath}")

if __name__ == "__main__":
    target_dir = os.path.join(os.getcwd(), "taya")
    # inject_junk_to_files(target_dir) # Disabled for now to be safe, enabling only file creation
    create_junk_files(target_dir, count=10)
