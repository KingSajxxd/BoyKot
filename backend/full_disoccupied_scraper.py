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

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Origin": BASE_URL,
    "Referer": f"{BASE_URL}/",
    "X-Requested-With": "XMLHttpRequest",
}

# --- SEED LIST ---
MANUAL_SEEDS = [
    # Fast Food
    "McDonalds", "Starbucks", "Coca Cola", "Pepsi", "Nestle",
    "Burger King", "KFC", "Subway", "Pizza Hut", "Dominos", "Papa Johns",
    "Wendys", "Taco Bell", "Dunkin", "Krispy Kreme", "Tim Hortons", "Costa Coffee",
    "Hardees", "Five Guys", "Shake Shack",

    # Snacks & Drinks
    "Nescafe", "Nespresso", "Maggi", "KitKat", "Cadbury", "Oreo", "Lindt", "Nutella",
    "Pringles", "Lays", "Doritos", "Cheetos", "Toblerone", "Milka", "Ben & Jerry's",
    "Gatorade", "Powerade", "Dasani", "Aquafina", "Sprite", "Fanta", "7Up",
    "Mountain Dew", "Dr Pepper", "Schweppes", "Tropicana", "Minute Maid", "Lipton",

    # Retail & Tech
    "Amazon", "Walmart", "Target", "Costco", "Carrefour", "Tesco", "Lidl", "Aldi", "IKEA",
    "Google", "Microsoft", "Apple", "Meta", "Facebook", "Instagram", "WhatsApp",
    "Samsung", "Sony", "LG", "Intel", "HP", "Dell", "Lenovo", "Nvidia", "Siemens",
    "Puma", "Adidas", "Nike", "Zara", "H&M", "Uniqlo", "Marks and Spencer",

    # Beauty & Personal Care
    "Loreal", "Garnier", "Maybelline", "Revlon", "Clinique", "MAC Cosmetics",
    "Estee Lauder", "Victoria's Secret", "Bath and Body Works", "Ahava",
    "Nivea", "Dove", "Axe", "Vaseline", "Pantene", "Gillette", "Colgate", "Listerine",
    "Head and Shoulders", "Oral-B", "CeraVe", "La Roche-Posay",

    # Travel & Finance
    "Airbnb", "Booking.com", "Expedia", "TripAdvisor", "Uber",
    "AXA", "HSBC", "Barclays", "Pillsbury", "General Mills"
]

def setup_dirs():
    if not os.path.exists(IMAGES_DIR):
        os.makedirs(IMAGES_DIR)

def clean_text(text):
    if not text: return ""
    return text.replace("\n", " ").strip()

def get_csrf_token(session):
    """Fetches the homepage to get a CSRF token for searching."""
    try:
        r = session.get(BASE_URL, headers=HEADERS, timeout=10)
        soup = BeautifulSoup(r.text, "html.parser")
        token = soup.find("input", {"name": "csrfmiddlewaretoken"})
        if token:
            return token["value"]
    except:
        pass
    return None

def resolve_seed_url(session, token, seed_name):
    """
    SEARCHES for the brand name instead of guessing the URL.
    Returns a list of actual URLs found (e.g. search 'Dominos' -> finds '/brand/dominos-pizza/')
    """
    found_urls = []
    if not token: return []
    
    try:
        payload = {'csrfmiddlewaretoken': token, 'search_text': seed_name}
        r = session.post(BASE_URL, data=payload, headers=HEADERS, timeout=10)
        
        # Parse HTML results
        soup = BeautifulSoup(r.text, "html.parser")
        for a in soup.find_all("a", href=True):
            if a['href'].startswith("/brand/") and a['href'] != "/brand/":
                found_urls.append(f"{BASE_URL}{a['href']}")
                
    except Exception as e:
        print(f"   ⚠️ Search failed for '{seed_name}': {e}")
        
    return found_urls

def download_image(url):
    if not url: return None
    try:
        filename = url.split("/")[-1].split("?")[0]
        filename = re.sub(r"[^\w\-_\.]", "", filename)
        local_path = os.path.join(IMAGES_DIR, filename)
        if os.path.exists(local_path):
            return f"assets/images/{filename}"

        r = requests.get(url, headers=HEADERS, timeout=10)
        if r.status_code == 200:
            with open(local_path, "wb") as f:
                f.write(r.content)
            return f"assets/images/{filename}"
    except:
        pass
    return None

def fetch_sitemap(session):
    print("🗺️  Checking Sitemap...")
    urls = set()
    try:
        r = session.get(f"{BASE_URL}/sitemap.xml", timeout=10)
        if r.status_code == 200:
            found = re.findall(r"/brand/([^<\"/]+)", r.text)
            for slug in found:
                decoded = urllib.parse.unquote(slug)
                urls.add(f"{BASE_URL}/brand/{decoded}/")
            print(f"   ✅ Found {len(urls)} brands in Sitemap!")
    except:
        print("   ⚠️ Sitemap not available. relying on Smart Search.")
    return urls

