import requests
from bs4 import BeautifulSoup
import json
import re
from datetime import datetime

def scrape_atp_tournaments():
    url = "https://www.atptour.com/en/tournaments"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching the ATP tournaments page: {e}")
        return []
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Find the tournament list container
    tournament_list = soup.find(class_="tournament-list")
    
    print(tournament_list)
    if not tournament_list:
        print("Tournament list container not found")
        return []
    
    tournaments = []
    
    # Find all month sections (h3) and corresponding tournament lists (ul)
    month_sections = tournament_list.find_all("h3")
    
    for month_section in month_sections:
        # Get the month/year
        month_year = month_section.get_text(strip=True)
        
        # Find the next ul (tournament list for this month)
        tournament_ul = month_section.find_next("ul")
        if not tournament_ul:
            continue
        
        # Find all tournament events (li elements)
        events = tournament_ul.find_all("li")
        
        for event in events:
            tournament_data = {"month_year": month_year}
            
            # Get event banner/logo
            event_banner = event.find(class_="event_banner")
            if event_banner and event_banner.get("style"):
                # Extract URL from background-image style
                bg_image = event_banner.get("style")
                image_url_match = re.search(r'url\([\'"]?(.*?)[\'"]?\)', bg_image)
                if image_url_match:
                    tournament_data["logo"] = image_url_match.group(1)
            
            # Get tournament details
            details_holder = event.find(class_="details-holder")
            if details_holder:
                # Tournament name and flag (in top section)
                top_section = details_holder.find(class_="top")
                if top_section:
                    # Name
                    tournament_name = top_section.find(class_="title")
                    if tournament_name:
                        tournament_data["name"] = tournament_name.get_text(strip=True)
                    
                    # Flag/Country - now extracting SVG use reference
                    flag = top_section.find(class_="flag")
                    if flag:
                        # Look for SVG and use tag
                        svg = flag.find("svg")
                        if svg:
                            use_tag = svg.find("use")
                            if use_tag and use_tag.has_attr("xlink:href"):
                                # Extract the country code from the reference
                                # Format is typically like "#flag-XX" where XX is country code
                                href = use_tag["xlink:href"]
                                country_match = re.search(r'#flag-(\w+)', href)
                                if country_match:
                                    tournament_data["country_code"] = country_match.group(1)
                                else:
                                    tournament_data["flag_reference"] = href
                
                # Venue and date (in bottom section)
                bottom_section = details_holder.find(class_="bottom")
                if bottom_section:
                    # Venue
                    venue = bottom_section.find(class_="venue")
                    if venue:
                        tournament_data["venue"] = venue.get_text(strip=True)
                    
                    # Date
                    date_element = bottom_section.find(class_="date")
                    if date_element:
                        tournament_data["date"] = date_element.get_text(strip=True)
            
            # Get additional information if available
            info_holder = event.find(class_="info-holder")
            if info_holder:
                # Surface type
                surface = info_holder.find(class_="item-details")
                if surface:
                    tournament_data["surface"] = surface.get_text(strip=True)
                
                # Tournament category/level
                category = info_holder.find(class_="tourney-badge")
                if category and category.get("class"):
                    badge_classes = category.get("class")
                    if len(badge_classes) > 1:
                        tournament_data["category"] = badge_classes[1]
            
            if tournament_data:  # Only add if we got some data
                tournaments.append(tournament_data)
    
    return tournaments

def main():
    tournaments = scrape_atp_tournaments()
    
    # Convert to JSON and print
    tournaments_json = json.dumps(tournaments, indent=2, ensure_ascii=False)
    print(tournaments_json)
    
    # Save to file
    with open("atp_tournaments.json", "w", encoding="utf-8") as f:
        f.write(tournaments_json)
    
    print(f"Successfully scraped {len(tournaments)} ATP tournaments")

if __name__ == "__main__":
    main()