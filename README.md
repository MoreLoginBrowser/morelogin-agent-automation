# MoreLogin + Agent Browser Complete Practical Guide

> Version: 2.0  
> Updated: 2026-02-28  
> Author: AI Assistant + MoreLogin  
> Status: ✅ Verified by real tests

This repository README is the primary entry document for MoreLogin + Agent-Browser workflows.

## Quick Start

```bash
# 1) Install dependencies
npm install -g agent-browser@0.3.2
agent-browser install

# 2) Configure env (example)
cp .env.example .env 2>/dev/null || true
```

```bash
# 3) Run examples
bash ./examples/workflow-a-basic-browser-automation.sh
```

## Scripts Included

- `examples/workflow-a-basic-browser-automation.sh`
- `examples/workflow-c-cloudphone-adb.sh`
- `examples/case-1-google-search.sh`
- `examples/case-3-data-extraction.sh`

## Security Notes (Before GitHub Upload)

- Do not commit production `envId`, API keys, proxy credentials, or account credentials.
- Use `.env` / environment variables for sensitive values.
- Add `.env*` and secret files to `.gitignore`.
- Review staged changes before pushing:

```bash
git status
git diff --staged
```

## Pinned Dependency Versions

```json
{
  "name": "morelogin-agentbrowser-workflows",
  "private": true,
  "type": "module",
  "scripts": {
    "workflow:a": "bash ./examples/workflow-a-basic-browser-automation.sh"
  },
  "dependencies": {
    "dotenv": "16.4.7"
  },
  "devDependencies": {
    "@playwright/test": "1.51.1",
    "tsx": "4.19.2"
  }
}
```

## Full Guide

For the complete long-form reference (architecture, API details, troubleshooting table, advanced tips), see:

- `MoreLogin-AgentBrowser-Complete-Guide.md`
