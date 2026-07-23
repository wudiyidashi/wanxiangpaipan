# Domain 层规范索引

领域层（`lib/domain/`）纯函数服务与业务规则约定。

| 文档 | 内容 |
|-----|------|
| [liuyao-analysis-engine.md](liuyao-analysis-engine.md) | 六爻断卦分析引擎：规则基准（增删卜易）、派生数据不落库、可空参数扩展、应期日历匹配约定 |

## 通用约定（来自 CLAUDE.md，此处仅索引）

- Domain services 必须是纯静态函数，无副作用、不直接访问数据
- 跨系统共享逻辑（干支/五行/六亲/农历）放 `lib/domain/services/shared/`
- 系统专属服务放 `lib/domain/services/<system>/`（对齐 daliuren/ 先例）
