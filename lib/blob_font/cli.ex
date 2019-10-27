defmodule BlobFont.CLI do
    @moduledoc """
      BlobFont is a utility to convert BMFont files into blob
      font files.

      usage:
        blob_font [options] [file]

      Options:
      * `--help`, `-h` - Prints this message and exits
      * `--newline`, `-n` - Add a newline letter
      * `--tab`, `-t` - Add a tab letter
      * `--unicode`, `-u` - Set that the output should be unicode
      * `--ascii`, `-a` - Set that the output should be ascii
      * `--trim`, `-tr` - Trim the texture extension
      * `--name`, `-tn NAME` - Set the full texture name
      * `--letter`, `-l CHAR [-glyph x y w h] [-offset x y] [-adv advance]` - Add or modify a letter
      * `--letter-remove`, `-lr CHAR` - Remove a letter
      * `--bmfont` - Specify input type is BMFont
      * `--stdin`, `-in` - Specify that the input will be passed through stdin
    """

    def main(args \\ [], opts \\ [])
    def main([cmd|_], _) when cmd in ["-h", "--help"], do: help()
    def main([cmd|args], opts) when cmd in ["-n", "--newline"], do: main(args, [{ :letter, { ?\n, [] } }|opts])
    def main([cmd|args], opts) when cmd in ["-t", "--tab"], do: main(args, [{ :letter, { ?\t, [] } }|opts])
    def main([cmd|args], opts) when cmd in ["-u", "--unicode"], do: main(args, [{ :unicode, true }|opts])
    def main([cmd|args], opts) when cmd in ["-a", "--ascii"], do: main(args, [{ :unicode, false }|opts])
    def main([cmd|args], opts) when cmd in ["-tr", "--trim"], do: main(args, [{ :trim, true }|opts])
    def main([cmd, name|args], opts) when cmd in ["-tn", "--name"], do: main(args, [{ :name, name }|opts])
    def main([cmd, char|args], opts) when cmd in ["-l", "--letter"] do
        { args, letter_opts } = letter_options(args)
        main(args, [{ :letter, { String.to_charlist(char) |> hd, letter_opts } }|opts])
    end
    def main([cmd, char|args], opts) when cmd in ["-lr", "--letter-remove"] do
        main(args, [{ :letter, { String.to_charlist(char) |> hd, :remove } }|opts])
    end
    def main([cmd|args], opts) when cmd in ["--bmfont"], do: main(args, [{ :type, :bmfont }|opts])
    def main([cmd|args], opts) when cmd in ["-in", "--stdin"], do: main(args, [{ :stdin, true }|opts])
    def main([file], opts), do: convert(File.read!(file), Path.extname(file), opts)
    def main([], opts) do
        :ok = :io.setopts(:standard_io, encoding: :latin1)

        case opts[:stdin] && IO.binread(:all) do
            data when is_binary(data) and bit_size(data) > 0 ->
                :ok = :io.setopts(:standard_io, encoding: :utf8)
                convert(data, "", opts)
            _ ->
                :ok = :io.setopts(:standard_io, encoding: :utf8)
                help()
        end
    end
    def main(_, _), do: help()

    defp letter_options(args, opts \\ [])
    defp letter_options(["-glyph", x, y, w, h|args], opts), do: letter_options(args, [{ :glyph, { to_integer(x), to_integer(y), to_integer(w), to_integer(h) } }|opts])
    defp letter_options(["-offset", x, y|args], opts), do: letter_options(args, [{ :offset, { to_integer(x), to_integer(y) } }|opts])
    defp letter_options(["-adv", x|args], opts), do: letter_options(args, [{ :advance, to_integer(x) }|opts])
    defp letter_options(args, opts), do: { args, opts }

    defp to_integer(value) do
        { value, _ } = Integer.parse(value)
        value
    end

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

    defp modify_bmfont_char(char, [{ :glyph, { x, y, w, h } }|opts]), do: modify_bmfont_char(%{ char | x: x, y: y, width: w, height: h }, opts)
    defp modify_bmfont_char(char, [{ :offset, { x, y } }|opts]), do: modify_bmfont_char(%{ char | xoffset: x, yoffset: y }, opts)
    defp modify_bmfont_char(char, [{ :advance, x }|opts]), do: modify_bmfont_char(%{ char | xadvance: x }, opts)
    defp modify_bmfont_char(char, []), do: char

    defp modify_bmfont_char([%{ id: id }|chars], { id, :remove }, new_chars), do: new_chars ++ chars
    defp modify_bmfont_char([char = %{ id: id }|chars], { id, opts }, new_chars), do: [modify_bmfont_char(char, opts)|new_chars] ++ chars
    defp modify_bmfont_char([char|chars], letter, new_chars), do: modify_bmfont_char(chars, letter, [char|new_chars])
    defp modify_bmfont_char([], { id, opts }, new_chars), do: [modify_bmfont_char(%BMFont.Char{ id: id }, opts)|new_chars]

    defp modify_bmfont(font, [{ :letter, letter }|opts]), do: Map.update!(font, :chars, &modify_bmfont_char(&1, letter, [])) |> modify_bmfont(opts)
    defp modify_bmfont(font, [{ :unicode, unicode }|opts]), do: Map.update!(font, :info, &(%{ &1 | unicode: unicode })) |> modify_bmfont(opts)
    defp modify_bmfont(font, [{ :name, name }|opts]), do: Map.update!(font, :pages, &Enum.map(&1, fn page -> %{ page | file: name } end)) |> modify_bmfont(opts)
    defp modify_bmfont(font, [{ :trim, true }|opts]), do: Map.update!(font, :pages, &Enum.map(&1, fn page -> %{ page | file: Path.rootname(page.file) } end)) |> modify_bmfont(opts)
    defp modify_bmfont(font, [_|opts]), do: modify_bmfont(font, opts)
    defp modify_bmfont(font, []), do: font

    defp type_for_content(<<"BMF", _ :: binary>>), do: :bmfont
    defp type_for_content(_), do: nil

    defp type_for_extension(_), do: nil

    defp input_type(input, ext, opts) do
        with nil <- opts[:type],
             nil <- type_for_extension(ext),
             nil <- type_for_content(input) do
                :bmfont
        else
            type -> type
        end
    end

    defp convert(input, ext, opts) do
        case input_type(input, ext, opts) do
            :bmfont -> BMFont.parse(input) |> modify_bmfont(opts)
        end
        |> BlobFont.convert
        |> IO.puts
    end
end
