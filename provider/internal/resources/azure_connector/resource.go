package azure_connector

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
)

var _ resource.Resource = &AzureConnectorResource{}

type AzureConnectorResource struct {
	// client will be *client.Client once wired up
}

// NewResource returns a new AzureConnectorResource.
// Uncomment in provider.go Resources() when ready.
func NewResource() resource.Resource {
	return &AzureConnectorResource{}
}

func (r *AzureConnectorResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_azure_connector"
}

func (r *AzureConnectorResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	// TODO: populate from wiz_types_combined.json once introspection is run.
	resp.Schema = schema.Schema{
		Description: "Manages a Wiz Azure subscription connector.",
		Attributes:  map[string]schema.Attribute{
			// Fields will be added here once the CreateConnectorInput schema is known.
		},
	}
}

func (r *AzureConnectorResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	// TODO: implement createConnector mutation
}

func (r *AzureConnectorResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	// TODO: implement connector read/refresh
}

func (r *AzureConnectorResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	// TODO: implement updateConnector mutation
}

func (r *AzureConnectorResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	// TODO: implement deleteConnector mutation
}

func (r *AzureConnectorResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
	// TODO: implement import by connector ID
}
