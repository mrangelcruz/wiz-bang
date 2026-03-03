package client

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// Client is the Wiz GraphQL API client used by all provider resources.
type Client struct {
	apiURL     string
	httpClient *http.Client
	auth       *authManager
}

func New(clientID, clientSecret, apiURL string) (*Client, error) {
	if clientID == "" || clientSecret == "" || apiURL == "" {
		return nil, fmt.Errorf("client_id, client_secret, and api_url are all required")
	}
	return &Client{
		apiURL:     apiURL,
		httpClient: &http.Client{Timeout: 30 * time.Second},
		auth:       newAuthManager(clientID, clientSecret),
	}, nil
}

type gqlRequest struct {
	Query     string         `json:"query"`
	Variables map[string]any `json:"variables,omitempty"`
}

type gqlResponse struct {
	Data   json.RawMessage `json:"data"`
	Errors []gqlError      `json:"errors"`
}

type gqlError struct {
	Message string `json:"message"`
}

// Query executes a GraphQL query or mutation and unmarshals the response data into out.
func (c *Client) Query(ctx context.Context, query string, variables map[string]any, out any) error {
	token, err := c.auth.getToken(ctx)
	if err != nil {
		return fmt.Errorf("auth: %w", err)
	}

	body, err := json.Marshal(gqlRequest{Query: query, Variables: variables})
	if err != nil {
		return fmt.Errorf("marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.apiURL, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("execute request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("HTTP %d from Wiz API", resp.StatusCode)
	}

	var gqlResp gqlResponse
	if err := json.NewDecoder(resp.Body).Decode(&gqlResp); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}

	if len(gqlResp.Errors) > 0 {
		return fmt.Errorf("GraphQL error: %s", gqlResp.Errors[0].Message)
	}

	if out != nil {
		if err := json.Unmarshal(gqlResp.Data, out); err != nil {
			return fmt.Errorf("unmarshal data: %w", err)
		}
	}

	return nil
}
