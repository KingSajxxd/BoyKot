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

# Headers to mimic a real browser
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

def download_image(url):
    if not url: return None
    try:
        filename = url.split('/')[-1].split('?')[0]
        # Basic sanitization
        filename = re.sub(r'[^\w\-_\.]', '', filename)
        local_path = os.path.join(IMAGES_DIR, filename)
        asset_path = f"assets/images/{filename}"

        if os.path.exists(local_path): return asset_path

        r = requests.get(url, headers=HEADERS, timeout=10)
        if r.status_code == 200:
            with open(local_path, 'wb') as f:
                f.write(r.content)
            return asset_path
    except:
        pass
    return None

def fetch_smart_toll():
    """Fetches Daily History and backfills missing data correctly."""
    print("  • Fetching Daily History (Smart Backfill)...", end=" ")
    try:
        resp = requests.get(DAILY_URL, headers=API_HEADERS, timeout=15)
        resp.raise_for_status()
        history = resp.json()

        if not history: return {}

        def get_last_known(key):
            for report in reversed(history):
                val = report.get(key, 0)
                if val is not None and val > 0:
                    return val
            return 0

        latest = history[-1]
        
        # Calculate Aid Seekers (Killed + Injured)
        aid_killed = get_last_known('aid_seeker_killed_cum')
        aid_injured = get_last_known('aid_seeker_injured_cum')

        toll_data = {
            "killed": latest.get('killed_cum', 0),
            "injured": latest.get('injured_cum', 0),
            "children": get_last_known('ext_killed_children_cum'),
            "women": get_last_known('ext_killed_women_cum'),
            "medical": get_last_known('ext_med_killed_cum'),
            "press": get_last_known('ext_press_killed_cum'),
            "civil_defense": get_last_known('ext_civdef_killed_cum'),
            "starved": get_last_known('famine_cum'),
            "aid_attacked": aid_killed + aid_injured,
            "last_update": latest.get('report_date', "Today"),
        }

        print(f"✅ (Killed: {toll_data['killed']:,} | Starved: {toll_data['starved']})")
        return toll_data

    except Exception as e:
        print(f"❌ Error fetching toll: {e}")
        return {
            "killed": 73000, "injured": 171000, "children": 21000, 
            "women": 13000, "starved": 463, "last_update": "Offline"
        }

def scrape_site():
    print(f"⚡ Connecting to {TARGET_URL}...")
    try:
        response = requests.get(TARGET_URL, headers=HEADERS)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        all_items = []
        for cat in soup.find_all("div", class_="boycott-category"):
            cat_header = cat.find("h3")
            cat_name = clean_text(cat_header.text) if cat_header else "General"
            
            for item in cat.find_all("li"):
                h4 = item.find("h4")
                if not h4: continue
                
                status_span = h4.find("span", class_="label")
                status = clean_text(status_span.text).title() if status_span else "Avoid"
                name = h4.get_text().replace(status.lower(), "").replace(status.upper(), "").strip()
                
                desc = "No description."
                content_div = item.find("div", class_="company-content")
                if content_div:
                    for p in content_div.find_all("p"):
                        if "country" not in p.get("class", []) and "alternative" not in p.get("class", []):
                            desc = clean_text(p.text); break
                
                country = "Global"
                country_tag = item.find("p", class_="country")
                if country_tag: country = clean_text(country_tag.text)

                alternatives = []
                alt_tag = item.find("p", class_="alternative")
                if alt_tag: alternatives = [clean_text(alt_tag.text).replace("Alternative", "").strip()]

                subbrands = []
                sub_div = item.find("div", class_="subbrands")
                if sub_div: subbrands = [clean_text(s.text) for s in sub_div.find_all("div")]

                img_path = None
                logo_div = item.find("div", class_="company-logo")
                if logo_div and logo_div.find("img"):
                    full_img_url = urljoin(TARGET_URL, logo_div.find("img")['src'])
                    img_path = download_image(full_img_url)

                all_items.append({
                    "name": name, 
                    "category": cat_name, 
                    "status": status,
                    "description": desc, 
                    "country": country,
                    "alternatives": alternatives, 
                    "subbrands": subbrands,
                    "logo_asset": img_path
                })
        
        print(f"\n✅ SUCCESS! Scraped {len(all_items)} companies from source.")
        return all_items

    except Exception as e:
        print(f"❌ Error scraping site: {e}")
        return []

def main():
    setup_dirs()
    
    # 1. LOAD EXISTING DATA (To avoid overwriting Disoccupied data)
    existing_items = []
    if os.path.exists(OUTPUT_JSON):
        print(f"📂 Loading existing database from {OUTPUT_JSON}...")
        try:
            with open(OUTPUT_JSON, 'r') as f:
                data = json.load(f)
                existing_items = data.get('items', [])
        except Exception as e:
            print(f"⚠️ Could not load existing data: {e}")

    # Create a set of normalized names for fast duplicate checking
    existing_names = set()
    for item in existing_items:
        if 'name' in item and item['name']:
            existing_names.add(clean_text(item['name']).lower())
    
    print(f"   ℹ️  Found {len(existing_names)} brands currently in DB.")

    # 2. SCRAPE NEW DATA
    scraped_items = scrape_site()
    
    # 3. MERGE (Only add if NOT in existing)
    added_count = 0
    for item in scraped_items:
        name = clean_text(item['name'])
        name_key = name.lower()
        
        if name_key not in existing_names:
            existing_items.append(item)
            existing_names.add(name_key) # Add to set to prevent internal duplicates
            added_count += 1
            print(f"   ➕ Added new brand: {name}")
        # else:
        #     print(f"   (Skipping {name} - Already exists)")

    # 4. SAVE MERGED LIST
    final_data = {
        "meta": {
            "source": "Merged Database",
            "updated": time.strftime("%Y-%m-%d"),
        },
        "toll": fetch_smart_toll(),
        "items": existing_items,
    }

    with open(OUTPUT_JSON, 'w') as f:
        json.dump(final_data, f, indent=2)

    print(f"\n🎉 DONE! Added {added_count} new brands.")
    print(f"   Total Database Size: {len(existing_items)} brands.")
    print(f"   Saved to {OUTPUT_JSON}")

if __name__ == "__main__":
    main()