def scrape_brand_details(session, brand_url):
    time.sleep(random.uniform(0.5, 1.0))
    try:
        resp = session.get(brand_url, headers=HEADERS, timeout=15)
        if resp.status_code != 200:
            return None, []

        soup = BeautifulSoup(resp.text, "html.parser")

        name_tag = soup.find("h4", class_="brand")
        if not name_tag:
            return None, []

        name = clean_text(name_tag.text).replace("BRAND NAME :", "").strip()

        status = "Avoid"
        if soup.find("h1", class_="result-failure"):
            status = "Avoid"
        elif soup.find("h1", class_="result-warning"):
            status = "Caution"
        elif soup.find("h1", class_="result-success"):
            status = "Safe"

        desc = "Listed on Disoccupied."
        reason_header = soup.find("h5", string=lambda t: t and "REASON" in t.upper())
        if reason_header:
            reason_p = reason_header.find_next_sibling("p")
            if reason_p:
                desc = clean_text(reason_p.text)

        alternatives = []
        new_links = []
        for slide in soup.find_all("div", class_="swiper-slide"):
            link = slide.find("a")
            if link and "href" in link.attrs:
                href = link["href"]
                if href.startswith("/brand/"):
                    full_url = f"{BASE_URL}{href}"
                    new_links.append(full_url)

                    raw_alt = href.replace("/brand/", "").replace("/", "")
                    alt_name = urllib.parse.unquote(raw_alt)
                    if len(alt_name) > 1 and alt_name != name:
                        alternatives.append(alt_name)

        img_path = None
        img_tag = soup.find("img", class_="brand_image")
        if img_tag and img_tag.get("src"):
            img_path = download_image(img_tag["src"])

        return (
            {
                "name": name,
                "status": status,
                "description": desc,
                "alternatives": list(set(alternatives)),
                "logo_asset": img_path,
                "category": "General",
                "subbrands": [],
            },
            new_links,
        )

    except Exception as e:
        print(f"❌ Error {brand_url}: {e}")
        return None, []

def main():
    print("--- STARTING SMART-SEARCH SCRAPER ---")
    setup_dirs()
    session = requests.Session()
    
    # 1. Try Sitemap First
    queue_urls = fetch_sitemap(session)

    # 2. Smart Search for Manual Seeds
    print(f"🔎 Resolving {len(MANUAL_SEEDS)} seeds via Search...")
    csrf_token = get_csrf_token(session)
    
    if csrf_token:
        found_seeds = 0
        for i, seed in enumerate(MANUAL_SEEDS):
            if i % 10 == 0: print(f"   ...searching batch {i+1}-{i+10}...")
            
            real_urls = resolve_seed_url(session, csrf_token, seed)
            for url in real_urls:
                queue_urls.add(url)
                found_seeds += 1
            
            time.sleep(0.5) # Be polite
        print(f"   ✅ Resolved {found_seeds} valid URLs from seeds.")
    else:
        print("   ❌ Could not get CSRF token. Skipping smart search.")

    print(f"\n--- CRAWLING {len(queue_urls)} TARGETS ---")

    visited = set()
    final_items = []

    # Load previous progress
    if os.path.exists(OUTPUT_FILE):
        try:
            with open(OUTPUT_FILE, "r") as f:
                old = json.load(f)
                final_items = old.get("items", [])
                for i in final_items:
                    visited.add(f"{BASE_URL}/brand/{urllib.parse.quote(i['name'])}/")
        except:
            pass

    queue_list = list(queue_urls)
    i = 0
    while i < len(queue_list):
        url = queue_list[i]
        i += 1

        clean_url = url if url.endswith("/") else url + "/"
        if clean_url in visited: continue
        visited.add(clean_url)

        brand_name = urllib.parse.unquote(clean_url.split("/")[-2])
        print(f"[{i}/{len(queue_list)}] Visiting: {brand_name}")

        data, new_links = scrape_brand_details(session, clean_url)

        if data:
            # Deduplicate by name
            existing_names = {x.get("name") for x in final_items}
            if data["name"] not in existing_names:
                final_items.append(data)

            # Add new spider links
            for link in new_links:
                clean_link = link if link.endswith("/") else link + "/"
                if clean_link not in visited and clean_link not in queue_list:
                    queue_list.append(clean_link)

        # Save frequently
        if i % 20 == 0:
            with open(OUTPUT_FILE, "w") as f:
                json.dump(
                    {"meta": {"updated": time.strftime("%Y-%m-%d")}, "items": final_items},
                    f, indent=2, ensure_ascii=False
                )

    # Final Save
    output = {
        "meta": {"source": "Disoccupied Smart-Seed", "updated": time.strftime("%Y-%m-%d")},
        "toll": {"killed": 73000, "injured": 171000, "children": 21000, "last_update": "Live"},
        "items": final_items,
    }
    with open(OUTPUT_FILE, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"\n🎉 DONE! Total Brands: {len(final_items)}")

if __name__ == "__main__":
    main()