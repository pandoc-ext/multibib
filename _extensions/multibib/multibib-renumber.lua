--[[
multibib-renumber – renumber numbered references and their citations

Copyright © 2024 William Lupton and contributors

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

local stringify = pandoc.utils.stringify

-- logging
local script_dir = require('pandoc.path').directory(PANDOC_SCRIPT_FILE)
package.path = string.format('%s/?.lua;%s/../?.lua;%s/../scripts/?.lua;%s',
                             script_dir, script_dir, script_dir, package.path)
local logging = require 'logging'
logging.setlogprefix()
if false then logging.setloglevel(1) end

-- this filter should run after the multibib filter
-- (the logic is too dependent on the CSL, although it should do no harm)

-- map from reference id to its new label
local ref_map = List()

-- ref counter
local ref_counter = 1

-- pass 1: process references:
-- * populate ref_map, mapping reference ids to their new labels (numbers)
-- * modify reference labels to be the new numbers
--
-- this will operate on divs (created by citeproc) like this one (markdown):
--
-- ::: {#ref-Bel .csl-entry}
-- [\[1\] ]{.csl-left-margin}[Bellori, *Le vite de' pittori, scultori e
-- architetti moderni*, 1672]{.csl-right-inline}
-- :::
local function collect_refs(div)
  if div.attr.classes:includes('csl-entry') then
    logging.debug('csl entry', div)
    local identifier = div.attr.identifier
    local content = div.content
    -- expect single Para with a Span (depending on style) possibly containing
    -- the citation number (only do anything if it does)
    if (#div.content > 0 and #div.content[1].content > 0 and
        div.content[1].content[1].tag == 'Span') then
      local span = div.content[1].content[1]
      local content = span.content
      if #content > 0 then
        local id = identifier:gsub('^ref%-', '')
        local text = content[1].text
        local pre, num, post = content[1].text:match("^(%p*)(%d+)(%p*)$")
        if pre and num and post then
          -- replace num with the current ref counter (1, 2, ...)
          local label = string.format('%s%d%s', pre, ref_counter, post)
          content[1] = pandoc.Str(label)
          ref_map[id] = tostring(ref_counter)
          logging.info('collect refs', 'id', id, 'label', text, '->', label)
          ref_counter = ref_counter + 1
          return div
        end
      end
    end
  end
end

-- pass 2: process citations:
-- * for each citation, use ref_map to find its new label (number)
-- * update the citation content to use the new label (this is the messy bit,
--   because we have to do string processing, which we do at the Str level so
--   as to retain formatting, links etc.)
--
-- for example, given '([3, Knu86]; [1, Bae])', map the '3' in '[3,' to '1'
-- and the '[1,' to '3', resulting in '([4, Knu86]; [3, Bae])'
local function renumber_cites(cite)
  logging.debug('cite', cite)
  local content = cite.content
  local changed = false
  for _, citation in ipairs(cite.citations) do
    local id = citation.id
    local label = ref_map[id]
    -- only change the content if the label is defined
    if label then
      local found = false

      -- only substitute the first, because we assume that the citations are
      -- referenced in the content in citation order (see below for the other
      -- trick)
      -- XXX the opening '[' should be configurable
      local function substitute_first(str)
        if not found then
          local pre, num, post =
            str.text:match('^(.-%[)(%d+)(%D)')
          if pre and num and post then
            -- the other trick is that we use '!label!' to avoid the
            -- substituted value from being substituted again
            local text = pre .. '!' .. label .. '!' .. post
            logging.debug('citation id', id, 'label', label, str, '->', text)
            str.text = text
            found = true
            return str
          end
        end
      end

      content = content:walk({Str = substitute_first})
      if found then
        changed = true
      end
    end
  end

  if changed then
    -- map '!label!' back to 'label'
    content = content:walk({Str = function(str)
                              str.text = str.text:gsub('!(%d+)!', '%1')
                              return str end})
    logging.info('renumber cites', stringify(cite.content), '->',
                 stringify(content))
    cite.content = content
    return cite
  end
end

return {
  { Div = collect_refs },
  { Cite = renumber_cites }
}
