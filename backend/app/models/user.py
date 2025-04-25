import datetime
import bcrypt
from bson import ObjectId
from app import mongo

class User:
    """用户模型类"""
    
    collection = mongo.db.users
    
    @staticmethod
    def create_user(username, email, password, profile_picture='default.jpg', is_admin=False):
        """创建新用户"""
        # 检查是否已存在相同用户名或邮箱的用户
        if User.collection.find_one({'username': username}):
            return None, 'Username already exists'
        
        if User.collection.find_one({'email': email}):
            return None, 'Email already exists'
        
        # 密码加密
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        
        user = {
            'username': username,
            'email': email,
            'password': hashed_password,
            'profile_picture': profile_picture,
            'favorite_matches': [],
            'is_admin': is_admin,
            'created_at': datetime.datetime.utcnow(),
            'updated_at': datetime.datetime.utcnow()
        }
        
        # 插入数据库
        result = User.collection.insert_one(user)
        
        # 获取新创建的用户并返回
        new_user = User.collection.find_one({'_id': result.inserted_id})
        
        return User._format_user(new_user), None
    
    @staticmethod
    def get_user_by_id(user_id):
        """通过ID获取用户"""
        user = User.collection.find_one({'_id': ObjectId(user_id)})
        if not user:
            return None
        
        return User._format_user(user)
    
    @staticmethod
    def get_user_by_username(username):
        """通过用户名获取用户"""
        user = User.collection.find_one({'username': username})
        if not user:
            return None
        
        return User._format_user(user)
    
    @staticmethod
    def get_user_by_email(email):
        """通过邮箱获取用户"""
        user = User.collection.find_one({'email': email})
        if not user:
            return None
        
        return User._format_user(user)
    
    @staticmethod
    def authenticate(email, password):
        """用户认证"""
        user = User.collection.find_one({'email': email})
        if not user:
            return None, 'Invalid email or password'
        
        # 验证密码
        if not bcrypt.checkpw(password.encode('utf-8'), user['password']):
            return None, 'Invalid email or password'
        
        return User._format_user(user), None
    
    @staticmethod
    def update_user(user_id, update_data):
        """更新用户信息"""
        # 不允许更新的字段
        disallowed_fields = ['_id', 'password', 'created_at']
        
        # 移除不允许更新的字段
        update_data = {k: v for k, v in update_data.items() if k not in disallowed_fields}
        
        # 添加更新时间
        update_data['updated_at'] = datetime.datetime.utcnow()
        
        # 更新用户
        result = User.collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': update_data}
        )
        
        if result.modified_count == 0:
            return None, 'User not found or no changes made'
        
        # 获取更新后的用户
        updated_user = User.collection.find_one({'_id': ObjectId(user_id)})
        
        return User._format_user(updated_user), None
    
    @staticmethod
    def add_favorite_match(user_id, match_id):
        """添加收藏比赛"""
        result = User.collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$addToSet': {'favorite_matches': ObjectId(match_id)}}
        )
        
        if result.modified_count == 0:
            return False, 'User not found or match already in favorites'
        
        return True, None
    
    @staticmethod
    def remove_favorite_match(user_id, match_id):
        """移除收藏比赛"""
        result = User.collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$pull': {'favorite_matches': ObjectId(match_id)}}
        )
        
        if result.modified_count == 0:
            return False, 'User not found or match not in favorites'
        
        return True, None
    
    @staticmethod
    def _format_user(user):
        """格式化用户数据，移除敏感信息"""
        if not user:
            return None
        
        # 格式化输出，删除密码等敏感字段
        user_data = {
            'id': str(user['_id']),
            'username': user['username'],
            'email': user['email'],
            'profile_picture': user['profile_picture'],
            'favorite_matches': [str(match_id) for match_id in user.get('favorite_matches', [])],
            'is_admin': user.get('is_admin', False),
            'created_at': user.get('created_at', datetime.datetime.utcnow()).isoformat(),
            'updated_at': user.get('updated_at', datetime.datetime.utcnow()).isoformat()
        }
        
        return user_data 