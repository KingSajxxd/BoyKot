import requests
from bs4 import BeautifulSoup
import json
import time
import random
import os
import urllib.parse
import re

# --- CONFIGURATION ---
BASE_URL = "https://disoccupied.com"
OUTPUT_FILE = "../app/assets/boycott_data.json"
IMAGES_DIR = "../app/assets/images"

# Headers to mimic a real browser
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Origin': BASE_URL,
    'Referer': f'{BASE_URL}/',
    'X-Requested-With': 'XMLHttpRequest', 
}

# --- THE MEGA SEED LIST ---
# This forces the scraper to check these brands directly
MANUAL_SEEDS = [
    "McDonalds", "Starbucks", "Coca Cola", "Pepsi", "Nestle", "Burger King", "Pizza Hut", "Dominos", "Papa Johns",
    "Disney", "Marvel", "Fox", "Paramount", "Warner Bros", "Netflix", "Amazon", "Google", "HP", "Siemens", "AXA",
    "Puma", "Adidas", "Nike", "Zara", "H&M", "Marks and Spencer", "L'Oreal", "Garnier", "Maybelline", "Revlon",
    "Estee Lauder", "Clinique", "MAC Cosmetics", "Victoria's Secret", "Bath and Body Works", "Ahava", "Sabra",
    "SodaStream", "Keter", "Teva", "Wix", "Fiverr", "Monday.com", "Intel", "Motorola", "Airbnb", "Booking.com",
    "Expedia", "TripAdvisor", "Carrefour", "Tesco", "Lidl", "Aldi", "Costco", "Walmart", "Target", "Whole Foods",
    "Danone", "Activia", "Evian", "Volvic", "General Mills", "Kelloggs", "Mars", "Snickers", "Twix", "M&Ms",
    "KitKat", "Ferrero Rocher", "Nutella", "Kinder", "Mondelez", "Cadbury", "Oreo", "Toblerone", "Milka", "Lindt",
    "Kraft Heinz", "Unilever", "Ben & Jerry's", "Hellmann's", "Knorr", "Maggi", "Lipton", "Nescafe", "Nespresso",
    "Pringles", "Lays", "Doritos", "Cheetos", "Gatorade", "Powerade", "Vitamin Water", "Dasani", "Aquafina",
    "7Up", "Sprite", "Fanta", "Mountain Dew", "Dr Pepper", "Schweppes", "Tropicana", "Minute Maid", "Simply Orange",
    "Innocent", "Alpro", "Oatly", "Beyond Meat", "Impossible Foods", "Quorn", "Amy's Kitchen", "Annie's Homegrown",
    "Volvo", "CAT", "JCB", "Hyundai", "Chevron", "BP", "Shell", "ExxonMobil", "Texaco", "Caltex", "Barclays",
    "HSBC", "BNP Paribas", "Societe Generale", "Scotiabank", "RBC", "TD Bank", "BMO", "CIBC", "Manulife", "Sun Life",
    "Hardees", "KFC", "Subway", "Taco Bell", "Wendy's", "Dunkin", "Krispy Kreme", "Tim Hortons", "Costa Coffee"
]

def setup_dirs():
    if not os.path.exists(IMAGES_DIR):
        os.makedirs(IMAGES_DIR)

def clean_text(text):
    if not text: return ""
    return text.replace('\n', ' ').strip()

def download_image(url):
    if not url: return None
    try:
        filename = url.split('/')[-1].split('?')[0]
        filename = re.sub(r'[^\w\-_\.]', '', filename) # Sanitize
        local_path = os.path.join(IMAGES_DIR, filename)
        if os.path.exists(local_path): return f"assets/images/{filename}"

        r = requests.get(url, headers=HEADERS, timeout=10)
        if r.status_code == 200:
            with open(local_path, 'wb') as f:
                f.write(r.content)
            return f"assets/images/{filename}"
    except: pass
    return None

def fetch_sitemap(session):
    print("🗺️  Checking Sitemap...")
    urls = set()
    try:
        r = session.get(f"{BASE_URL}/sitemap.xml", timeout=10)
        if r.status_code == 200:
            found = re.findall(r'/brand/([^<"/]+)', r.text)
            for slug in found:
                decoded = urllib.parse.unquote(slug)
                urls.add(f"{BASE_URL}/brand/{decoded}/")
            print(f"   ✅ Found {len(urls)} brands in Sitemap!")
    except: pass
    return urls

