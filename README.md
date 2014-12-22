# Aglio Default Theme
This is *Olio*, the default theme engine for [Aglio](https://github.com/danielgtaylor/aglio). It takes an [API Blueprint](http://apiblueprint.org/) AST and renders it into static HTML. Example use:

```bash
$ sudo npm install -g aglio
$ aglio -i blueprint.md -o MyAPI.html
```

Theme engines for Aglio are described in more detail in the [Aglio documentation]().

## Design Philosophy
Olio is designed from the ground up to be both **fast** and **extensible** while maintaining backward compatibility with the original Aglio theme. It uses the following technologies:

* Less to produce CSS
* Remarked to render Markdown
* Jade to produce HTML
* Highlight.js to highlight code snippets
