# HTML2Markdown

## What is this?

It's a Swift Package which attempts to convert HTML into Markdown.

## How do I use it?

```swift
let html = "<p>This is a <em>terrible</em> idea.<br/>I must be daft.</p>"

do {
    let dom = try HTMLParser().parse(html: html)
    let markdown = dom.markdownFormatted(options: .unorderedListBullets)
    print(markdown)
} catch {
    // parsing error
}
```

This generates the following markdown string:

```
This is a *terrible* idea.\nI must be daft.
```

## What is supported?

* `<strong>` and `<em>` for highlighting text
* ordered and unordered lists (`<ol>` and `<ul>`)
* paragraphs (`<p>`) and line breaks (`<br>`)
* hyperlinks (`<a href="...">`)

All other HTML tags are removed.

> Note:
> `SwiftUI.Text` currently cannot render Markdown lists therefore use the `MarkdownGenerator.Options.unorderedListBullets` option to generate nicer-looking bullets: `•` instead of `*`.

## License

See [LICENSE](LICSNE)
