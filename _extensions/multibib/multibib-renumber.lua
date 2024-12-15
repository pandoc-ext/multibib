--[[
multibib-renumber – renumber numbered references and their citations

Copyright © 2018-2024 Albert Krewinkel

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

local pandoc = require 'pandoc'
local List   = require 'pandoc.List'

-- this filter should run after the multibib filter
-- (the logic is too dependent on the CSL, although it should do no harm)

-- map from reference id to its new label
local ref_map = List()

-- ref counter
local ref_counter = 1

local function collect_numbered_refs(div)
  if div.attr.classes:includes('csl-entry') then
    local identifier = div.attr.identifier
    local content = div.content
    -- expect single Para with a Span (depending on style) possibly containing
    -- the citation number (only do anything if it does)
    if (#div.content > 0 and #div.content[1].content > 0 and
        div.content[1].content[1].tag == 'Span') then
      local span = div.content[1].content[1]
      local content = span.content
      if #content > 0 then
        local text = content[1].text
        local pre, num, post = content[1].text:match("^(%p*)(%d+)(%p*)$")
        if pre and num and post then
          local ident = identifier:gsub('^ref%-', '')
          local label = string.format('%s%d%s', pre, ref_counter, post)
          content[1] = pandoc.Str(label)
          ref_map[ident] = label
          ref_counter = ref_counter + 1
          return div
        end
      end
    end
  end
end

local function renumber_cites(cite)
  -- only consider cites with single citations
  if #cite.citations == 1 then
    local id = cite.citations[1].id
    local label = ref_map[id]
    -- only change the content if the label is defined
    if label then
      cite.content = label
      return cite
    end
  end
end

return {
  { Div = collect_numbered_refs },
  { Cite = renumber_cites }
}