def scrape_brand_details(session, brand_url):
    time.sleep(random.uniform(0.5, 1.0)) # Fast but safe
    try:
        resp = session.get(brand_url, headers=HEADERS, timeout=15)
        if resp.status_code != 200: return None, []
        
        soup = BeautifulSoup(resp.text, 'html.parser')
        
        name_tag = soup.find('h4', class_='brand')
        if not name_tag: return None, []
        name = clean_text(name_tag.text).replace('BRAND NAME :', '').strip()
        
        # Determine Status
        status = "Avoid" # Default to avoid if we can't tell, usually red banner
        if soup.find('h1', class_='result-failure'): status = "Avoid"
        elif soup.find('h1', class_='result-warning'): status = "Caution"
        elif soup.find('h1', class_='result-success'): status = "Safe"

        desc = "Listed on Disoccupied."
        reason_header = soup.find('h5', string=lambda t: t and "REASON" in t.upper())
        if reason_header:
            reason_p = reason_header.find_next_sibling('p')
            if reason_p: desc = clean_text(reason_p.text)

        alternatives = []
        new_links = []
        # Find alternatives in the slider
        for slide in soup.find_all('div', class_='swiper-slide'):
            link = slide.find('a')
            if link and 'href' in link.attrs:
                href = link['href']
                if href.startswith('/brand/'):
                    full_url = f"{BASE_URL}{href}"
                    new_links.append(full_url)
                    
                    raw_alt = href.replace('/brand/', '').replace('/', '')
                    alt_name = urllib.parse.unquote(raw_alt)
                    if len(alt_name) > 1 and alt_name != name:
                        alternatives.append(alt_name)

        img_path = None
        img_tag = soup.find('img', class_='brand_image')
        if img_tag and img_tag.get('src'):
            img_path = download_image(img_tag['src'])

        return {
            "name": name,
            "status": status,
            "description": desc,
            "alternatives": list(set(alternatives)),
            "logo_asset": img_path,
            "category": "General",
            "subbrands": []
        }, new_links

    except Exception as e:
        print(f"❌ Error {brand_url}: {e}")
        return None, []

def main():
    print("--- STARTING MEGA-SEED SCRAPER ---")
    setup_dirs()
    session = requests.Session()

    # 1. BUILD QUEUE (Sitemap + Manual Seeds)
    queue_urls = fetch_sitemap(session)
    
    print(f"   🌱 Adding {len(MANUAL_SEEDS)} Manual Seeds...")
    for s in MANUAL_SEEDS:
        # Encode spaces for URL (Coca Cola -> Coca%20Cola)
        safe_name = urllib.parse.quote(s)
        queue_urls.add(f"{BASE_URL}/brand/{safe_name}/")

    print(f"\n--- CRAWLING {len(queue_urls)} INITIAL TARGETS ---")
    
    visited = set()
    final_items = []
    
    # Load previous progress to avoid starting over
    if os.path.exists(OUTPUT_FILE):
        try:
            with open(OUTPUT_FILE, 'r') as f:
                old = json.load(f)
                final_items = old.get('items', [])
                for i in final_items: 
                    visited.add(f"{BASE_URL}/brand/{urllib.parse.quote(i['name'])}/")
        except: pass

    queue_list = list(queue_urls)
    
    # 2. SPIDER LOOP
    i = 0
    while i < len(queue_list):
        url = queue_list[i]
        i += 1
        
        clean_url = url if url.endswith('/') else url + '/'
        if clean_url in visited: continue
        visited.add(clean_url)
        
        brand_name = urllib.parse.unquote(clean_url.split('/')[-2])
        print(f"[{i}/{len(queue_list)}] Visiting: {brand_name}")
        
        data, new_links = scrape_brand_details(session, clean_url)
        
        if data:
            final_items.append(data)
            # Add found alternatives to queue (this finds the 'Safe' brands)
            for link in new_links:
                clean_link = link if link.endswith('/') else link + '/'
                if clean_link not in visited and clean_link not in queue_list:
                    queue_list.append(clean_link)

        # Save every 20 items
        if i % 20 == 0:
            with open(OUTPUT_FILE, 'w') as f:
                json.dump({"meta": {"updated": time.strftime("%Y-%m-%d")}, "items": final_items}, f, indent=2)

    # 3. FINAL SAVE (Preserve Toll Data structure)
    output = {
        "meta": {"source": "Disoccupied Mega-Seed", "updated": time.strftime("%Y-%m-%d")},
        "toll": {"killed": 73000, "injured": 171000, "children": 21000, "last_update": "Live"},
        "items": final_items
    }
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(output, f, indent=2)
        
    print(f"\n🎉 DONE! Total Brands: {len(final_items)}")

if __name__ == "__main__":
    main()
