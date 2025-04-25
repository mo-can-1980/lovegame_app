from flask import Blueprint, jsonify, request
from app.utils.atp_scraper import ATPTournamentScraper
from flask_jwt_extended import jwt_required
import logging
from datetime import datetime

# 配置日志
logger = logging.getLogger(__name__)

# 创建蓝图
atp_tournaments_bp = Blueprint('atp_tournaments', __name__, url_prefix='/api/atp-tournaments')

@atp_tournaments_bp.route('/scrape', methods=['POST'])
@jwt_required()
def scrape_tournaments():
    """触发爬取ATP赛事信息"""
    try:
        # 获取请求参数
        data = request.json or {}
        year = data.get('year', datetime.now().year)
        
        # 验证年份
        try:
            year = int(year)
            if year < 2000 or year > 2100:
                return jsonify({
                    'success': False,
                    'message': '年份必须在2000到2100之间'
                }), 400
        except (ValueError, TypeError):
            return jsonify({
                'success': False,
                'message': '无效的年份格式'
            }), 400
        
        # 创建爬虫实例
        scraper = ATPTournamentScraper()
        
        # 运行爬虫
        output_file = f"atp_tournaments_{year}.json"
        tournaments = scraper.run(year=year, output_file=output_file)
        
        return jsonify({
            'success': True,
            'message': f'成功爬取 {len(tournaments)} 个赛事信息',
            'count': len(tournaments),
            'year': year,
            'output_file': output_file
        })
        
    except Exception as e:
        logger.error(f"爬取ATP赛事信息出错: {e}")
        return jsonify({
            'success': False,
            'message': f'爬取ATP赛事信息出错: {str(e)}'
        }), 500

@atp_tournaments_bp.route('/', methods=['GET'])
def get_tournaments():
    """获取已保存的ATP赛事信息"""
    try:
        # 获取查询参数
        year = request.args.get('year', datetime.now().year)
        try:
            year = int(year)
        except (ValueError, TypeError):
            return jsonify({
                'success': False,
                'message': '无效的年份格式'
            }), 400
        
        # 创建爬虫实例（只用于连接MongoDB）
        scraper = ATPTournamentScraper()
        
        # 查询MongoDB
        tournaments = list(scraper.tournaments_collection.find(
            {'year': year},
            {'_id': 0}  # 排除MongoDB的_id字段
        ))
        
        # 处理日期格式
        for tournament in tournaments:
            if 'scraped_at' in tournament and isinstance(tournament['scraped_at'], datetime):
                tournament['scraped_at'] = tournament['scraped_at'].isoformat()
        
        return jsonify({
            'success': True,
            'count': len(tournaments),
            'year': year,
            'data': tournaments
        })
        
    except Exception as e:
        logger.error(f"获取ATP赛事信息出错: {e}")
        return jsonify({
            'success': False,
            'message': f'获取ATP赛事信息出错: {str(e)}'
        }), 500

@atp_tournaments_bp.route('/<tournament_id>', methods=['GET'])
def get_tournament_details(tournament_id):
    """获取特定ATP赛事的详细信息"""
    try:
        # 创建爬虫实例（只用于连接MongoDB）
        scraper = ATPTournamentScraper()
        
        # 查询MongoDB
        tournament = scraper.tournaments_collection.find_one(
            {'id': tournament_id},
            {'_id': 0}  # 排除MongoDB的_id字段
        )
        
        if not tournament:
            return jsonify({
                'success': False,
                'message': f'未找到ID为 {tournament_id} 的赛事'
            }), 404
        
        # 处理日期格式
        if 'scraped_at' in tournament and isinstance(tournament['scraped_at'], datetime):
            tournament['scraped_at'] = tournament['scraped_at'].isoformat()
        
        return jsonify({
            'success': True,
            'data': tournament
        })
        
    except Exception as e:
        logger.error(f"获取ATP赛事详情出错: {e}")
        return jsonify({
            'success': False,
            'message': f'获取ATP赛事详情出错: {str(e)}'
        }), 500

@atp_tournaments_bp.route('/logos', methods=['GET'])
def get_tournament_logos():
    """获取所有赛事的Logo信息"""
    try:
        # 创建爬虫实例（只用于连接MongoDB）
        scraper = ATPTournamentScraper()
        
        # 查询MongoDB
        logos = list(scraper.tournaments_collection.find(
            {'logo_url': {'$ne': None}},
            {'_id': 0, 'id': 1, 'title': 1, 'logo_url': 1}
        ))
        
        return jsonify({
            'success': True,
            'count': len(logos),
            'data': logos
        })
        
    except Exception as e:
        logger.error(f"获取ATP赛事Logo信息出错: {e}")
        return jsonify({
            'success': False,
            'message': f'获取ATP赛事Logo信息出错: {str(e)}'
        }), 500 