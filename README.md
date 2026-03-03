# Wiz Management Repository

Central repository for managing Wiz CSPM configurations, automation, and policies as code.

## Repository Structure

```
wiz/
├── terraform/          # Infrastructure as Code for Wiz configuration
├── scripts/python/     # Python scripts for Wiz API automation
├── queries/wql/        # Saved Wiz Graph (WQL) queries
└── policies/custom/    # Custom security policy definitions
```

## Getting Started

| Area | Documentation |
|------|---------------|
| **Terraform** | [`terraform/README.md`](terraform/README.md) |
| **Python Scripts** | [`scripts/python/README.md`](scripts/python/README.md) |
| **WQL Queries** | [`queries/wql/README.md`](queries/wql/README.md) |
| **Custom Policies** | [`policies/custom/README.md`](policies/custom/README.md) |

## Authentication

Wiz credentials are stored in `.env.wiz` (gitignored). Source before running commands:

```bash
source .env.wiz
```

## Contributing

1. Create a feature branch
2. Source credentials: `source .env.wiz`
3. Make changes and test
4. Submit a pull request

