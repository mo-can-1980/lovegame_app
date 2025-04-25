from flask import request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from app.api import users_bp
from app.models.user import User

@users_bp.route('/register', methods=['POST'])
def register():
    """注册新用户"""
    data = request.get_json()
    
    # 验证必要字段
    if not data or not all(k in data for k in ('username', 'email', 'password')):
        return jsonify({'message': 'Missing required fields'}), 400
    
    # 创建用户
    user, error = User.create_user(
        username=data['username'],
        email=data['email'],
        password=data['password'],
        profile_picture=data.get('profile_picture', 'default.jpg')
    )
    
    if not user:
        return jsonify({'message': error}), 400
    
    # 生成JWT token
    access_token = create_access_token(identity=user['id'])
    
    return jsonify({
        'message': 'User registered successfully',
        'user': user,
        'access_token': access_token
    }), 201

@users_bp.route('/login', methods=['POST'])
def login():
    """用户登录"""
    data = request.get_json()
    
    # 验证必要字段
    if not data or not all(k in data for k in ('email', 'password')):
        return jsonify({'message': 'Missing email or password'}), 400
    
    # 验证用户
    user, error = User.authenticate(data['email'], data['password'])
    
    if not user:
        return jsonify({'message': error}), 401
    
    # 生成JWT token
    access_token = create_access_token(identity=user['id'])
    
    return jsonify({
        'message': 'Login successful',
        'user': user,
        'access_token': access_token
    })

@users_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    """获取当前用户资料"""
    user_id = get_jwt_identity()
    user = User.get_user_by_id(user_id)
    
    if not user:
        return jsonify({'message': 'User not found'}), 404
    
    return jsonify(user)

@users_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """更新当前用户资料"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if not data:
        return jsonify({'message': 'No data provided'}), 400
    
    user, error = User.update_user(user_id, data)
    
    if not user:
        return jsonify({'message': error}), 400
    
    return jsonify({
        'message': 'Profile updated successfully',
        'user': user
    })

@users_bp.route('/favorites', methods=['GET'])
@jwt_required()
def get_favorites():
    """获取用户收藏的比赛"""
    user_id = get_jwt_identity()
    user = User.get_user_by_id(user_id)
    
    if not user:
        return jsonify({'message': 'User not found'}), 404
    
    return jsonify({
        'favorite_matches': user['favorite_matches']
    })

@users_bp.route('/favorites/<match_id>', methods=['POST'])
@jwt_required()
def add_favorite(match_id):
    """添加比赛到收藏"""
    user_id = get_jwt_identity()
    success, error = User.add_favorite_match(user_id, match_id)
    
    if not success:
        return jsonify({'message': error}), 400
    
    return jsonify({'message': 'Match added to favorites'})

@users_bp.route('/favorites/<match_id>', methods=['DELETE'])
@jwt_required()
def remove_favorite(match_id):
    """从收藏中移除比赛"""
    user_id = get_jwt_identity()
    success, error = User.remove_favorite_match(user_id, match_id)
    
    if not success:
        return jsonify({'message': error}), 400
    
    return jsonify({'message': 'Match removed from favorites'})

# 管理员路由
@users_bp.route('/admin/users', methods=['GET'])
@jwt_required()
def get_all_users():
    """获取所有用户（管理员专用）"""
    user_id = get_jwt_identity()
    user = User.get_user_by_id(user_id)
    
    if not user or not user.get('is_admin'):
        return jsonify({'message': 'Unauthorized access'}), 403
    
    # 这里应该有分页逻辑，简化版本省略
    users_cursor = User.collection.find()
    users = [User._format_user(user) for user in users_cursor]
    
    return jsonify({
        'users': users,
        'count': len(users)
    }) 