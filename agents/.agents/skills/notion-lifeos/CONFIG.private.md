# Notion LifeOS - 私密配置

**注意**：此文件包含真实的数据库 ID，不要提交到 Git！

## 数据库 ID 映射（嘉豪专用）

| 数据库 | database_id (创建页面用) | data_source_id (查询用) |
|--------|--------------------------|-------------------------|
| Task | `25b119f1-93ef-804a-96fe-c277cc6b45fa` | `25b119f1-93ef-800c-8553-000b29174668` |
| Notes | `25b119f1-93ef-80ee-9cb1-e5b92a8ca6ac` | `25b119f1-93ef-81c1-92e0-000b3e41b6b2` |
| Areas | `23b119f1-93ef-8025-86e7-c14df9a231ae` | `23b119f1-93ef-81a0-b66d-000b305e4f4b` |
| Resources | `25b119f1-93ef-80dd-8497-ccd9f1b901e4` | `25b119f1-93ef-81ab-9763-000b4769af23` |
| Projects | `23b119f1-93ef-80c5-887a-c91078b1e06f` | `23b119f1-93ef-818d-94f1-000bc7ab78e8` |
| Make Time | `25b119f1-93ef-8022-ae70-ce8534b84435` | `25b119f1-93ef-8086-a05f-000b460defc3` |

LifeOS 根页面：`f41afd0d-524b-468f-9c34-78877b7c76d1`

## 使用方式

在 SKILL.md 中使用占位符 `YOUR_*_DATABASE_ID`，实际使用时 OpenClaw 会从此文件读取真实 ID。

或者，你可以直接在 SKILL.md 中替换占位符为上述真实 ID（但不要提交到 Git）。
