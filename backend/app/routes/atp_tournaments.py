from flask import Blueprint, jsonify, request
from app.scrapers.atp_tournament_scraper import ATPTournamentScraper
from app.utils.auth import jwt_required, admin_required
import logging

logger = logging.getLogger(__name__)
atp_tournaments_bp = Blueprint('atp_tournaments', __name__, url_prefix='/api/tournaments')
scraper = ATPTournamentScraper()

@atp_tournaments_bp.route('/', methods=['GET'])
def get_tournaments():
    """获取ATP赛事列表
    
    可选参数:
        year: 要获取的赛事年份
    """
    year = request.args.get('year')
    if year:
        try:
            year = int(year)
        except ValueError:
            return jsonify({"success": False, "error": "Year must be an integer"}), 400
    
    result = scraper.get_tournaments(year)
    
    if result["success"]:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@atp_tournaments_bp.route('/<tournament_id>', methods=['GET'])
def get_tournament_details(tournament_id):
    """获取单个ATP赛事详情
    
    路径参数:
        tournament_id: 赛事ID
    """
    result = scraper.get_tournament_by_id(tournament_id)
    
    if result["success"]:
        return jsonify(result), 200
    else:
        return jsonify(result), 404

@atp_tournaments_bp.route('/logos', methods=['GET'])
def get_tournament_logos():
    """获取所有ATP赛事的Logo信息"""
    result = scraper.get_tournament_logos()
    
    if result["success"]:
        return jsonify(result), 200
    else:
        return jsonify(result), 500

@atp_tournaments_bp.route('/scrape', methods=['POST'])
@jwt_required
@admin_required
def scrape_tournaments():
    """手动触发ATP赛事数据抓取
    
    需要管理员权限
    
    可选JSON参数:
        year: 要抓取的赛事年份，默认为当前年份
    """
    data = request.json or {}
    year = data.get('year')
    
    if year:
        try:
            year = int(year)
        except ValueError:
            return jsonify({"success": False, "error": "Year must be an integer"}), 400
    
    # 记录谁触发了抓取任务
    user_id = getattr(request, 'user_id', 'unknown')
    logger.info(f"用户 {user_id} 触发了ATP赛事抓取任务，年份: {year or 'current'}")
    
    result = scraper.scrape_tournaments(year)
    
    if result["success"]:
        return jsonify(result), 200
    else:
        return jsonify(result), 500 