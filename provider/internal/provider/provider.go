package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/geico-private/wiz/provider/internal/client"
)

var _ provider.Provider = &WizAzureProvider{}

type WizAzureProvider struct {
	version string
}

type WizAzureProviderModel struct {
	ClientID     types.String `tfsdk:"client_id"`
	ClientSecret types.String `tfsdk:"client_secret"`
	ApiURL       types.String `tfsdk:"api_url"`
}

func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &WizAzureProvider{version: version}
	}
}

func (p *WizAzureProvider) Metadata(_ context.Context, _ provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "wiz-azure"
	resp.Version = p.version
}

func (p *WizAzureProvider) Schema(_ context.Context, _ provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Provider for managing Wiz Azure connectors.",
		Attributes: map[string]schema.Attribute{
			"client_id": schema.StringAttribute{
				Required:    true,
				Description: "Wiz service account Client ID.",
			},
			"client_secret": schema.StringAttribute{
				Required:    true,
				Sensitive:   true,
				Description: "Wiz service account Client Secret.",
			},
			"api_url": schema.StringAttribute{
				Required:    true,
				Description: "Wiz GraphQL API URL (e.g. https://api.us9.app.wiz.io/graphql).",
			},
		},
	}
}

func (p *WizAzureProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	var config WizAzureProviderModel
	diags := req.Config.Get(ctx, &config)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	c, err := client.New(
		config.ClientID.ValueString(),
		config.ClientSecret.ValueString(),
		config.ApiURL.ValueString(),
	)
	if err != nil {
		resp.Diagnostics.AddError("Failed to create Wiz client", err.Error())
		return
	}

	// Pass the client to resources and data sources.
	resp.ResourceData = c
	resp.DataSourceData = c
}

func (p *WizAzureProvider) Resources(_ context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		// Uncomment as resources are implemented:
		// azure_connector.NewResource,
	}
}

func (p *WizAzureProvider) DataSources(_ context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{}
}
