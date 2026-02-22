
import os
import re
import json

def extract_keybindings(file_path):
    keybindings = []
    content = ""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
    except Exception as e:
        return []

    # Regex to find 'keys = { ... }' or 'mappings = { ... }' blocks
    # This is a simplified regex and might miss some complex cases
    # It tries to capture the content between { and }
    pattern = re.compile(r'(?:keys\s*=|mappings\s*=)\s*\{\s*([\s\S]*?)\s*\}', re.MULTILINE)
    matches = pattern.finditer(content)

    for match in matches:
        block_content = match.group(1)
        # Regex to find individual key-value pairs within the block
        # This is also simplified and might need refinement
        # It attempts to capture LHS, RHS, and optional mode/desc
        key_pattern = re.compile(r'\{\s*(["'].*?["']),\s*(.*?)(?:,\s*mode\s*=\s*\{\s*([\s\S]*?)\s*\})?(?:,\s*desc\s*=\s*(["'].*?["']))?\s*\},?', re.MULTILINE)
        inline_key_pattern = re.compile(r'(["'].*?["'])\s*=\s*(.*?)(?:,\s*mode\s*=\s*\{\s*([\s\S]*?)\s*\})?(?:,\s*desc\s*=\s*(["'].*?["']))?,?', re.MULTILINE)


        for k_match in key_pattern.finditer(block_content):
            lhs = k_match.group(1).strip()
            rhs = k_match.group(2).strip()
            mode = k_match.group(3).strip() if k_match.group(3) else "n" # Default to normal mode
            desc = k_match.group(4).strip() if k_match.group(4) else ""
            keybindings.append({
                "file": os.path.basename(file_path),
                "lhs": lhs,
                "rhs": rhs,
                "mode": mode.replace('"', '').replace("'", '').split(','),
                "desc": desc.strip(''"'),
            })

        for ik_match in inline_key_pattern.finditer(block_content):
            lhs = ik_match.group(1).strip()
            rhs = ik_match.group(2).strip()
            mode = ik_match.group(3).strip() if ik_match.group(3) else "n" # Default to normal mode
            desc = ik_match.group(4).strip() if ik_match.group(4) else ""
            keybindings.append({
                "file": os.path.basename(file_path),
                "lhs": lhs,
                "rhs": rhs,
                "mode": mode.replace('"', '').replace("'", '').split(','),
                "desc": desc.strip(''"'),
            })

    return keybindings

def main():
    plugin_dir = "modules/home/programs/neovim/lua/sysinit/plugins/"
    all_keybindings = []
    
    # Read the leader keys from init.lua
    init_lua_path = "modules/home/programs/neovim/init.lua"
    init_lua_content = ""
    try:
        with open(init_lua_path, 'r') as f:
            init_lua_content = f.read()
    except Exception as e:
        print(f"Error reading {init_lua_path}: {e}")
        return

    mapleader_match = re.search(r'vim\.g\.mapleader\s*=\s*(["'])(.*?)\1', init_lua_content)
    maplocalleader_match = re.search(r'vim\.g\.maplocalleader\s*=\s*(["'])(.*?)\1', init_lua_content)

    leader = mapleader_match.group(2) if mapleader_match else " "
    localleader = maplocalleader_match.group(2) if maplocalleader_match else ""
    
    global_vars = {"<leader>": leader, "<localleader>": localleader}

    for root, _, files in os.walk(plugin_dir):
        for file in files:
            if file.endswith(".lua"):
                file_path = os.path.join(root, file)
                keybindings = extract_keybindings(file_path)
                # Replace leader placeholders
                for kb in keybindings:
                    for placeholder, value in global_vars.items():
                        kb['lhs'] = kb['lhs'].replace(placeholder, value)
                        # Remove quotes from the lhs if present from the regex
                        kb['lhs'] = kb['lhs'].strip(''"')
                all_keybindings.extend(keybindings)

    # Sort keybindings by LHS for easier review
    all_keybindings.sort(key=lambda x: x['lhs'])

    with open("extracted_keybindings.json", "w") as f:
        json.dump(all_keybindings, f, indent=2)

if __name__ == "__main__":
    main()
