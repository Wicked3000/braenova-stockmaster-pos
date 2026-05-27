import glob
import re

def fix_logo():
    files = glob.glob('templates/*.html')
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            
        # Desktop height
        content = content.replace('.logo-img { height: 45px; width: auto; border-radius: 8px; border: 1px solid #333; }', 
                                  '.logo-img { height: 55px; width: auto; }')
        content = content.replace('.logo-img { height: 40px; width: auto; border-radius: 8px; border: 1px solid #333; }', 
                                  '.logo-img { height: 50px; width: auto; }')
        content = content.replace('.logo-img { height: 40px; width: auto; border-radius: 8px; }', 
                                  '.logo-img { height: 50px; width: auto; }')
        # login.html inline style
        content = content.replace('style="height: 80px; width: auto; border-radius: 15px;"',
                                  'style="height: 100px; width: auto;"')
        # pending_activation
        content = content.replace('.logo-img { height: 50px; border-radius: 10px; margin-bottom: 15px; }',
                                  '.logo-img { height: 60px; margin-bottom: 15px; }')
        # register.html
        content = content.replace('.logo-img { height: 60px; border-radius: 12px; margin-bottom: 20px; }',
                                  '.logo-img { height: 75px; margin-bottom: 20px; }')
        
        # Mobile height overrides
        content = content.replace('.logo-img { height: 32px !important; }', 
                                  '.logo-img { height: 42px !important; }')
        
        # Fix pos.html modal logo (style="width: 40px; height: 40px; border-radius: 10px;")
        content = content.replace('style="width: 40px; height: 40px; border-radius: 10px;"',
                                  'style="width: 50px; height: 50px;"')
        
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
            
    print("Logo styling updated in all files.")

if __name__ == '__main__':
    fix_logo()
