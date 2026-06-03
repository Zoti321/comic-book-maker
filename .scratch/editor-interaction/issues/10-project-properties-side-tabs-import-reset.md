Category: enhancement
Status: done

# 项目属性侧边 Tab 与修改导入格式清空

## What to build

将「项目属性」对话框改为与新建向导**共用侧边 Tab 壳层**，分 Tab 展示并可编辑工作流设置；修改导入格式时按产品规则**清空**项目内容。

**对话框 Tab（属性）**

1. **概览**：项目名称、页数、封面页、最近更新（以只读为主）
2. **导入**：可修改 `inferred_import_kind`（导入格式）
3. **导出**：与新建向导相同的 Export 与工作流字段（格式、容器、扩展名、路径、导出后删除）
4. **元数据**：推断类型说明、导入元数据快照摘要（保持 03 行为）

**修改导入格式**

- 用户更改 `inferred_import_kind` 前：强确认，明确说明将删除**全部**已导入 Page 与相关 Metadata，项目变为空（无 Page Image、无可编辑书目元数据），需用户自行重新导入
- 确认后：Core 删除全部 Page 与 Asset Reference，Metadata 重置为默认（如标题可保留或一并重置——实现时选一种并在 UI 文案中写清）
- 属性内**不**提供「再选文件导入」；清空后用户通过编辑页追加 / 图片 Tab 等重新导入

**范围外**

- 画廊「添加页面」仅图片（11）
- 按导入格式限制其它选择器（11）

## Acceptance criteria

- [x] 项目属性使用左侧 Tab 切换四个分区，布局与新建向导壳层一致
- [x] 导出 Tab 修改的字段与 06、08 一致且持久化
- [x] 修改导入格式并确认后，Page 列表为空，Metadata 处于文档化的空项目状态
- [x] 取消确认则不修改导入格式且不删除内容
- [x] 确认文案明确「需重新导入」，无静默清空

## Blocked by

- [06-project-workflow-settings-persistence.md](06-project-workflow-settings-persistence.md)
- [09-create-project-wizard-library-entry.md](09-create-project-wizard-library-entry.md)
