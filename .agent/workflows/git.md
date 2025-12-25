---
description: Git workflow for ZendyKey development
---

# Git Workflow

## Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

## Commit Changes
```bash
git add .
git commit -m "feat: your message"
```

## Push Branch
```bash
git push -u origin feature/your-feature-name
```

## Create Release Tag
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## Commit Message Conventions
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Tests
- `chore:` Maintenance
