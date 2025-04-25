import requests
from bs4 import BeautifulSoup
import json
import logging
import os
from datetime import datetime
import re
import time
from pymongo import MongoClient
from dotenv import load_dotenv

# 配置日志
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 加载环境变量
load_dotenv()

class ATPTournamentScraper:
    """从ATP官网爬取赛事信息的工具类"""
    
    BASE_URL = "https://www.atptour.com"
    TOURNAMENTS_URL = f"{BASE_URL}/en/tournaments"
    
    def __init__(self, mongo_uri=None):
        """初始化爬虫"""
        self.mongo_uri = mongo_uri or os.environ.get('MONGO_URI', 'mongodb://localhost:27017/tennisapp')
        self.db_client = MongoClient(self.mongo_uri)
        self.db = self.db_client.get_database()
        self.tournaments_collection = self.db.tournaments
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        }
    
    def scrape_tournaments(self, year=None):
        """爬取特定年份的所有赛事
        
        参数:
            year (int): 要爬取的年份，默认为当前年份
            
        返回:
            list: 赛事信息列表
        """
        if year is None:
            year = datetime.now().year
            
        logger.info(f"开始爬取 {year} 年ATP赛事信息...")
        
        # 构造URL（添加年份参数）
        url = f"{self.TOURNAMENTS_URL}?year={year}"
        
        try:
            # 获取网页内容
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()
            
            # 解析HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # 提取赛事信息
            tournaments = []
            
            # 找到所有赛事区块
            tournament_sections = soup.select('.tournament-list')
            
            for section in tournament_sections:
                tournament = self._parse_tournament_section(section, year)
                if tournament:
                    tournaments.append(tournament)
                    # 防止请求过快被封
                    time.sleep(0.5)
            
            logger.info(f"成功爬取 {len(tournaments)} 个赛事信息")
            return tournaments
            
        except Exception as e:
            logger.error(f"爬取赛事信息出错: {e}")
            raise
    
    def _parse_tournament_section(self, section, year):
        """解析单个赛事区块
        
        参数:
            section (BeautifulSoup): 赛事HTML区块
            year (int): 赛事年份
            
        返回:
            dict: 赛事信息
        """
        try:
            # 提取基本信息
            title_elem = section.select_one('.tourney-title')
            location_elem = section.select_one('.tourney-location')
            date_elem = section.select_one('.tourney-dates')
            
            if not title_elem or not date_elem:
                return None
                
            title = title_elem.text.strip()
            location = location_elem.text.strip() if location_elem else ""
            date_text = date_elem.text.strip()
            
            # 提取赛事ID和详情页URL
            details_link = section.select_one('a.tourney-title')
            details_url = None
            tournament_id = None
            
            if details_link and 'href' in details_link.attrs:
                details_url = f"{self.BASE_URL}{details_link['href']}"
                # 从URL中提取赛事ID
                match = re.search(r'/tournaments/(\d+)/', details_url)
                if match:
                    tournament_id = match.group(1)
            
            # 提取表面和室内/室外信息
            surface_elem = section.select_one('.tourney-badge-wrapper .info-surface')
            surface = surface_elem.text.strip() if surface_elem else ""
            
            indoor_outdoor_elem = section.select_one('.tourney-badge-wrapper .info-indoor-outdoor')
            indoor_outdoor = indoor_outdoor_elem.text.strip() if indoor_outdoor_elem else ""
            
            # 提取奖金信息
            prize_money_elem = section.select_one('.tourney-details .info-prize-money')
            prize_money = prize_money_elem.text.strip() if prize_money_elem else ""
            
            # 提取抽签规模
            draw_size_elem = section.select_one('.tourney-details .info-draw')
            draw_size = draw_size_elem.text.strip() if draw_size_elem else ""
            
            # 创建基本赛事信息
            tournament = {
                'id': tournament_id,
                'title': title,
                'location': location,
                'date_text': date_text,
                'year': year,
                'surface': surface,
                'indoor_outdoor': indoor_outdoor,
                'prize_money': prize_money,
                'draw_size': draw_size,
                'details_url': details_url,
                'logo_url': self._get_tournament_logo(details_url) if details_url else None,
                'scraped_at': datetime.now(),
            }
            
            # 如果有详情页URL，获取更多信息
            if details_url:
                detailed_info = self._get_tournament_details(details_url)
                if detailed_info:
                    tournament.update(detailed_info)
            
            return tournament
            
        except Exception as e:
            logger.error(f"解析赛事区块出错: {e}")
            return None
    
    def _get_tournament_logo(self, details_url):
        """获取赛事Logo
        
        参数:
            details_url (str): 赛事详情页URL
            
        返回:
            str: Logo图片URL
        """
        try:
            # 获取详情页内容
            response = requests.get(details_url, headers=self.headers)
            response.raise_for_status()
            
            # 解析HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # 查找赛事Logo
            logo_elem = soup.select_one('.tournament-logo img')
            if logo_elem and 'src' in logo_elem.attrs:
                logo_url = logo_elem['src']
                # 确保URL是完整的
                if logo_url.startswith('/'):
                    logo_url = f"{self.BASE_URL}{logo_url}"
                return logo_url
                
            return None
            
        except Exception as e:
            logger.error(f"获取赛事Logo出错 ({details_url}): {e}")
            return None
    
    def _get_tournament_details(self, details_url):
        """获取赛事详细信息
        
        参数:
            details_url (str): 赛事详情页URL
            
        返回:
            dict: 赛事详细信息
        """
        try:
            # 获取详情页内容
            response = requests.get(details_url, headers=self.headers)
            response.raise_for_status()
            
            # 解析HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            
            details = {}
            
            # 获取赛事描述
            description_elem = soup.select_one('.tournament-desc')
            if description_elem:
                details['description'] = description_elem.text.strip()
            
            # 获取赛事网站
            website_elem = soup.select_one('.tourney-website a')
            if website_elem and 'href' in website_elem.attrs:
                details['website'] = website_elem['href']
            
            # 获取赛事地址
            address_elem = soup.select_one('.tourney-address')
            if address_elem:
                details['address'] = address_elem.text.strip()
            
            # 获取赛事电话
            phone_elem = soup.select_one('.tourney-contact-phone')
            if phone_elem:
                details['phone'] = phone_elem.text.strip()
            
            # 获取赛事邮箱
            email_elem = soup.select_one('.tourney-contact-email')
            if email_elem:
                details['email'] = email_elem.text.strip()
            
            # 获取赛事委员会信息
            committee_elems = soup.select('.tourney-committee-row')
            if committee_elems:
                committee = {}
                for elem in committee_elems:
                    role_elem = elem.select_one('.tourney-committee-role')
                    name_elem = elem.select_one('.tourney-committee-member')
                    if role_elem and name_elem:
                        role = role_elem.text.strip()
                        name = name_elem.text.strip()
                        committee[role] = name
                
                if committee:
                    details['committee'] = committee
            
            # 获取场地信息
            venue_elem = soup.select_one('.tourney-venue')
            if venue_elem:
                details['venue'] = venue_elem.text.strip()
            
            # 获取历史冠军
            champions = []
            champion_rows = soup.select('.tourney-champions-table tbody tr')
            for row in champion_rows:
                year_elem = row.select_one('.tourney-champions-year')
                singles_elem = row.select_one('.tourney-champions-singles')
                doubles_elem = row.select_one('.tourney-champions-doubles')
                
                if year_elem:
                    champion = {
                        'year': year_elem.text.strip(),
                        'singles': singles_elem.text.strip() if singles_elem else '',
                        'doubles': doubles_elem.text.strip() if doubles_elem else ''
                    }
                    champions.append(champion)
            
            if champions:
                details['champions'] = champions
            
            return details
            
        except Exception as e:
            logger.error(f"获取赛事详情出错 ({details_url}): {e}")
            return {}
    
    def save_to_mongodb(self, tournaments):
        """保存赛事信息到MongoDB
        
        参数:
            tournaments (list): 赛事信息列表
        """
        if not tournaments:
            logger.warning("没有赛事信息可保存")
            return
            
        try:
            # 更新或插入数据
            for tournament in tournaments:
                if 'id' in tournament and tournament['id']:
                    # 使用赛事ID作为过滤条件
                    self.tournaments_collection.update_one(
                        {'id': tournament['id']},
                        {'$set': tournament},
                        upsert=True
                    )
                else:
                    # 如果没有ID，直接插入
                    self.tournaments_collection.insert_one(tournament)
                    
            logger.info(f"成功保存 {len(tournaments)} 个赛事信息到MongoDB")
            
        except Exception as e:
            logger.error(f"保存赛事信息到MongoDB出错: {e}")
            raise
    
    def export_to_json(self, tournaments, output_file="atp_tournaments.json"):
        """导出赛事信息到JSON文件
        
        参数:
            tournaments (list): 赛事信息列表
            output_file (str): 输出文件名
        """
        if not tournaments:
            logger.warning("没有赛事信息可导出")
            return
            
        try:
            # 处理日期格式
            for tournament in tournaments:
                if 'scraped_at' in tournament:
                    tournament['scraped_at'] = tournament['scraped_at'].isoformat()
            
            # 导出到JSON
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(tournaments, f, ensure_ascii=False, indent=2)
                
            logger.info(f"成功导出 {len(tournaments)} 个赛事信息到 {output_file}")
            
        except Exception as e:
            logger.error(f"导出赛事信息到JSON出错: {e}")
            raise
    
    def run(self, year=None, output_file="atp_tournaments.json"):
        """运行爬虫流程
        
        参数:
            year (int): 要爬取的年份，默认为当前年份
            output_file (str): 输出JSON文件名
        
        返回:
            list: 赛事信息列表
        """
        # 爬取赛事信息
        tournaments = self.scrape_tournaments(year)
        
        # 保存到MongoDB
        self.save_to_mongodb(tournaments)
        
        # 导出到JSON
        self.export_to_json(tournaments, output_file)
        
        return tournaments 