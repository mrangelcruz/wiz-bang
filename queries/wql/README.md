# Wiz Graph Queries (WQL)

Version-controlled Wiz Query Language (WQL) queries for the Wiz Security Graph.

## Organization

Organize queries by category:

```
wql/
├── vulnerabilities/    # Vulnerability hunting queries
├── misconfigurations/  # Cloud misconfiguration queries
├── identities/         # IAM and identity queries
├── network/            # Network exposure queries
└── compliance/         # Compliance-related queries
```

## Query Format

Save queries as `.wql` files with a descriptive header:

```wql
# Query: Critical vulnerabilities in production
# Description: Finds critical CVEs on internet-exposed resources
# Author: security-team
# Last Updated: 2025-01-06

{
  "select": true,
  "type": ["VIRTUAL_MACHINE"],
  "where": {
    "vulnerabilities": {
      "severity": { "EQUALS": "CRITICAL" }
    }
  }
}
```

## Resources

- [Wiz Graph Query Documentation](https://docs.wiz.io/wiz-docs/docs/wiz-query-language)

