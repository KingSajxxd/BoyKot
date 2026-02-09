import requests
from bs4 import BeautifulSoup
import json
import os
import re
from urllib.parse import urljoin
import time

# --- CONFIG ---
TARGET_URL = "https://boycott-israel.org/boycott.html"
DAILY_URL = "https://data.techforpalestine.org/api/v2/casualties_daily.json"
OUTPUT_JSON = "../app/assets/boycott_data.json"
IMAGES_DIR = "../app/assets/images"

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
}
API_HEADERS = {'User-Agent': 'Mozilla/5.0'}

def setup_dirs():
    if not os.path.exists(IMAGES_DIR):
        os.makedirs(IMAGES_DIR)

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def normalize_name(name):
    """Normalizes name for duplicate checking (e.g. 'Coca-Cola' == 'coca cola')"""
    if not name: return ""
    return re.sub(r'[^a-z0-9]', '', name.lower())

def download_image(url):
    if not url: return None
    try:
        filename = url.split('/')[-1].split('?')[0]
        filename = re.sub(r'[^\w\-_\.]', '', filename)
        local_path = os.path.join(IMAGES_DIR, filename)
        if os.path.exists(local_path): return f"assets/images/{filename}"

        r = requests.get(url, headers=HEADERS, timeout=10)
        if r.status_code == 200:
            with open(local_path, 'wb') as f:
                f.write(r.content)
            return f"assets/images/{filename}"
    except: pass
    return None

def fetch_smart_toll():
    """Fetches Daily History."""
    print("  • Fetching Daily Toll...", end=" ")
    try:
        resp = requests.get(DAILY_URL, headers=API_HEADERS, timeout=15)
        if resp.status_code == 200:
            history = resp.json()
            if history:
                latest = history[-1]
                # Simple fetch for toll data
                return {
                    "killed": latest.get('killed_cum', 0),
                    "injured": latest.get('injured_cum', 0),
                    "children": latest.get('ext_killed_children_cum', 0),
                    "women": latest.get('ext_killed_women_cum', 0),
                    "starved": latest.get('famine_cum', 0),
                    "last_update": latest.get('report_date', "Today")
                }
    except: pass
    return {"killed": 73000, "last_update": "Offline"} # Fallback

def scrape_site():
    print(f"⚡ Connecting to {TARGET_URL}...")
    try:
        response = requests.get(TARGET_URL, headers=HEADERS)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        scraped_items = []
        for cat in soup.find_all("div", class_="boycott-category"):
            cat_header = cat.find("h3")
            cat_name = clean_text(cat_header.text) if cat_header else "General"
            
            for item in cat.find_all("li"):
                h4 = item.find("h4")
                if not h4: continue
                
                status_span = h4.find("span", class_="label")
                status = clean_text(status_span.text).title() if status_span else "Avoid"
                name = h4.get_text().replace(status.lower(), "").replace(status.upper(), "").strip()
                
                # Extract meta
                desc = "No description."
                content = item.find("div", class_="company-content")
                if content:
                    for p in content.find_all("p"):
                        if "country" not in p.get("class", []) and "alternative" not in p.get("class", []):
                            desc = clean_text(p.text); break
                
                country = "Global"
                ctag = item.find("p", class_="country")
                if ctag: country = clean_text(ctag.text)

                alternatives = []
                alt_tag = item.find("p", class_="alternative")
                if alt_tag: alternatives = [clean_text(alt_tag.text).replace("Alternative", "").strip()]

                img_path = None
                logo_div = item.find("div", class_="company-logo")
                if logo_div and logo_div.find("img"):
                    img_path = download_image(urljoin(TARGET_URL, logo_div.find("img")['src']))

                scraped_items.append({
                    "name": name, "category": cat_name, "status": status,
                    "description": desc, "country": country,
                    "alternatives": alternatives, "subbrands": [],
                    "logo_asset": img_path
                })
        return scraped_items
    except Exception as e:
        print(f"❌ Error: {e}")
        return []

def main():
    setup_dirs()
    
    # 1. LOAD EXISTING DATA (From Disoccupied Scraper)
    existing_data = {"items": []}
    if os.path.exists(OUTPUT_JSON):
        print(f"📂 Loading existing database...")
        try:
            with open(OUTPUT_JSON, 'r') as f:
                existing_data = json.load(f)
        except: pass

    # Build lookup set for fast duplicate checking
    existing_names = set()
    for item in existing_data.get("items", []):
        existing_names.add(normalize_name(item['name']))
    
    print(f"   ℹ️  Current Database Size: {len(existing_names)} brands.")

    # 2. SCRAPE NEW DATA
    new_items = scrape_site()
    
    # 3. MERGE
    added_count = 0
    final_items = existing_data.get("items", [])
    
    for item in new_items:
        key = normalize_name(item['name'])
        # Only add if we don't have it yet
        if key not in existing_names:
            final_items.append(item)
            existing_names.add(key)
            added_count += 1
            print(f"   ➕ Added: {item['name']}")

    # 4. SAVE
    final_output = {
        "meta": {"source": "Merged Database", "updated": time.strftime("%Y-%m-%d")},
        "toll": fetch_smart_toll(),
        "items": final_items
    }

    with open(OUTPUT_JSON, 'w') as f:
        json.dump(final_output, f, indent=2)

    print(f"\n🎉 DONE! Added {added_count} new brands.")
    print(f"   Total Database: {len(final_items)} brands.")

if __name__ == "__main__":
    main()