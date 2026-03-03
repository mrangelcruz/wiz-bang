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


if __name__ == "__main__":
    main()


