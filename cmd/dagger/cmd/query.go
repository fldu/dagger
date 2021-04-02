package cmd

import (
	"fmt"

	"cuelang.org/go/cue"
	"dagger.io/go/cmd/dagger/cmd/common"
	"dagger.io/go/cmd/dagger/logger"
	"dagger.io/go/dagger"
	"dagger.io/go/dagger/compiler"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var queryCmd = &cobra.Command{
	Use:   "query [TARGET] [flags]",
	Short: "Query the contents of a deployment",
	Args:  cobra.MaximumNArgs(1),
	PreRun: func(cmd *cobra.Command, args []string) {
		// Fix Viper bug for duplicate flags:
		// https://github.com/spf13/viper/issues/233
		if err := viper.BindPFlags(cmd.Flags()); err != nil {
			panic(err)
		}
	},
	Run: func(cmd *cobra.Command, args []string) {
		lg := logger.New()
		ctx := lg.WithContext(cmd.Context())

		cueOpts := parseQueryFlags()

		store, err := dagger.DefaultStore()
		if err != nil {
			lg.Fatal().Err(err).Msg("failed to load store")
		}

		deployment := common.GetCurrentDeployment(ctx, store)

		lg = lg.With().
			Str("deploymentName", deployment.Name()).
			Str("deploymentId", deployment.ID()).
			Logger()

		cuePath := cue.MakePath()
		if len(args) > 0 {
			cuePath = cue.ParsePath(args[0])
		}

		c, err := dagger.NewClient(ctx, "")
		if err != nil {
			lg.Fatal().Err(err).Msg("unable to create client")
		}
		output, err := c.Do(ctx, deployment, nil)
		if err != nil {
			lg.Fatal().Err(err).Msg("failed to query deployment")
		}

		cueVal := output.LookupPath(cuePath)

		if viper.GetBool("concrete") {
			if err := cueVal.IsConcreteR(); err != nil {
				lg.Fatal().Err(compiler.Err(err)).Msg("not concrete")
			}
		}

		out, err := cueVal.Source(cueOpts...)
		if err != nil {
			lg.Fatal().Err(err).Msg("failed to lookup source")
		}

		fmt.Println(string(out))
	},
}

func parseQueryFlags() []cue.Option {
	opts := []cue.Option{
		cue.Definitions(true),
	}

	if viper.GetBool("concrete") {
		opts = append(opts, cue.Concrete(true))
	}

	if viper.GetBool("show-optional") {
		opts = append(opts, cue.Optional(true))
	}

	if viper.GetBool("show-attributes") {
		opts = append(opts, cue.Attributes(true))
	}

	return opts
}

func init() {
	queryCmd.Flags().BoolP("concrete", "c", false, "Require the evaluation to be concrete")
	queryCmd.Flags().BoolP("show-optional", "O", false, "Display optional fields")
	queryCmd.Flags().BoolP("show-attributes", "A", false, "Display field attributes")

	// FIXME: implement the flags below
	// queryCmd.Flags().String("revision", "latest", "Query a specific version of the deployment")
	// queryCmd.Flags().StringP("format", "f", "", "Output format (json|yaml|cue|text|env)")
	// queryCmd.Flags().BoolP("no-input", "I", false, "Exclude inputs from query")
	// queryCmd.Flags().BoolP("no-output", "O", false, "Exclude outputs from query")
	// queryCmd.Flags().BoolP("no-plan", "P", false, "Exclude outputs from query")

	if err := viper.BindPFlags(queryCmd.Flags()); err != nil {
		panic(err)
	}
}