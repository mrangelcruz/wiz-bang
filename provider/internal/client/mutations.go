package client

import "context"

// GraphQL mutations and queries for Azure connectors.
// These will be populated once wiz_types_combined.json is generated
// from the introspection workflow and the exact input schema is known.

// TODO: replace stub fields with real ones from wiz_types_combined.json

const queryListConnectors = `
query ListConnectors {
  connectors {
    nodes {
      id
      name
      type
      enabled
      status
    }
  }
}
`

// AzureConnector represents a Wiz Azure connector as returned by the API.
// Fields will be expanded once introspection output is available.
type AzureConnector struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Type    string `json:"type"`
	Enabled bool   `json:"enabled"`
	Status  string `json:"status"`
}

// ListConnectors returns all connectors visible to the service account.
// Used during development to validate API connectivity and inspect live data.
func (c *Client) ListConnectors(ctx context.Context) ([]AzureConnector, error) {
	var result struct {
		Connectors struct {
			Nodes []AzureConnector `json:"nodes"`
		} `json:"connectors"`
	}

	if err := c.Query(ctx, queryListConnectors, nil, &result); err != nil {
		return nil, err
	}

	return result.Connectors.Nodes, nil
}
