# Tennis App Backend

这是Tennis App的后端服务，提供API接口给Flutter客户端使用。

## 目录结构

```
backend/
  ├── src/               # 源代码
  │   ├── controllers/   # 控制器/路由处理
  │   ├── models/        # 数据模型
  │   ├── services/      # 业务逻辑服务
  │   └── utils/         # 工具函数
  ├── config/            # 配置文件
  ├── tests/             # 测试文件
  └── public/            # 静态资源
```

## 技术栈

- Node.js
- Express.js
- MongoDB
- WebSocket (用于实时比分更新)

## API接口

### 比赛相关

- `GET /api/matches` - 获取比赛列表
- `GET /api/matches/:id` - 获取比赛详情
- `GET /api/matches/live` - 获取实时比赛

### 用户相关

- `POST /api/users/register` - 用户注册
- `POST /api/users/login` - 用户登录
- `GET /api/users/profile` - 获取用户资料

## 开发说明

1. 安装依赖: `npm install`
2. 开发环境运行: `npm run dev`
3. 生产环境构建: `npm run build`
4. 生产环境运行: `npm start`

## 数据模型

### Match (比赛)

```javascript
{
  id: String,
  player1: Player,
  player2: Player,
  scores: [Set],
  status: String, // "upcoming", "live", "completed"
  startTime: Date,
  tournament: Tournament,
  round: String
}
```

### Player (球员)

```javascript
{
  id: String,
  name: String,
  country: String,
  rank: Number,
  image: String
}
``` 