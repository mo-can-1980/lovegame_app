from flask import Blueprint, jsonify, request
from app.utils.api_client import tennis_api
from flask_jwt_extended import jwt_required
import logging

# 配置日志
logger = logging.getLogger(__name__)

# 创建蓝图
tennis_data_bp = Blueprint('tennis_data', __name__, url_prefix='/api/tennis-data')

@tennis_data_bp.route('/tournaments/<int:year>', methods=['GET'])
def get_tournaments(year):
    """获取特定年份的赛事日历"""
    try:
        # 获取查询参数
        tour_type = request.args.get('tour_type', 'atp')
        
        # 验证tour_type
        if tour_type not in ['atp', 'wta', 'itf']:
            return jsonify({'message': '无效的tour_type参数，必须是 atp, wta, 或 itf'}), 400
        
        # 调用API
        data = tennis_api.get_tournament_calendar(tour_type, year)
        
        return jsonify({
            'success': True,
            'data': data
        })
    except Exception as e:
        logger.error(f"获取赛事日历出错: {e}")
        return jsonify({
            'success': False,
            'message': f'获取赛事日历出错: {str(e)}'
        }), 500

@tennis_data_bp.route('/tournament/<tournament_id>', methods=['GET'])
def get_tournament_details(tournament_id):
    """获取赛事详情"""
    try:
        # 获取查询参数
        tour_type = request.args.get('tour_type', 'atp')
        
        # 验证tour_type
        if tour_type not in ['atp', 'wta', 'itf']:
            return jsonify({'message': '无效的tour_type参数，必须是 atp, wta, 或 itf'}), 400
        
        # 调用API
        data = tennis_api.get_tournament_details(tour_type, tournament_id)
        
        return jsonify({
            'success': True,
            'data': data
        })
    except Exception as e:
        logger.error(f"获取赛事详情出错: {e}")
        return jsonify({
            'success': False,
            'message': f'获取赛事详情出错: {str(e)}'
        }), 500

@tennis_data_bp.route('/player/<player_id>', methods=['GET'])
def get_player_profile(player_id):
    """获取球员资料"""
    try:
        # 获取查询参数
        tour_type = request.args.get('tour_type', 'atp')
        
        # 验证tour_type
        if tour_type not in ['atp', 'wta', 'itf']:
            return jsonify({'message': '无效的tour_type参数，必须是 atp, wta, 或 itf'}), 400
        
        # 调用API
        data = tennis_api.get_player_profile(tour_type, player_id)
        
        return jsonify({
            'success': True,
            'data': data
        })
    except Exception as e:
        logger.error(f"获取球员资料出错: {e}")
        return jsonify({
            'success': False,
            'message': f'获取球员资料出错: {str(e)}'
        }), 500

@tennis_data_bp.route('/live-matches', methods=['GET'])
def get_live_matches():
    """获取正在进行的比赛"""
    try:
        # 获取查询参数
        tour_type = request.args.get('tour_type', 'atp')
        
        # 验证tour_type
        if tour_type not in ['atp', 'wta', 'itf']:
            return jsonify({'message': '无效的tour_type参数，必须是 atp, wta, 或 itf'}), 400
        
        # 调用API
        data = tennis_api.get_live_matches(tour_type)
        
        return jsonify({
            'success': True,
            'data': data
        })
    except Exception as e:
        logger.error(f"获取正在进行的比赛出错: {e}")
        return jsonify({
            'success': False,
            'message': f'获取正在进行的比赛出错: {str(e)}'
        }), 500

@tennis_data_bp.route('/clear-cache', methods=['POST'])
@jwt_required()
def clear_cache():
    """清除API缓存（需要登录权限）"""
    try:
        tennis_api.clear_cache()
        return jsonify({
            'success': True,
            'message': 'API缓存已成功清除'
        })
    except Exception as e:
        logger.error(f"清除缓存出错: {e}")
        return jsonify({
            'success': False,
            'message': f'清除缓存出错: {str(e)}'
        }), 500 