// introspect is a CLI tool that BFS-walks Wiz GraphQL input types and writes
// the full field schema to JSON files. Output feeds provider schema development.
//
// Usage:
//
//	go run ./tools/introspect \
//	  --api-url  https://api.us9.app.wiz.io/graphql \
//	  --out-dir  ./tools/introspect/out
//
// Required env vars: WIZ_CLIENT_ID, WIZ_CLIENT_SECRET
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/geico-private/wiz/provider/internal/client"
)

// ---------------------------------------------------------------------------
// GraphQL introspection query — resolves a single named type with all fields.
// Unwraps up to 4 levels of NON_NULL / LIST wrappers (sufficient for Wiz API).
// Fetches inputFields (INPUT_OBJECT), fields (OBJECT), possibleTypes (UNION/INTERFACE),
// and enumValues (ENUM) so the BFS covers both mutation inputs and query return types.
// ---------------------------------------------------------------------------
// queryIntrospectTypeTemplate inlines the type name directly — the Wiz GraphQL
// API does not apply variables to __type introspection queries.
const queryIntrospectTypeTemplate = `
{
  __type(name: "%s") {
    name
    kind
    description
    inputFields {
      name
      description
      type {
        kind name
        ofType {
          kind name
          ofType {
            kind name
            ofType {
              kind name
            }
          }
        }
      }
    }
    fields {
      name
      description
      type {
        kind name
        ofType {
          kind name
          ofType {
            kind name
            ofType {
              kind name
            }
          }
        }
      }
    }
    possibleTypes {
      kind
      name
    }
    enumValues {
      name
      description
    }
  }
}
`

// ---------------------------------------------------------------------------
// Response types
// ---------------------------------------------------------------------------

type TypeRef struct {
	Kind   string   `json:"kind"`
	Name   string   `json:"name"`
	OfType *TypeRef `json:"ofType"`
}

// leafName unwraps NON_NULL / LIST wrappers and returns the named type.
func (t *TypeRef) leafName() string {
	if t == nil {
		return ""
	}
	if t.Kind == "NON_NULL" || t.Kind == "LIST" {
		return t.OfType.leafName()
	}
	return t.Name
}

type InputField struct {
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Type        TypeRef `json:"type"`
}

type EnumValue struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

type WizType struct {
	Name          string       `json:"name"`
	Kind          string       `json:"kind"`
	Description   string       `json:"description"`
	InputFields   []InputField `json:"inputFields"`
	Fields        []InputField `json:"fields"`        // OBJECT types
	PossibleTypes []TypeRef    `json:"possibleTypes"` // UNION / INTERFACE types
	EnumValues    []EnumValue  `json:"enumValues"`
}

type introspectResponse struct {
	Type *WizType `json:"__type"`
}

// ---------------------------------------------------------------------------
// BFS walker
// ---------------------------------------------------------------------------

// seeds are the root types for BFS traversal.
// Mutation input seeds (INPUT_OBJECT) cover create/update/delete shapes.
// Connector (OBJECT) is the read-side return type; BFS from it discovers
// ConnectorConfigAzure and sibling cloud config types via possibleTypes.
var seeds = []string{
	// Mutation inputs
	"CreateConnectorInput",
	"UpdateConnectorInput",
	"DeleteConnectorInput",
	// Read-side return type
	"Connector",
}

