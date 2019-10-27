defmodule BlobFont do
    @spec convert(BMFont.t) :: String.t
    def convert(font) do
        args =
            [font.info, font.common, font.pages, font.chars, font.kernings]
            |> List.flatten
            |> Enum.sort(fn
                %BMFont.Info{}, _ -> true
                _, %BMFont.Info{} -> false
                %BMFont.Common{}, _ -> true
                _, %BMFont.Common{} -> false
                %BMFont.Page{}, _ -> true
                _, %BMFont.Page{} -> false
                %BMFont.Char{ id: a }, %BMFont.Char{ id: b } -> a < b
                %BMFont.Char{}, _ -> true
                _, %BMFont.Char{} -> false
                a, b -> a > b
            end)

        %BMFont.Common{ height: tex_height } = Enum.find(args, fn
            %BMFont.Common{} -> true
            _ -> false
        end)

        convert(args |> Enum.map(fn
            chr = %BMFont.Char{ y: y, height: h } -> %BMFont.Char{ chr | y: tex_height - y - h }
            arg -> arg
        end), "")
    end

    defp convert([], script), do: script <> ")"
    defp convert([%BMFont.Info{ face: face, size: size, bold: bold, italic: italic, unicode: unicode }|args], script) do
        style = cond do
            bold and italic -> " (style: :bold :italic)"
            bold -> " (style: :bold)"
            italic -> " (style: :italic)"
            true -> ""
        end
        unicode = if unicode, do: "(unicode: #t)", else: "(unicode: #f)"

        convert(args, script <> """
        (font \"#{face}\" #{size}#{style}
            #{unicode}
        """)
    end
    defp convert([%BMFont.Common{ line_height: line_height, base: base, pages: 1 }|args], script) do
        convert(args, script <> """
            (line-height: #{line_height})
            (base: #{base})
        """)
    end
    defp convert([%BMFont.Page{ file: file }|args], script) do
        convert(args, script <> """
            (texture \"#{file}\")
        """)
    end
    defp convert([%BMFont.Char{ id: id, x: x, y: y, width: w, height: h, xoffset: xoffset, yoffset: yoffset, xadvance: xadvance }|args], script) do
        letter = case [id] do
            '\\' -> '\\\\'
            '"' -> '\\"'
            c -> c
        end
        convert(args, script <> "    (letter: \"#{letter}\" (glyph: #{x} #{y} #{w} #{h}) (offset: #{xoffset} #{yoffset}) (advance: #{xadvance}))\n")
    end
    defp convert([_|args], script), do: convert(args, script)
end
