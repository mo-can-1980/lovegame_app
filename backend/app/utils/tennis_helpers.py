def format_game_score(points):
    """将局内比分转换为网球计分方式 (0, 15, 30, 40, Ad)"""
    score_mapping = {
        0: '0',
        1: '15',
        2: '30',
        3: '40',
        4: 'Ad'
    }
    return score_mapping.get(points, str(points))

def is_deuce(player1_points, player2_points):
    """检查是否处于DEUCE状态（两方均不低于3分且分数相同）"""
    return player1_points >= 3 and player2_points >= 3 and player1_points == player2_points

def get_current_game_score(player1_points, player2_points):
    """获取当前局分数（考虑平分和优势情况）"""
    if is_deuce(player1_points, player2_points):
        return {'player1': '40', 'player2': '40', 'status': 'deuce'}
    
    if player1_points >= 3 and player2_points >= 3:
        if player1_points > player2_points:
            return {'player1': 'Ad', 'player2': '40', 'status': 'advantage1'}
        elif player2_points > player1_points:
            return {'player1': '40', 'player2': 'Ad', 'status': 'advantage2'}
    
    return {
        'player1': format_game_score(player1_points),
        'player2': format_game_score(player2_points),
        'status': 'normal'
    }

def is_tiebreak(player1_score, player2_score):
    """检查是否为抢七局"""
    return (player1_score == 6 and player2_score == 6) or \
           (player1_score >= 6 and player2_score >= 6)

def is_set_complete(player1_score, player2_score):
    """检查该盘是否已结束"""
    # 常规盘结束条件：一方至少获得6局且领先对手至少2局
    if (player1_score >= 6 and player1_score - player2_score >= 2) or \
       (player2_score >= 6 and player2_score - player1_score >= 2):
        return True
    
    # 抢七局结束条件：抢七获胜
    if is_tiebreak(player1_score, player2_score):
        p1_tb = player1_score > 6
        p2_tb = player2_score > 6
        
        # 在抢七中，一方至少7分且领先至少2分
        return (p1_tb and player1_score - player2_score >= 2) or \
               (p2_tb and player2_score - player1_score >= 2)
    
    return False

def get_match_status(sets, best_of=3):
    """获取比赛状态，确定获胜方或比赛是否仍在进行"""
    player1_sets = 0
    player2_sets = 0
    
    for set_data in sets:
        p1_score = set_data.get('player1_score', 0)
        p2_score = set_data.get('player2_score', 0)
        
        if is_set_complete(p1_score, p2_score):
            if p1_score > p2_score:
                player1_sets += 1
            else:
                player2_sets += 1
    
    # 确定是否有获胜者
    sets_to_win = best_of // 2 + 1
    
    if player1_sets >= sets_to_win:
        return {'status': 'completed', 'winner': 'player1', 'sets_won': [player1_sets, player2_sets]}
    elif player2_sets >= sets_to_win:
        return {'status': 'completed', 'winner': 'player2', 'sets_won': [player1_sets, player2_sets]}
    else:
        return {'status': 'in_progress', 'sets_won': [player1_sets, player2_sets]} 