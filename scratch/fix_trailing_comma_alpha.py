import os
import re

# This regex finds the broken pattern: .withAlpha(((VALUE,) * 255).toInt())
# It handles both single line and multi-line cases.
# Pattern matches .withAlpha( followed by any number of ( and then a VALUE followed by a comma
regex = r"\.withAlpha\(\(+\s*([^,]+),\s*\*\s*255\)\.toInt\(\)\)+"

def fix_broken_alpha(match):
    value = match.group(1).strip()
    # Return a clean version: .withAlpha((VALUE * 255).toInt())
    # Note: we use double parens just to be safe with expressions
    return f".withAlpha(({value} * 255).toInt())"

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # First, fix the specific comma-before-star error
                # We use re.DOTALL to match across lines
                new_content = re.sub(r"\.withAlpha\(\(+\s*([^,]+),\s*\n?\s*\*?\s*255\)\.toInt\(\)\)+", 
                                     lambda m: f".withAlpha(({m.group(1).strip()} * 255).toInt())", 
                                     content, flags=re.MULTILINE)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed broken alpha in {path}")
            except Exception as e:
                print(f"Error processing {path}: {e}")
