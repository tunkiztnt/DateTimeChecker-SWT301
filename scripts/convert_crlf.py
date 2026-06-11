import os

def convert_to_crlf(directory):
    for root, dirs, files in os.walk(directory):
        # Skip node_modules and .git
        if 'node_modules' in root or '.git' in root:
            continue
        for file in files:
            if file.endswith('.bat'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'rb') as f:
                        content = f.read()
                    
                    # Replace LF with CRLF (avoiding double CR)
                    # Normalizing to LF first, then replacing LF with CRLF
                    normalized = content.replace(b'\r\n', b'\n')
                    crlf_content = normalized.replace(b'\n', b'\r\n')
                    
                    if content != crlf_content:
                        with open(file_path, 'wb') as f:
                            f.write(crlf_content)
                        print(f"Converted to CRLF: {file_path}")
                except Exception as e:
                    print(f"Error converting {file_path}: {e}")

if __name__ == "__main__":
    convert_to_crlf(".")
