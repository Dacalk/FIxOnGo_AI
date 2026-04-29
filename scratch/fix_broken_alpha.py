import os
import re

# This regex targets the broken pattern: .withAlpha((SOMETHING * 255).toInt())
# and changes it to: .withAlpha(((SOMETHING) * 255).toInt())
regex = r"\.withAlpha\(\(([^)]+\?[^)]+)\s\*\s255\)\.toInt\(\)\)"

def fix_alpha(match):
    expression = match.group(1).strip()
    return f".withAlpha((({expression}) * 255).toInt())"

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = re.sub(regex, fix_alpha, content)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed alpha in {path}")
            except Exception as e:
                print(f"Error processing {path}: {e}")
