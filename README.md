# multiple-bibliographies

This filter allows to create multiple bibliographies using
`citeproc`. The content of each bibliography is controlled via
YAML values and the file in which a bibliographic entry is
specified.

## Usage

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
