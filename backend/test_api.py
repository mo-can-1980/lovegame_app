'''
Descripttion: 
Author: ouchao
Email: ouchao@sendpalm.com
version: 1.0
Date: 2025-04-16 11:29:20
LastEditors: ouchao
LastEditTime: 2025-04-16 14:07:05
'''
import http.client
import json
import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def test_tennis_api():
    """测试RapidAPI的网球API接口"""
    # 设置API连接
    conn = http.client.HTTPSConnection("tennis-api-atp-wta-itf.p.rapidapi.com")
    
    # 设置请求头
    headers = {
        'x-rapidapi-key': "40c6cdc8d0msh20d3ced0ae2a262p18f4f9jsn8adaef19622c",
        'x-rapidapi-host': "tennis-api-atp-wta-itf.p.rapidapi.com"
    }
    
    try:
        # 发送请求获取2025年ATP赛事日历
        print("正在请求 2025年ATP赛事日历...")
        conn.request("GET", "/tennis/v2/atp/tournament/calendar/2025", headers=headers)
        
        # 获取响应
        res = conn.getresponse()
        data = res.read()
        
        # 解析并格式化输出响应
        decoded_data = data.decode("utf-8")
        
        # 保存响应到文件
        with open('api_response.json', 'w') as f:
            f.write(decoded_data)
        
        # 尝试解析JSON并格式化打印
        try:
            json_data = json.loads(decoded_data)
            print("\n状态码:", res.status)
            print("响应头:", res.getheaders())
            print("\n响应成功! 数据已保存到 api_response.json")
            
            # 打印数据概要
            if isinstance(json_data, dict):
                print("\n数据概要:")
                if "tournaments" in json_data:
                    tournaments = json_data.get("tournaments", [])
                    print(f"共获取 {len(tournaments)} 个赛事")
                    
                    if tournaments:
                        print("\n前3个赛事:")
                        for i, tournament in enumerate(tournaments[:3]):
                            print(f"{i+1}. {tournament.get('name', 'N/A')} - {tournament.get('location', 'N/A')}")
        except json.JSONDecodeError:
            print("响应不是有效的JSON格式，原始响应:")
            print(decoded_data)
            
    except Exception as e:
        print(f"请求出错: {e}")
    finally:
        # 关闭连接
        conn.close()

if __name__ == "__main__":
    test_tennis_api() 