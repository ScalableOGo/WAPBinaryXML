## WAPBinaryXML

WAPBinaryXML is a Swift encoder/decoder for WBXML 1.3. Intended for ActiveSync,
but usable with other WBXML dialects too. The package has no dependencies and
does not ship protocol code pages.

Swift 6.2 or later. Should work on all platforms, iOS 13 and peers and up.


### Quick start

Declare the tag mappings used by the peer. This is a small subset of the
ActiveSync AirSync page, not a complete ActiveSync schema:

```swift
import WAPBinaryXML

let airSync = WBXMLCodePage(page: 0, namespace: "AirSync:", tokens: [
  ( 0x05, "Sync"         ),
  ( 0x0B, "SyncKey"      ),
  ( 0x0E, "Status"       ),
  ( 0x0F, "Collection"   ),
  ( 0x12, "CollectionId" ),
  ( 0x1C, "Collections"  )
])
let codePages = WBXMLCodePage.Set([ airSync ])
try codePages.validate()
```

Build and encode a document using the page number from `airSync`. In the
builder, children without an explicit page inherit their enclosing page:

```swift
let root = WBXMLBuilder.element("Sync", page: airSync.page) {
  $0.element("Collections") {
    $0.element("Collection") {
      $0.element("SyncKey", text: "0")
      $0.element("CollectionId", text: "inbox")
    }
  }
}

let encoder = WBXMLEncoder(codePages: codePages)
var bytes = [ UInt8 ]()
try encoder.encode(root, to: &bytes)
```

Decode from the encoded byte collection:

```swift
let decoder  = WBXMLDecoder(codePages: codePages)
let document = try decoder.decode(bytes)

let collection = document.root[tag: "Collections"]?[tag: "Collection"]
let syncKey    = collection?[tag: "SyncKey"]?.textValue
```

Both codecs can be reused for multiple documents. To select a charset or public
identifier, wrap the root in `WBXMLDocument` and pass that to the encoder.


### Supported WBXML constructs

| Construct                              | Decode | Encode |
| -------------------------------------- | ------ | ------ |
| WBXML 1.3 header version               | Yes    | Yes    |
| Tag code pages and page switches       | Yes    | Yes    |
| Attribute code pages and attributes    | Yes    | Yes    |
| Inline and string-table text           | Yes    | Yes    |
| Numeric and literal public identifiers | Yes    | Yes    |
| Literal tag and attribute names        | Yes    | Yes    |
| Entities and opaque data               | Yes    | Yes    |
| Processing instructions                | Yes    | Yes    |
| WBXML extension tokens                 | Yes    | Yes    |


### Character sets

Latin 1 or UTF-8 only.

| MIBenum | Interpretation                      |
| ------- | ----------------------------------- |
| `0`     | Unspecified value, treated as UTF-8 |
| `4`     | ISO-8859-1                          |
| `106`   | UTF-8                               |



## Who

**This** is brought to you by
[Helge Heß](https://github.com/helje5/) / [ZeeZide](https://zeezide.de).
We like feedback, GitHub stars, cool contract work, and any form of praise you 
can think of.
Buy one of our [apps](https://zeezide.de/en/products/products.html),
you don't have to use them! 😀
