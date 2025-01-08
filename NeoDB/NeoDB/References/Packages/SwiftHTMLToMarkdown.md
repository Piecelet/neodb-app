# Swift HTML -> Markdown
This package allows you to quickly convert HTML code into Markdown. Normally you want to go from Markdown -> HTML and there are a thousand packages and parsers to do that. However, what if the service you are using (like Mastodon) provides everything in HTML but you want to parse it in Markdown? Well you need to convert it. This package allows you to do just that!

## Supported Flavors of HTML
| Flavor               | Support                                             |
| -------------------- | --------------------------------------------------- |
| Mastodon Status HTML (MastodonHTML) | ✅                                                  |
| Basic HTML (BasicHTML)           | ⚠️ (Almost fully supported, tables are not) |

## How to use
Using the library is pretty simple. The first step is to pick which HTML flavor you are going to be converting. If you are converting a Basic HTML document you can use the `BasicHTML` class. For Mastodon statuses you can use the `MastodonHTML` class.

Once you have picked out the class you will be using, the following code is all you need!
```swift
var document = BasicHTML(rawHTML: raw)
try document.parse()
        
let markdown = try document.asMarkdown()
print(markdwon)
```
