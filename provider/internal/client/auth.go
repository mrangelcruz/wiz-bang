package client

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

const tokenURL = "https://auth.app.wiz.io/oauth/token"

type authManager struct {
	clientID     string
	clientSecret string
	mu           sync.Mutex
	token        string
	expiry       time.Time
}

func newAuthManager(clientID, clientSecret string) *authManager {
	return &authManager{
		clientID:     clientID,
		clientSecret: clientSecret,
	}
}

// getToken returns a cached token or fetches a new one if expired.
func (a *authManager) getToken(ctx context.Context) (string, error) {
	a.mu.Lock()
	defer a.mu.Unlock()

	// Return cached token if still valid with a 60-second buffer.
	if a.token != "" && time.Now().Before(a.expiry.Add(-60*time.Second)) {
		return a.token, nil
	}

	form := url.Values{
		"grant_type":    {"client_credentials"},
		"audience":      {"wiz-api"},
		"client_id":     {a.clientID},
		"client_secret": {a.clientSecret},
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, tokenURL, strings.NewReader(form.Encode()))
	if err != nil {
		return "", fmt.Errorf("build token request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("token request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return "", fmt.Errorf("token endpoint returned HTTP %d", resp.StatusCode)
	}

	var result struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("decode token response: %w", err)
	}

	a.token = result.AccessToken
	a.expiry = time.Now().Add(time.Duration(result.ExpiresIn) * time.Second)

	return a.token, nil
}
