defmodule BlobFont.CLI do
    @moduledoc """
      BlobFont is a utility to convert BMFont files into blob
      font files.

      usage:
        bmfont-convert file
    """

    def main(args \\ [])
    def main([file]), do: convert(file)
    def main(_), do: help()

    defp help(), do: get_docs() |> SimpleMarkdown.convert(render: &SimpleMarkdownExtensionCLI.Formatter.format/1) |> IO.puts

    defp get_docs() do
        if Version.match?(System.version, "> 1.7.0") do
            { :docs_v1, _, :elixir, "text/markdown", %{ "en" => doc }, _, _ } = Code.fetch_docs(__MODULE__)
            doc
        else
            { _, doc } = Code.get_docs(__MODULE__, :moduledoc)
            doc
        end
    end

    defp convert(file) do
        File.read!(file)
        |> BMFont.parse
        |> BlobFont.convert
        |> IO.puts
    end
end
