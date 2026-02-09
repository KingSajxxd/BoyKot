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

# --- ONLY "LIKELY-TO-EXIST" SEEDS ON DISOCCUPIED ---
# Keep these as simple consumer-facing names.
MANUAL_SEEDS = [
    # Food / drink (commonly present)
    "McDonalds", "Starbucks", "Coca Cola", "Pepsi", "Nestle",
    "Burger King", "KFC", "Subway", "Pizza Hut", "Dominos", "Papa Johns",
    "Wendys", "Taco Bell", "Dunkin", "Krispy Kreme", "Tim Hortons", "Costa Coffee",
    "Nescafe", "Nespresso", "Maggi", "KitKat", "Cadbury", "Oreo", "Lindt", "Nutella",
    "Pringles", "Lays", "Doritos", "Cheetos",
    "Gatorade", "Powerade", "Dasani", "Aquafina", "Sprite", "Fanta", "7Up",

    # Retail / shopping
    "Amazon", "Walmart", "Target", "Costco",
    "Carrefour", "Tesco", "Lidl", "Aldi", "IKEA",
    "Marks and Spencer", "Zara", "H&M", "Uniqlo",

    # Tech / electronics (simple parent brand names only)
    "Google", "Microsoft", "Apple", "Meta", "Facebook", "Instagram", "WhatsApp",
    "Samsung", "Sony", "LG", "Intel", "HP", "Dell", "Lenovo", "Nvidia",

    # Streaming / media (brand names only)
    "Netflix", "Disney",

    # Fashion / sportswear
    "Nike", "Adidas", "Puma", "Reebok", "Under Armour",

    # Beauty / personal care (brand names only)
    "Loreal", "Garnier", "Maybelline", "Revlon", "Clinique", "MAC",
    "Nivea", "Dove", "Axe", "Vaseline",
    "Pantene", "Gillette", "Colgate", "Listerine",

    # Travel / booking (simple)
    "Airbnb", "Booking", "Expedia", "TripAdvisor", "Agoda", "Uber",

    # Banks / finance / insurance (often present as brand names)
    "AXA", "HSBC", "Barclays",

    # Misc
    "Siemens",
]

# Common “human input” -> “Disoccupied-friendly” variations
# (we'll generate variants so user can type anything and you still hit the right page)
SEED_ALIASES = {
    "McDonald's": "McDonalds",
    "Domino's": "Dominos",
    "Papa John's": "Papa Johns",
    "Wendy's": "Wendys",
    "H&M": "H&M",
    "L'Oréal": "Loreal",
    "L’Oreal": "Loreal",
    "Nestlé": "Nestle",
    "7-Up": "7Up",
    "Coca-Cola": "Coca Cola",
}

def setup_dirs():
    if not os.path.exists(IMAGES_DIR):
        os.makedirs(IMAGES_DIR)

def clean_text(text):
    if not text:
        return ""
    return text.replace("\n", " ").strip()

def download_image(url):
    if not url:
        return None
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
        pass
    return urls

def normalize_seed(s: str) -> str:
    s = s.strip()
    if s in SEED_ALIASES:
        s = SEED_ALIASES[s]
    # remove weird quotes/apostrophes but keep & (H&M)
    s = s.replace("’", "'").replace("“", '"').replace("”", '"')
    s = s.replace("'", "")  # McDonald's -> McDonalds
    s = re.sub(r"\s+", " ", s).strip()
    return s

def seed_variants(s: str):
    """
    Generate variants: 'Coca Cola', 'CocaCola', 'Coca-Cola'
    """
    s = normalize_seed(s)
    variants = {s}

    # 1. Remove spaces (CocaCola)
    no_space = s.replace(" ", "")
    if len(no_space) > 2:
        variants.add(no_space)

    # 2. Replace & with 'and'
    if "&" in s:
        variants.add(s.replace("&", "and"))

    # 3. Hyphenated (Coca-Cola) - NEW ADDITION
    if " " in s:
        variants.add(s.replace(" ", "-"))

    # 4. Title case
    variants.add(s.title())

    # --- THIS WAS MISSING ---
    out = []
    for v in variants:
        v = v.strip()
        if len(v) >= 2:
            out.append(v)
            
    return list(dict.fromkeys(out))

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
    print("--- STARTING MEGA-SEED SCRAPER (DISOCCUPIED-FRIENDLY) ---")
    setup_dirs()
    session = requests.Session()

    # 1) Start from sitemap
    queue_urls = fetch_sitemap(session)

    # 2) Add manual seeds BUT as Disoccupied-friendly variants
    seed_count = 0
    for s in MANUAL_SEEDS:
        for v in seed_variants(s):
            safe_name = urllib.parse.quote(v)
            queue_urls.add(f"{BASE_URL}/brand/{safe_name}/")
            seed_count += 1

    print(f"   🌱 Added ~{seed_count} seed URL variants from {len(MANUAL_SEEDS)} seeds.")
    print(f"\n--- CRAWLING {len(queue_urls)} INITIAL TARGETS ---")

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
        if clean_url in visited:
            continue
        visited.add(clean_url)

        brand_name = urllib.parse.unquote(clean_url.split("/")[-2])
        print(f"[{i}/{len(queue_list)}] Visiting: {brand_name}")

        data, new_links = scrape_brand_details(session, clean_url)

        if data:
            existing_names = {x.get("name") for x in final_items}
            if data["name"] not in existing_names:
                final_items.append(data)

            for link in new_links:
                clean_link = link if link.endswith("/") else link + "/"
                if clean_link not in visited and clean_link not in queue_list:
                    queue_list.append(clean_link)

        if i % 20 == 0:
            with open(OUTPUT_FILE, "w") as f:
                json.dump(
                    {"meta": {"updated": time.strftime("%Y-%m-%d")}, "items": final_items},
                    f,
                    indent=2,
                    ensure_ascii=False,
                )

    output = {
        "meta": {"source": "Disoccupied Seeds (Brand-Only)", "updated": time.strftime("%Y-%m-%d")},
        "toll": {"killed": 73000, "injured": 171000, "children": 21000, "last_update": "Live"},
        "items": final_items,
    }
    with open(OUTPUT_FILE, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"\n🎉 DONE! Total Brands: {len(final_items)}")

if __name__ == "__main__":
    main()
