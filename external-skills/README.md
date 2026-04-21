# External Skills

此目录已废弃。外部技能现在加载到 `skills/ext-<id>/` 目录。

## 使用方法

使用 `/summ:find-skill <关键词>` 搜索并加载技能。

## 调用已加载的技能

```
summ:ext-<skill-id>
```

## 目录结构

```
skills/
├── ext-<skill-id>/
│   └── SKILL.md
└── ...
```

## 注意事项

- 加载的技能保留在 `skills/ext-*` 供后续使用（已加入 .gitignore）
- 注意查看技能的 risk 级别
- critical 级别技能请谨慎使用
