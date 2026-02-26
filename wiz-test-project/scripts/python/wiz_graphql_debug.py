#!/usr/bin/env python3
import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, Optional

import requests


DEFAULT_TOKEN_URL = "https://auth.app.wiz.io/oauth/token"
FILTER_RE = re.compile(r"(azure|deployment|connector|cloudAccount|cloud|subscription)", re.I)

# Mutations we want to deeply introspect (follow all nested INPUT_OBJECT types)
DEEP_INTROSPECT_ROOTS = [
    "CreateConnectorInput",
    "UpdateConnectorInput",
]

INTROSPECTION_MUTATIONS = """
query IntrospectMutations {
  __schema {
    mutationType {
      fields {
        name
        args {
          name
          type { kind name ofType { kind name ofType { kind name } } }
        }
      }
    }
  }
}
"""

INTROSPECT_TYPE_QUERY = """
query IntrospectInputType($name: String!) {
  __type(name: $name) {
    name
    kind
    description
    inputFields {
      name
      description
      defaultValue
      type {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
            }
          }
        }
      }
    }
    enumValues {
      name
      description
    }
  }
}
"""

TYPENAME_QUERY = {"query": "query { __typename }"}


def env_or_fail(name: str) -> str:
    v = os.getenv(name)
    if not v:
        print(f"ERROR: missing required env var {name}", file=sys.stderr)
        sys.exit(1)
    return v


def fetch_token(token_url: str, client_id: str, client_secret: str, timeout: int) -> str:
    payload = {
        "grant_type": "client_credentials",
        "audience": "wiz-api",
        "client_id": client_id,
        "client_secret": client_secret,
    }

    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
    }

    r = requests.post(
        token_url,
        data=payload,
        headers=headers,
        timeout=timeout,
    )

    if r.status_code >= 400:
        # Safe error reporting
        try:
            j = r.json()
            raise RuntimeError(
                f"Token request failed: HTTP {r.status_code} "
                f"error={j.get('error')} desc={j.get('error_description')}"
            )
        except ValueError:
            raise RuntimeError(
                f"Token request failed: HTTP {r.status_code} body={r.text[:120]!r}"
            )

    j = r.json()
    token = j.get("access_token")
    if not token:
        raise RuntimeError(f"Token response missing access_token. Keys={list(j.keys())}")

    return token

def gql(api_url: str, token: str, query: str, variables: Optional[Dict[str, Any]], timeout: int) -> Dict[str, Any]:
    r = requests.post(
        api_url,
        json={"query": query, "variables": variables or {}},
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        timeout=timeout,
    )
    if r.status_code >= 400:
        raise RuntimeError(f"GraphQL HTTP error {r.status_code}: {r.text}")
    return r.json()


def write_json(path: Path, obj: Any) -> None:
    path.write_text(json.dumps(obj, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _unwrap_type_name(type_node: Optional[Dict[str, Any]]) -> Optional[str]:
    """Walk NON_NULL / LIST wrappers to find the named type."""
    while type_node is not None:
        if type_node.get("name"):
            return type_node["name"]
        type_node = type_node.get("ofType")
    return None


def introspect_type_deep(
    api_url: str,
    token: str,
    root_name: str,
    timeout: int,
    out_dir: Path,
) -> Dict[str, Any]:
    """
    Recursively introspect an INPUT_OBJECT (or ENUM) type and all INPUT_OBJECT
    types reachable from its inputFields.  Returns a dict keyed by type name.
    """
    visited: Dict[str, Any] = {}
    queue = [root_name]

    while queue:
        name = queue.pop(0)
        if name in visited:
            continue

        result = gql(api_url, token, INTROSPECT_TYPE_QUERY, {"name": name}, timeout)
        type_def = (result.get("data") or {}).get("__type")
        if not type_def:
            visited[name] = None
            continue

        visited[name] = type_def

        # Enqueue any INPUT_OBJECT fields we haven't seen yet
        for field in type_def.get("inputFields") or []:
            child_name = _unwrap_type_name(field.get("type"))
            if child_name and child_name not in visited:
                # Only follow non-scalar types (scalars have no inputFields)
                child_result = gql(
                    api_url, token, INTROSPECT_TYPE_QUERY, {"name": child_name}, timeout
                )
                child_def = (child_result.get("data") or {}).get("__type")
                if child_def and child_def.get("kind") in ("INPUT_OBJECT", "ENUM"):
                    queue.append(child_name)

    return visited


def main() -> None:
    ap = argparse.ArgumentParser(description="Debug Wiz GraphQL: sanity + introspect mutation names")
    ap.add_argument("--api-url", default=os.getenv("WIZ_API_URL"), help="Wiz GraphQL URL (or env WIZ_API_URL)")
    ap.add_argument("--token-url", default=os.getenv("WIZ_TOKEN_URL", DEFAULT_TOKEN_URL))
    ap.add_argument("--out-dir", default=os.getenv("WIZ_DEBUG_OUT_DIR", "wiz_debug_out"))
    ap.add_argument("--timeout-seconds", type=int, default=int(os.getenv("WIZ_TIMEOUT_SECONDS", "30")))
    args = ap.parse_args()

    api_url = args.api_url or ""
    if not api_url:
        print("ERROR: provide --api-url or set WIZ_API_URL", file=sys.stderr)
        sys.exit(1)

    client_id = env_or_fail("WIZ_CLIENT_ID")
    client_secret = env_or_fail("WIZ_CLIENT_SECRET")

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    token = fetch_token(args.token_url, client_id, client_secret, args.timeout_seconds)

    # Sanity check
    typename = gql(api_url, token, TYPENAME_QUERY["query"], None, args.timeout_seconds)
    write_json(out_dir / "wiz_typename.json", typename)

    if "errors" in typename and typename["errors"]:
        print("ERROR: __typename query returned errors", file=sys.stderr)
        print(json.dumps(typename["errors"], indent=2), file=sys.stderr)
        sys.exit(1)

    # Introspect mutations
    intro = gql(api_url, token, INTROSPECTION_MUTATIONS, None, args.timeout_seconds)
    write_json(out_dir / "wiz_introspection_mutations.json", intro)

    if "errors" in intro and intro["errors"]:
        print("ERROR: introspection returned errors", file=sys.stderr)
        print(json.dumps(intro["errors"], indent=2), file=sys.stderr)
        sys.exit(1)

    fields = intro["data"]["__schema"]["mutationType"]["fields"] or []
    names = sorted({f["name"] for f in fields if FILTER_RE.search(f["name"])})

    (out_dir / "wiz_mutations_filtered.txt").write_text("\n".join(names) + "\n", encoding="utf-8")

    print("Wiz GraphQL OK. Filtered mutation names:")
    for n in names:
        print(n)

    # Deep introspect each root input type
    combined: Dict[str, Any] = {}
    for root_name in DEEP_INTROSPECT_ROOTS:
        print(f"\nDeep introspecting {root_name} ...")
        type_map = introspect_type_deep(api_url, token, root_name, args.timeout_seconds, out_dir)
        combined.update(type_map)
        for type_name, type_def in type_map.items():
            safe_name = re.sub(r"[^A-Za-z0-9_\-]", "_", type_name)
            write_json(out_dir / f"wiz_type_{safe_name}.json", type_def)
            status = "OK" if type_def else "NOT FOUND"
            print(f"  {type_name}: {status}")

    write_json(out_dir / "wiz_types_combined.json", combined)
    print(f"\nWrote {len(combined)} types to {out_dir}/wiz_types_combined.json")


if __name__ == "__main__":
    main()
