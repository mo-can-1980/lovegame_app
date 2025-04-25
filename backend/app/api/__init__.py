from flask import Blueprint

# 创建蓝图
matches_bp = Blueprint('matches', __name__, url_prefix='/api/matches')
users_bp = Blueprint('users', __name__, url_prefix='/api/users')

# 导入视图函数
from . import matches
from . import users 