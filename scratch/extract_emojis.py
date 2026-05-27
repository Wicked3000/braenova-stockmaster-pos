import os
import glob
import emoji

def extract_emojis():
    files = glob.glob('templates/*.html')
    all_emojis = set()
    
    for file_path in files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            for char in content:
                if char in emoji.EMOJI_DATA:
                    all_emojis.add(char)
                    
    with open('scratch/emojis_found.txt', 'w', encoding='utf-8') as out:
        out.write("Found Emojis:\n")
        for e in all_emojis:
            out.write(f"'{e}': '<i class=\"bi bi-X\"></i>',\n")
            
    print("Extraction complete. Check scratch/emojis_found.txt")

if __name__ == '__main__':
    extract_emojis()
