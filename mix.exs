defmodule BlobFont.Mixfile do
    use Mix.Project

    def project do
        [
            app: :blob_font,
            description: "A library to convert BMFont files to blob font files",
            version: "0.1.0",
            elixir: "~> 1.7",
            start_permanent: Mix.env == :prod,
            deps: deps(),
            package: package(),
            escript: escript(),
            dialyzer: [plt_add_deps: :transitive]
        ]
    end

    # Run "mix help compile.app" to learn about applications.
    def application do
        [extra_applications: [:logger]]
    end

    # Run "mix help deps" to learn about dependencies.
    defp deps do
        [
            { :bmfont, "~> 0.1.0" },
            { :simple_markdown, "~> 0.6" },
            { :simple_markdown_extension_cli, "~> 0.1.3" },
            { :ex_doc, "~> 0.18", only: :dev }
        ]
    end

    defp package do
        [
            maintainers: ["Stefan Johnson"],
            licenses: ["BSD 2-Clause"],
            links: %{ "GitHub" => "https://github.com/ScrimpyCat/BlobFont" }
        ]
    end

    defp escript do
        [
            main_module: BlobFont.CLI,
            strip_beam: false
        ]
    end
end
