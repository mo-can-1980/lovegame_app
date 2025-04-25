import datetime
from bson import ObjectId
from app import mongo

class Match:
    """比赛模型类"""
    
    collection = mongo.db.matches
    
    @staticmethod
    def get_all_matches(status=None, tournament=None, player=None, date=None, limit=10, page=1):
        """获取比赛列表，支持分页和过滤"""
        # 构建查询条件
        query = {}
        
        if status:
            query['status'] = status
        
        if tournament:
            query['tournament.name'] = {'$regex': tournament, '$options': 'i'}
        
        if player:
            query['$or'] = [
                {'player1.name': {'$regex': player, '$options': 'i'}},
                {'player2.name': {'$regex': player, '$options': 'i'}}
            ]
        
        if date:
            start_date = datetime.datetime.strptime(date, '%Y-%m-%d')
            end_date = start_date + datetime.timedelta(days=1)
            query['start_time'] = {'$gte': start_date, '$lt': end_date}
        
        # 计算跳过的文档数
        skip = (page - 1) * limit
        
        # 获取匹配的总数
        total = Match.collection.count_documents(query)
        
        # 获取分页结果
        cursor = Match.collection.find(query).sort('start_time', 1).skip(skip).limit(limit)
        
        # 格式化结果
        matches = [Match._format_match(match) for match in cursor]
        
        # 构建分页信息
        pagination = {
            'total': total,
            'page': page,
            'limit': limit,
            'pages': (total + limit - 1) // limit  # 向上取整
        }
        
        return matches, pagination
    
    @staticmethod
    def get_live_matches():
        """获取正在进行的比赛"""
        cursor = Match.collection.find({'status': 'Live'}).sort('start_time', 1)
        return [Match._format_match(match) for match in cursor]
    
    @staticmethod
    def get_match_by_id(match_id):
        """通过ID获取比赛"""
        try:
            match = Match.collection.find_one({'_id': ObjectId(match_id)})
            if not match:
                return None, 'Match not found'
            
            return Match._format_match(match), None
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def create_match(match_data):
        """创建新比赛"""
        try:
            # 添加创建和更新时间
            match_data['created_at'] = datetime.datetime.utcnow()
            match_data['updated_at'] = datetime.datetime.utcnow()
            
            # 确保start_time是datetime对象
            if 'start_time' in match_data and isinstance(match_data['start_time'], str):
                match_data['start_time'] = datetime.datetime.fromisoformat(match_data['start_time'].replace('Z', '+00:00'))
            
            # 插入数据库
            result = Match.collection.insert_one(match_data)
            
            # 获取新创建的比赛
            new_match = Match.collection.find_one({'_id': result.inserted_id})
            
            return Match._format_match(new_match), None
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def update_match(match_id, update_data):
        """更新比赛信息"""
        try:
            # 添加更新时间
            update_data['updated_at'] = datetime.datetime.utcnow()
            
            # 确保start_time是datetime对象
            if 'start_time' in update_data and isinstance(update_data['start_time'], str):
                update_data['start_time'] = datetime.datetime.fromisoformat(update_data['start_time'].replace('Z', '+00:00'))
            
            # 更新比赛
            result = Match.collection.update_one(
                {'_id': ObjectId(match_id)},
                {'$set': update_data}
            )
            
            if result.modified_count == 0:
                return None, 'Match not found or no changes made'
            
            # 获取更新后的比赛
            updated_match = Match.collection.find_one({'_id': ObjectId(match_id)})
            
            return Match._format_match(updated_match), None
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def delete_match(match_id):
        """删除比赛"""
        try:
            result = Match.collection.delete_one({'_id': ObjectId(match_id)})
            
            if result.deleted_count == 0:
                return False, 'Match not found'
            
            return True, None
        except Exception as e:
            return False, str(e)
    
    @staticmethod
    def update_match_score(match_id, set_index, player1_score, player2_score, 
                            player1_tiebreak=None, player2_tiebreak=None):
        """更新比赛分数"""
        try:
            update_data = {
                f'sets.{set_index}.player1_score': player1_score,
                f'sets.{set_index}.player2_score': player2_score,
                'updated_at': datetime.datetime.utcnow()
            }
            
            # 如果有抢七分数，也更新
            if player1_tiebreak is not None and player2_tiebreak is not None:
                update_data[f'sets.{set_index}.tiebreak_points.player1'] = player1_tiebreak
                update_data[f'sets.{set_index}.tiebreak_points.player2'] = player2_tiebreak
            
            result = Match.collection.update_one(
                {'_id': ObjectId(match_id)},
                {'$set': update_data}
            )
            
            if result.modified_count == 0:
                return None, 'Match not found or no changes made'
            
            # 获取更新后的比赛
            updated_match = Match.collection.find_one({'_id': ObjectId(match_id)})
            
            return Match._format_match(updated_match), None
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def update_current_game_score(match_id, player1_points, player2_points, serving_player=None):
        """更新当前局分数"""
        try:
            update_data = {
                'current_game_score.player1': player1_points,
                'current_game_score.player2': player2_points,
                'updated_at': datetime.datetime.utcnow()
            }
            
            # 如果提供了发球方信息，也更新
            if serving_player is not None:
                update_data['serving_player'] = serving_player
            
            result = Match.collection.update_one(
                {'_id': ObjectId(match_id)},
                {'$set': update_data}
            )
            
            if result.modified_count == 0:
                return None, 'Match not found or no changes made'
            
            # 获取更新后的比赛
            updated_match = Match.collection.find_one({'_id': ObjectId(match_id)})
            
            return Match._format_match(updated_match), None
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def _format_match(match):
        """格式化比赛数据以便输出"""
        if not match:
            return None
        
        # 将_id转换为字符串
        formatted_match = dict(match)
        formatted_match['id'] = str(formatted_match.pop('_id'))
        
        # 格式化日期时间
        for key in ['start_time', 'end_time', 'created_at', 'updated_at']:
            if key in formatted_match and formatted_match[key]:
                formatted_match[key] = formatted_match[key].isoformat()
        
        # 格式化亮点ID
        if 'highlights' in formatted_match and formatted_match['highlights']:
            for highlight in formatted_match['highlights']:
                if '_id' in highlight:
                    highlight['id'] = str(highlight.pop('_id'))
        
        return formatted_match 