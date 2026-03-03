package main

import (
	"context"
	"flag"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/mrangelcruz/terraform-provider-wiz-azure/internal/provider"
)

// version is set at build time via -ldflags.
var version string = "dev"

func main() {
	var debug bool
	flag.BoolVar(&debug, "debug", false, "run provider with debugger support (delve)")
	flag.Parse()

	opts := providerserver.ServeOpts{
		Address: "local/geico/wiz-azure",
		Debug:   debug,
	}

	err := providerserver.Serve(context.Background(), provider.New(version), opts)
	if err != nil {
		log.Fatal(err.Error())
	}
}
