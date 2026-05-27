import glob
import re

def fix_gap():
    files = glob.glob('templates/*.html')
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            
        # Desktop gap
        content = content.replace('.brand { display: flex; align-items: center; gap: 12px; text-decoration: none; }', 
                                  '.brand { display: flex; align-items: center; gap: 4px; text-decoration: none; }')
        
        # In case some have gap: 10px or 15px
        content = re.sub(r'\.brand \{ display: flex; align-items: center; gap: \d+px; text-decoration: none; \}', 
                         '.brand { display: flex; align-items: center; gap: 4px; text-decoration: none; }', content)
                         
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
            
    print("Brand gap updated in all files.")

if __name__ == '__main__':
    fix_gap()
