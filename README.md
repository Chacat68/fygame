# fygame

基于Brackeys教程制作的游戏demo

教程地址：https://youtu.be/LOhfqjmasi0?si=qng6rKh2-j9MwLgN

这是一个基于Brackeys教程制作的游戏demo项目。通过该项目，你可以学习如何使用Godot引擎创建简单的游戏。教程地址提供了详细的教学视频，帮助你逐步完成游戏的制作过程。

![nyFavE](https://blog-1259751088.cos.ap-shanghai.myqcloud.com/uPic/nyFavE.png)

# 核心设计文档

## 模块设计
1. **角色控制模块** (player.gd)
- 双段跳机制实现
- 动画状态机管理
- 物理运动处理

2. **敌人AI模块** (slime.gd)
- 自动转向逻辑
- 射线碰撞检测
- 移动速度控制

3. **游戏管理模块** (game_manager.gd)
- 场景切换
- 分数统计
- 游戏状态管理

## 扩展规划
- 敌人基类开发
- 关卡进度系统
- 技能树系统
- 存档/读档功能
- 多人联机支持