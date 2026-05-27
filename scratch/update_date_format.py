import glob

old_js = """                if(!isNaN(d)) {
                    el.textContent = d.toLocaleDateString(undefined, {day:'numeric', month:'short'}) + ' ' + d.toLocaleTimeString(undefined, {hour:'2-digit', minute:'2-digit', hour12: false});
                }"""

new_js = """                if(!isNaN(d)) {
                    const month = d.toLocaleDateString('en-US', {month:'short'});
                    const day = d.getDate().toString().padStart(2, '0');
                    const year = d.getFullYear();
                    let hours = d.getHours();
                    const minutes = d.getMinutes().toString().padStart(2, '0');
                    const ampm = hours >= 12 ? 'pm' : 'am';
                    hours = hours % 12;
                    hours = hours ? hours : 12;
                    const hoursStr = hours.toString().padStart(2, '0');
                    el.textContent = `${month}-${day}-${year} | ${hoursStr}:${minutes}${ampm}`;
                }"""

def update_date_format():
    for f in ['templates/dashboard.html', 'templates/pos.html']:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            
        if old_js in content:
            content = content.replace(old_js, new_js)
            with open(f, 'w', encoding='utf-8') as file:
                file.write(content)
            print(f"Updated {f}")
        else:
            print(f"Code not found in {f}")

if __name__ == '__main__':
    update_date_format()
