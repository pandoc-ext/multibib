# multibib

[![GitHub build status][CI badge]][CI workflow]

This filter allows to create multiple bibliographies using
`citeproc`. The content of each bibliography is controlled via
YAML values and the file in which a bibliographic entry is
specified.

[CI badge]: https://img.shields.io/github/actions/workflow/status/pandoc-ext/multibib/ci.yaml?logo=github&branch=main
[CI workflow]: https://github.com/pandoc-ext/multibib/actions/workflows/ci.yaml

The bibliographies must be defined in a map below the
`bibliography` key in the document's metadata. E.g.

```yaml
---
bibliography:
  main: main-bibliography.bib
  software: software.bib
---
```

The placement of bibliographies is controlled via special divs.

``` markdown
# References

::: {#refs-main}
:::

# Software

::: {#refs-software}
:::
```

Each refs-*x* div should have a matching entry *x* in the
metadata. These divs are filled with citations from the respective
bib-file.

> [!IMPORTANT]
> This filter works best with citation styles that use non-numeric
> citation labels.


Usage
------------------------------------------------------------------

The filter modifies the internal document representation; it can
be used with many publishing systems that are based on pandoc.

### Plain pandoc

Pass the filter to pandoc via the `--lua-filter` (or `-L`) command
line option.

    pandoc --lua-filter multibib.lua ...

### Quarto

Users of Quarto can install this filter as an extension with

    quarto install extension pandoc-ext/multibib

and use it by adding `multibib` to the `filters` entry
in their YAML header. (You also need to add `validate-yaml: false`, as per [this discussion](https://github.com/quarto-dev/quarto-cli/issues/4139).)

``` yaml
---
filters:
  - multibib
validate-yaml: false
---
```

### R Markdown

Use `pandoc_args` to invoke the filter. See the [R Markdown
Cookbook](https://bookdown.org/yihui/rmarkdown-cookbook/lua-filters.html)
for details.

``` yaml
---
output:
  word_document:
    pandoc_args: ['--lua-filter=multibib.lua']
---
```

License
------------------------------------------------------------------

This pandoc Lua filter is published under the MIT license, see
file `LICENSE` for details.
