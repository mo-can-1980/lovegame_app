'''
Descripttion: 
Author: ouchao
Email: ouchao@sendpalm.com
version: 1.0
Date: 2025-04-16 16:09:46
LastEditors: ouchao
LastEditTime: 2025-04-17 10:58:02
'''
import json
import re
from datetime import datetime

def process_tournament_dates(date_str):
    """
    处理赛事日期字符串，提取开始和结束日期
    支持四种格式:
    1. "15 January, 2025 - 28 January, 2025" (跨月完整格式)
    2. "1-7 January, 2025" (同月简短格式)
    3. "31 December, 2024 - 7 January, 2025" (跨年格式)
    4. "31 March - 6 April, 2025" (跨月简短格式)
    """
    if not date_str:
        return None, None

    try:
        # 模式1：跨月或跨年完整格式 
        # 例如："15 January, 2025 - 28 January, 2025" 或 "31 December, 2024 - 7 January, 2025"
        pattern1 = r'(\d+)\s+([A-Za-z]+),\s*(\d{4})\s*-\s*(\d+)\s+([A-Za-z]+),\s*(\d{4})'
        match1 = re.search(pattern1, date_str)
        if match1:
            start_day = int(match1.group(1))
            start_month = match1.group(2)
            start_year = int(match1.group(3))
            end_day = int(match1.group(4))
            end_month = match1.group(5)
            end_year = int(match1.group(6))
            
            start_date = datetime.strptime(f"{start_day} {start_month} {start_year}", "%d %B %Y")
            end_date = datetime.strptime(f"{end_day} {end_month} {end_year}", "%d %B %Y")
            return start_date, end_date

        # 模式2：同月简短格式
        # 例如："1-7 January, 2025"
        pattern2 = r'(\d+)-(\d+)\s+([A-Za-z]+),\s*(\d{4})'
        match2 = re.search(pattern2, date_str)
        if match2:
            start_day = int(match2.group(1))
            end_day = int(match2.group(2))
            month = match2.group(3)
            year = int(match2.group(4))
            
            start_date = datetime.strptime(f"{start_day} {month} {year}", "%d %B %Y")
            end_date = datetime.strptime(f"{end_day} {month} {year}", "%d %B %Y")
            return start_date, end_date

        # 模式3：跨月简短格式
        # 例如："31 March - 6 April, 2025"
        pattern3 = r'(\d+)\s+([A-Za-z]+)\s*-\s*(\d+)\s+([A-Za-z]+),\s*(\d{4})'
        match3 = re.search(pattern3, date_str)
        if match3:
            start_day = int(match3.group(1))
            start_month = match3.group(2)
            end_day = int(match3.group(3))
            end_month = match3.group(4)
            year = int(match3.group(5))
            
            start_date = datetime.strptime(f"{start_day} {start_month} {year}", "%d %B %Y")
            end_date = datetime.strptime(f"{end_day} {end_month} {year}", "%d %B %Y")
            return start_date, end_date

        raise ValueError(f"不支持的日期格式: {date_str}")

    except Exception as e:
        print(f"处理日期字符串出错 '{date_str}': {str(e)}")
        return None, None

def process_atp_data(input_file, output_file):
    # 读取JSON文件
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # 处理每个项目
    for item in data['TournamentDates']:
        for it in item['Tournaments']:
            # 处理FormattedDate转换为startDate和endDate
            if 'FormattedDate' in it:
                date_str = it['FormattedDate']
                
                # 情况1: "27 December, 2024 - 5 January, 2025"
                # 情况2: "6 - 11 January, 2025"
                # 情况3: "31 March - 6 April, 2025"
                date_match = re.search(r'(\d+)\s+([A-Za-z]+),\s*(\d{4})\s*-\s*(\d+)\s+([A-Za-z]+),\s*(\d{4})', date_str)
                if date_match:
                    start_day = int(date_match.group(1))
                    start_month = date_match.group(2)
                    start_year = date_match.group(3)
                    end_day = int(date_match.group(4))
                    end_month = date_match.group(5)
                    end_year = date_match.group(6)
                    
                    # 转换月份名称为数字
                    start_month_num = datetime.strptime(start_month, '%B').month
                    end_month_num = datetime.strptime(end_month, '%B').month
                    
                    # 创建日期格式
                    it['startDate'] = f"{start_year}-{start_month_num:02d}-{start_day:02d}"
                    it['endDate'] = f"{end_year}-{end_month_num:02d}-{end_day:02d}"
                else:
                    # 情况2: "6 - 11 January, 2025"
                    date_match = re.search(r'(\d+)\s*-\s*(\d+)\s+([A-Za-z]+),\s*(\d{4})', date_str)
                    if date_match:
                        start_day = int(date_match.group(1))
                        end_day = int(date_match.group(2))
                        month = date_match.group(3)
                        year = date_match.group(4)
                        
                        # 转换月份名称为数字
                        try:
                            month_num = datetime.strptime(month, '%B').month
                        except ValueError:
                            month_num = datetime.strptime(month, '%b').month
                        
                        # 创建日期格式
                        it['startDate'] = f"{year}-{month_num:02d}-{start_day:02d}"
                        it['endDate'] = f"{year}-{month_num:02d}-{end_day:02d}"
                    else:
                        pattern3 = r'(\d+)\s+([A-Za-z]+)\s*-\s*(\d+)\s+([A-Za-z]+),\s*(\d{4})'
                        date_match = re.search(pattern3, date_str)
                        if date_match:
                            start_day = int(date_match.group(1))
                            start_month = date_match.group(2)
                            end_day = int(date_match.group(3))
                            end_month = date_match.group(4)
                            year = date_match.group(5)

                            # 转换月份名称为数字
                            start_month_num = datetime.strptime(start_month, '%B').month
                            end_month_num = datetime.strptime(end_month, '%B').month
                            # 创建日期格式
                            it['startDate'] = f"{year}-{start_month_num:02d}-{start_day:02d}"
                            it['endDate'] = f"{year}-{end_month_num:02d}-{end_day:02d}"
                        else:
                            print(f"无法处理日期格式: {date_str}")

            
        # 处理URL，添加前缀
        if 'Url' in item and not item['Url'].startswith(('http://', 'https://')):
            item['Url'] = f"https://www.atptour.com{item['Url']}"
        
        # 处理DisplayDate，提取月份和年份
        if 'DisplayDate' in item:
            display_date = item['DisplayDate']
            print(f"DisplayDate: {display_date}")
            # 提取月份和年份（如"December, 2024"）
            date_match = re.search(r'([A-Za-z]+),\s*(\d{4})', display_date)
            if date_match:
                month_name = date_match.group(1)
                year = date_match.group(2)
                
                # 获取月份数字
                try:
                    month_num = datetime.strptime(month_name, '%B').month
                except ValueError:
                    # 尝试简写月份
                    try:
                        month_num = datetime.strptime(month_name, '%b').month
                    except ValueError:
                        month_num = 0
                
                item['month'] = month_num
                item['year'] = int(year)
    print(f"处理完成，已保存到 {data}")
    # 保存处理后的数据
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"处理完成，已保存到 {output_file}")

if __name__ == "__main__":
    input_file = "/Users/liubei/lovegame/backend/app/2025atp_tournaments.json"  # 输入文件路径
    output_file = "processed_atp_tournaments.json"  # 输出文件路径
    process_atp_data(input_file, output_file) 