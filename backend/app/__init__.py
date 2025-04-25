import os
from flask import Flask
from flask_pymongo import PyMongo
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_socketio import SocketIO
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 初始化MongoDB
mongo = PyMongo()

# 初始化JWT
jwt = JWTManager()

# 初始化SocketIO
socketio = SocketIO()

# 导入蓝图
from app.api.auth import auth_bp
from app.api.user import user_bp
from app.api.matches import matches_bp
from app.api.players import players_bp
from app.api.atp_tournaments import atp_tournaments_bp

def create_app(test_config=None):
    # 创建Flask应用
    app = Flask(__name__, instance_relative_config=True)
    
    # 配置应用
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev'),
        MONGO_URI=os.environ.get('MONGO_URI', 'mongodb://localhost:27017/tennisapp'),
        JWT_SECRET_KEY=os.environ.get('JWT_SECRET_KEY', 'dev'),
        JWT_ACCESS_TOKEN_EXPIRES=int(os.environ.get('JWT_ACCESS_TOKEN_EXPIRES', 604800)),
    )
    
    # 如果提供了测试配置，则使用测试配置
    if test_config is not None:
        app.config.update(test_config)
    
    # 确保实例文件夹存在
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass
    
    # 初始化CORS
    CORS(app)
    
    # 初始化MongoDB
    mongo.init_app(app)
    
    # 初始化JWT
    jwt.init_app(app)
    
    # 初始化SocketIO
    socketio.init_app(app, cors_allowed_origins="*")
    
    # 注册API蓝图
    app.register_blueprint(auth_bp)
    app.register_blueprint(user_bp)
    app.register_blueprint(matches_bp)
    app.register_blueprint(players_bp)
    app.register_blueprint(atp_tournaments_bp)
    
    # 根路由，健康检查
    @app.route('/')
    def index():
        return {'message': 'Tennis App API Server is running'}
    
    return app 