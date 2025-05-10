## Find:

```regex
#### `(?<name>[^ ]+)`.*\s+##### Syntax:\s+```\w*?\s+(?<syntax>.*)\s+```\s+(##### Example:\s+```\w*?\s+(?<example>(.|\s)*?)\s+```)?\s+##### Description:\s+(?<desc>(?:.|\s)+?(?=\<br\/\>|$))
```

## List:

```regex
<div class="method">\r\n\r\n### $name\r\n<p><span class="w3-tag w3-green">ICM</span> <span class="w3-tag w3-green">INFOASSET</span> <span class="w3-tag w3-blue">EXCHANGE</span></p>\r\n\r\n```ruby\r\n$syntax\r\n```\r\n<details>\r\n<summary>Description (Click to Expand)</summary>\r\n$desc\r\n</details>\r\n<details>\r\n<summary>Examples (Click to Expand)</summary>\r\n\r\n```ruby\r\n$example\r\n```\r\n</details>\r\n</div>\r\n\r\n\r\n\r\n
```

## [Example](https://regex101.com/r/HyuLO2/1)
