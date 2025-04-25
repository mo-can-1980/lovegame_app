import requests
from bs4 import BeautifulSoup
import logging
import json
from datetime import datetime
import os
from app.database import get_db

logger = logging.getLogger(__name__)

class ATPTournamentScraper:
    """
    用于抓取ATP赛事信息的爬虫类
    """
    def __init__(self):
        self.db = get_db()
        self.base_url = "https://www.atptour.com/en/tournaments"
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }
        # 确保存储目录存在
        self.data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'data')
        if not os.path.exists(self.data_dir):
            os.makedirs(self.data_dir)

    def scrape_tournaments(self, year=None):
        """
        抓取指定年份的所有ATP赛事信息
        
        :param year: 要抓取的年份，默认为当前年份
        :return: 包含抓取结果的字典：成功/失败状态、抓取的赛事数量和输出文件名
        """
        if year is None:
            year = datetime.now().year
            
        try:
            url = f"{self.base_url}?year={year}"
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            tournament_elements = soup.select('.tourney-result')
            
            tournaments = []
            for element in tournament_elements:
                tournament = self._parse_tournament(element, year)
                if tournament:
                    tournaments.append(tournament)
                    
            # 保存到MongoDB
            self._save_to_db(tournaments, year)
            
            # 同时保存到JSON文件(用于备份)
            output_file = f"atp_tournaments_{year}.json"
            file_path = os.path.join(self.data_dir, output_file)
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(tournaments, f, ensure_ascii=False, indent=2)
                
            return {
                "success": True,
                "count": len(tournaments),
                "output_file": output_file
            }
            
        except Exception as e:
            logger.error(f"抓取ATP赛事信息时出错: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def _parse_tournament(self, element, year):
        """
        解析单个赛事HTML元素，提取赛事信息
        
        :param element: BeautifulSoup元素，包含赛事信息
        :param year: 赛事年份
        :return: 包含赛事详细信息的字典
        """
        try:
            # 赛事ID和名称
            title_element = element.select_one('.tourney-title')
            if not title_element:
                return None
                
            tourney_url = title_element.get('href', '')
            tourney_id = None
            if tourney_url:
                # 从URL中提取赛事ID
                tourney_id = tourney_url.split('/')[-1]
                
            tourney_name = title_element.text.strip()
            
            # 赛事日期
            date_element = element.select_one('.tourney-dates')
            date_text = date_element.text.strip() if date_element else ""
            
            # 赛事地点
            location_element = element.select_one('.tourney-location')
            location = location_element.text.strip() if location_element else ""
            
            # 赛事表面
            surface_element = element.select_one('.tourney-surface')
            surface = surface_element.text.strip() if surface_element else ""
            
            # 赛事等级/类别
            category_element = element.select_one('.tourney-badge-wrapper img')
            category = ""
            category_img = ""
            if category_element:
                category_img = category_element.get('src', '')
                if 'grandslam' in category_img.lower():
                    category = 'Grand Slam'
                elif 'masters-1000' in category_img.lower():
                    category = 'Masters 1000'
                elif '500' in category_img.lower():
                    category = 'ATP 500'
                elif '250' in category_img.lower():
                    category = 'ATP 250'
                else:
                    category = 'Other'
            
            # 赛事Logo
            logo_element = element.select_one('.tourney-logo img')
            logo_url = logo_element.get('src', '') if logo_element else ""
            
            # 获胜者信息
            winner_element = element.select_one('.tourney-winner')
            winner_name = ""
            winner_url = ""
            if winner_element:
                winner_link = winner_element.select_one('a')
                if winner_link:
                    winner_name = winner_link.text.strip()
                    winner_url = winner_link.get('href', '')
            
            # 组装赛事数据
            tournament = {
                "id": tourney_id,
                "name": tourney_name,
                "year": year,
                "date": date_text,
                "location": location,
                "surface": surface,
                "category": category,
                "category_img": category_img,
                "logo_url": logo_url,
                "winner": {
                    "name": winner_name,
                    "url": winner_url
                },
                "detail_url": f"https://www.atptour.com{tourney_url}" if tourney_url else "",
                "scraped_at": datetime.now().isoformat()
            }
            
            return tournament
            
        except Exception as e:
            logger.error(f"解析赛事信息时出错: {str(e)}")
            return None
    
    def _save_to_db(self, tournaments, year):
        """
        将赛事信息保存到MongoDB
        
        :param tournaments: 赛事信息列表
        :param year: 赛事年份
        """
        try:
            # 先删除该年份的所有赛事记录
            self.db.atp_tournaments.delete_many({"year": year})
            
            # 插入新的赛事记录
            if tournaments:
                self.db.atp_tournaments.insert_many(tournaments)
                logger.info(f"成功保存{len(tournaments)}个ATP赛事到数据库")
        except Exception as e:
            logger.error(f"保存赛事信息到数据库时出错: {str(e)}")
    
    def get_tournaments(self, year=None):
        """
        从数据库获取指定年份的赛事信息
        
        :param year: 赛事年份
        :return: 赛事信息列表
        """
        try:
            query = {}
            if year:
                query["year"] = year
                
            tournaments = list(self.db.atp_tournaments.find(query, {"_id": 0}))
            return {
                "success": True,
                "count": len(tournaments),
                "data": tournaments
            }
        except Exception as e:
            logger.error(f"获取ATP赛事信息时出错: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def get_tournament_by_id(self, tournament_id):
        """
        根据ID获取赛事详细信息
        
        :param tournament_id: 赛事ID
        :return: 赛事详细信息
        """
        try:
            tournament = self.db.atp_tournaments.find_one({"id": tournament_id}, {"_id": 0})
            if tournament:
                return {
                    "success": True,
                    "data": tournament
                }
            else:
                return {
                    "success": False,
                    "error": "Tournament not found"
                }
        except Exception as e:
            logger.error(f"获取ATP赛事详细信息时出错: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def get_tournament_logos(self):
        """
        获取所有有Logo的赛事的Logo信息
        
        :return: 包含所有赛事Logo的列表
        """
        try:
            # 只选择有logo_url且不为空的赛事
            logos = list(self.db.atp_tournaments.find(
                {"logo_url": {"$exists": True, "$ne": ""}},
                {"id": 1, "name": 1, "logo_url": 1, "year": 1, "_id": 0}
            ))
            
            return {
                "success": True,
                "count": len(logos),
                "data": logos
            }
        except Exception as e:
            logger.error(f"获取ATP赛事Logo信息时出错: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            } 