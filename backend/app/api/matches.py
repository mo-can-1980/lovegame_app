from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import matches_bp
from app.models.match import Match
from app.models.user import User

@matches_bp.route('', methods=['GET'])
def get_matches():
    """获取比赛列表，支持过滤和分页"""
    # 获取查询参数
    status = request.args.get('status')
    tournament = request.args.get('tournament')
    player = request.args.get('player')
    date = request.args.get('date')
    limit = int(request.args.get('limit', 10))
    page = int(request.args.get('page', 1))
    
    # 获取比赛列表
    matches, pagination = Match.get_all_matches(
        status=status,
        tournament=tournament,
        player=player,
        date=date,
        limit=limit,
        page=page
    )
    
    return jsonify({
        'matches': matches,
        'pagination': pagination
    })

@matches_bp.route('/live', methods=['GET'])
def get_live_matches():
    """获取正在进行的比赛"""
    matches = Match.get_live_matches()
    
    return jsonify({
        'matches': matches,
        'count': len(matches)
    })

@matches_bp.route('/<match_id>', methods=['GET'])
def get_match(match_id):
    """获取特定比赛详情"""
    match, error = Match.get_match_by_id(match_id)
    
    if not match:
        return jsonify({'message': error}), 404
    
    return jsonify(match)

@matches_bp.route('', methods=['POST'])
@jwt_required()
def create_match():
    """创建新比赛（管理员）"""
    # 检查用户是否是管理员
    user_id = get_jwt_identity()
    user = User.get_user_by_id(user_id)
    
    if not user or not user.get('is_admin'):
        return jsonify({'message': 'Unauthorized access'}), 403
    
    data = request.get_json()
    
    if not data:
        return jsonify({'message': 'No data provided'}), 400
    
    # 创建比赛
    match, error = Match.create_match(data)
    
    if not match:
        return jsonify({'message': error}), 400
    
    return jsonify({
        'message': 'Match created successfully',
        'match': match
    }), 201

@matches_bp.route('/<match_id>', methods=['PUT'])
@jwt_required()
def update_match(match_id):
    """更新比赛信息（管理员）"""
    # 检查用户是否是管理员
    user_id = get_jwt_identity()
    user = User.get_user_by_id(user_id)
    
    if not user or not user.get('is_admin'):
        return jsonify({'message': 'Unauthorized access'}), 403
    
    data = request.get_json()
    
    if not data:
        return jsonify({'message': 'No data provided'}), 400
    
    # 更新比赛
    match, error = Match.update_match(match_id, data)
    
    if not match:
        return jsonify({'message': error}), 400
    
    return jsonify({
        'message': 'Match updated successfully',
        'match': match
    })

@matches_bp.route('/<match_id>', methods=['DELETE'])
@jwt_required()
def delete_match(match_id):
    """删除比赛（管理员）"""
    # 检查用户是否是管理员
    user_id = get_jwt_identity()
    user = User.get_user_by_id(user_id)
    
    if not user or not user.get('is_admin'):
        return jsonify({'message': 'Unauthorized access'}), 403
    
    # 删除比赛
    success, error = Match.delete_match(match_id)
    
    if not success:
        return jsonify({'message': error}), 400
    
    return jsonify({'message': 'Match deleted successfully'})

@matches_bp.route('/<match_id>/score', methods=['PUT'])
@jwt_required()
def update_score(match_id):
    """更新比赛分数（管理员）"""
    # 检查用户是否是管理员
    user_id = get_jwt_identity()
    user = User.get_user_by_id(user_id)
    
    if not user or not user.get('is_admin'):
        return jsonify({'message': 'Unauthorized access'}), 403
    
    data = request.get_json()
    
    if not data or 'set_index' not in data or 'player1_score' not in data or 'player2_score' not in data:
        return jsonify({'message': 'Missing required fields'}), 400
    
    # 更新比赛分数
    match, error = Match.update_match_score(
        match_id,
        set_index=data['set_index'],
        player1_score=data['player1_score'],
        player2_score=data['player2_score'],
        player1_tiebreak=data.get('player1_tiebreak'),
        player2_tiebreak=data.get('player2_tiebreak')
    )
    
    if not match:
        return jsonify({'message': error}), 400
    
    return jsonify({
        'message': 'Match score updated successfully',
        'match': match
    })

@matches_bp.route('/<match_id>/game_score', methods=['PUT'])
@jwt_required()
def update_game_score(match_id):
    """更新当前局分数（管理员）"""
    # 检查用户是否是管理员
    user_id = get_jwt_identity()
    user = User.get_user_by_id(user_id)
    
    if not user or not user.get('is_admin'):
        return jsonify({'message': 'Unauthorized access'}), 403
    
    data = request.get_json()
    
    if not data or 'player1_points' not in data or 'player2_points' not in data:
        return jsonify({'message': 'Missing required fields'}), 400
    
    # 更新当前局分数
    match, error = Match.update_current_game_score(
        match_id,
        player1_points=data['player1_points'],
        player2_points=data['player2_points'],
        serving_player=data.get('serving_player')
    )
    
    if not match:
        return jsonify({'message': error}), 400
    
    return jsonify({
        'message': 'Game score updated successfully',
        'match': match
    }) 