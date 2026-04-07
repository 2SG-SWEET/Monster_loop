---
name: "game-code-implementation"
description: "实现游戏功能代码，包括游戏逻辑、系统模块、工具脚本等。当用户需要编写游戏功能代码、修复bug、重构代码或实现特定游戏机制时调用此技能。"
---

# 游戏代码实现

## 职责
负责编写高质量、可维护的游戏功能代码。

## 工作范围

1. **游戏逻辑**
   - 核心玩法实现
   - 游戏规则系统
   - 状态管理

2. **系统模块**
   - 存档系统
   - 音频系统
   - 输入系统
   - UI系统

3. **工具脚本**
   - 编辑器扩展
   - 自动化工具
   - 数据导入导出

4. **性能优化**
   - 代码优化
   - 内存管理
   - 算法改进

## 编码规范

### 命名规范
```csharp
// 类名：PascalCase
public class PlayerController { }

// 方法名：PascalCase
public void TakeDamage(int damage) { }

// 变量名：camelCase
private int currentHealth;

// 常量名：ALL_CAPS
public const int MAX_HEALTH = 100;

// 私有字段：_camelCase
private string _playerName;
```

### 代码结构
```csharp
public class Example : MonoBehaviour {
    #region Fields
    [SerializeField] private int health;
    #endregion

    #region Properties
    public int Health => health;
    #endregion

    #region Unity Lifecycle
    private void Awake() { }
    private void Start() { }
    private void Update() { }
    #endregion

    #region Public Methods
    public void TakeDamage(int damage) { }
    #endregion

    #region Private Methods
    private void Die() { }
    #endregion
}
```

## 实现流程

1. **需求分析**
   - 理解功能需求
   - 明确输入输出
   - 识别边界情况

2. **设计**
   - 确定类/模块结构
   - 设计接口
   - 考虑扩展性

3. **编码**
   - 遵循编码规范
   - 编写清晰注释
   - 保持代码简洁

4. **测试**
   - 单元测试
   - 集成测试
   - 边界测试

5. **优化**
   - 性能分析
   - 代码重构
   - 内存优化

## 最佳实践

1. **单一职责原则**
   - 每个类/方法只做一件事
   - 避免 God Class

2. **依赖注入**
   - 减少硬编码依赖
   - 提高可测试性

3. **事件驱动**
   - 使用事件/委托解耦
   - 避免紧耦合

4. **对象池**
   - 频繁创建销毁的对象使用对象池
   - 减少GC压力

5. **配置化**
   - 关键数值配置化
   - 便于策划调整

## 注意事项
- 优先使用项目现有代码风格
- 保持向后兼容性
- 编写足够的注释
- 考虑多平台兼容性
