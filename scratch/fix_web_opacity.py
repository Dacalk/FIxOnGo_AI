import os
import re

def replace_opacity(content):
    # Replace .withOpacity(0.X) with .withAlpha((0.X * 255).toInt())
    # Handle both double literals and variables
    def sub_func(match):
        val = match.group(1)
        try:
            # If it's a number, calculate the alpha immediately to keep it clean
            alpha = int(float(val) * 255)
            return f'.withAlpha({alpha})'
        except ValueError:
            # If it's a variable, use the formula
            return f'.withAlpha(({val} * 255).toInt())'

    content = re.sub(r'\.withOpacity\(([^)]+)\)', sub_func, content)
    return content

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = replace_opacity(content)
                
                if new_content != content:
                    print(f"Updating {path}")
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)

if __name__ == '__main__':
    main()