func walk(ctx context.Context, c *client.Client) (map[string]*WizType, error) {
	visited := make(map[string]bool)
	results := make(map[string]*WizType)
	queue := append([]string{}, seeds...)

	for len(queue) > 0 {
		name := queue[0]
		queue = queue[1:]

		if visited[name] || name == "" {
			continue
		}
		visited[name] = true

		fmt.Printf("[INFO] introspecting: %s\n", name)
		time.Sleep(200 * time.Millisecond)

		var resp introspectResponse
		err := c.Query(ctx, fmt.Sprintf(queryIntrospectTypeTemplate, name), nil, &resp)
		if err != nil {
			return nil, fmt.Errorf("query %s: %w", name, err)
		}

		if resp.Type == nil {
			fmt.Printf("[WARN] type not found: %s\n", name)
			continue
		}

		results[name] = resp.Type

		// Enqueue nested types we haven't visited yet.
		// inputFields → INPUT_OBJECT mutation inputs
		for _, field := range resp.Type.InputFields {
			leaf := field.Type.leafName()
			if leaf != "" && !visited[leaf] && !isScalar(leaf) {
				queue = append(queue, leaf)
			}
		}
		// fields → OBJECT query return types (e.g. Connector → ConnectorConfig*)
		for _, field := range resp.Type.Fields {
			leaf := field.Type.leafName()
			if leaf != "" && !visited[leaf] && !isScalar(leaf) {
				queue = append(queue, leaf)
			}
		}
		// possibleTypes → UNION / INTERFACE concrete implementations
		// (e.g. ConnectorConfig union → ConnectorConfigAzure, ConnectorConfigAWS, ...)
		for _, pt := range resp.Type.PossibleTypes {
			if pt.Name != "" && !visited[pt.Name] {
				queue = append(queue, pt.Name)
			}
		}
	}

	return results, nil
}

// isScalar returns true for built-in GraphQL scalars that need no introspection.
func isScalar(name string) bool {
	scalars := map[string]bool{
		"String": true, "Boolean": true, "Int": true,
		"Float": true, "ID": true, "DateTime": true,
		"JSON": true, "Upload": true,
	}
	return scalars[name]
}

// ---------------------------------------------------------------------------
// Output helpers
// ---------------------------------------------------------------------------

func writeJSON(path string, v any) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	return enc.Encode(v)
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

func main() {
	apiURL  := flag.String("api-url",  os.Getenv("WIZ_API_URL"),  "Wiz GraphQL URL")
	authURL := flag.String("auth-url", os.Getenv("WIZ_AUTH_URL"), "Wiz OAuth2 token URL (default: https://auth.app.wiz.io/oauth/token)")
	outDir  := flag.String("out-dir",  "tools/introspect/out",    "Output directory for JSON files")
	flag.Parse()

	clientID := os.Getenv("WIZ_CLIENT_ID")
	clientSecret := os.Getenv("WIZ_CLIENT_SECRET")

	if clientID == "" || clientSecret == "" {
		fmt.Fprintln(os.Stderr, "[ERROR] WIZ_CLIENT_ID and WIZ_CLIENT_SECRET must be set")
		os.Exit(1)
	}
	if *apiURL == "" {
		fmt.Fprintln(os.Stderr, "[ERROR] --api-url or WIZ_API_URL must be set")
		os.Exit(1)
	}

	if err := os.MkdirAll(*outDir, 0o755); err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] create output dir: %v\n", err)
		os.Exit(1)
	}

	c, err := client.NewWithAuthURL(clientID, clientSecret, *apiURL, *authURL)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] create client: %v\n", err)
		os.Exit(1)
	}

	ctx := context.Background()

	fmt.Printf("[INFO] starting BFS introspection from seeds: %s\n", strings.Join(seeds, ", "))

	types, err := walk(ctx, c)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] introspection failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("[INFO] discovered %d types\n", len(types))

	// Write individual type files.
	for name, t := range types {
		path := filepath.Join(*outDir, fmt.Sprintf("wiz_type_%s.json", name))
		if err := writeJSON(path, t); err != nil {
			fmt.Fprintf(os.Stderr, "[ERROR] write %s: %v\n", path, err)
			os.Exit(1)
		}
		fmt.Printf("[INFO] wrote: %s\n", path)
	}

	// Write combined rollup.
	combined := filepath.Join(*outDir, "wiz_types_combined.json")
	if err := writeJSON(combined, types); err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] write combined: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("[INFO] wrote combined: %s\n", combined)
	fmt.Println("[INFO] introspection complete")
}
