# Simpl Language Support for VS Code

This extension provides language support for Simpl files (`.simpl`) in Visual Studio Code.

## What You Get

- Syntax highlighting for core Simpl syntax:
  - keywords (`let`, `rec`, `if`, `then`, `else`, `fn`, `do`, `with`, `end`, `is`, `and`, `or`)
  - literals (integers, negative integer literals, strings, `true`, `false`, `nil`)
  - operators (arithmetic, comparison, logical, assignment, reference updates)
  - variant tags (for example `#Tag`)
- Function-call highlighting for both styles:
  - parenthesized call: `f(...)`
  - trailing application: `f x`
  - grouped trailing call: `say: (1 + 2) * 3`
  - prefix-operator and negative-literal arguments: `f !x`, `f -1`, `f ~x`, `f $value`
  - UFCS and method-style calls: `value.render`, `1.add3(2; 3)`
- Function-definition highlighting for sugar in multiple positions:
  - top-level/local bindings: `let inc(x) = x + 1`, `let inc x = x + 1`
  - record fields: `{ inc(x) = x + 1 }`
  - named lambda arguments: `apply(f(x) = x + 1)`
- Built-in function highlighting for `ref`, `say`, `map`, `length`, `max`, `min`, and `sum`
- Built-in language configuration:
  - bracket matching
  - auto-closing pairs
  - quote pairing behavior tuned for Simpl string interpolation workflows

## Quote Auto-Closing Behavior

The extension sets Simpl-specific defaults to make interpolation-style string editing smoother:

- `editor.autoClosingQuotes = "always"`
- `editor.autoClosingOvertype = "never"`

In practice:

- Typing `"` after an identifier (for example `name"`) inserts a quote pair.
- Typing `"` right before an existing `"` inserts quotes instead of moving the cursor over that quote.
- Typing `"` inside strings also auto-closes.

This is especially useful for chained string interpolation patterns such as:

```simpl
name" is "$age" years old"
```

## Installation (From Location)

Install the extension directly from the extension folder (no packaging required):

1. In VS Code, open the Command Palette.
2. Run `Developer: Install Extension from Location...`.
3. Select the `editors/vscode-simpl` directory.

## Development Notes

- Extension manifest: `package.json`
- Language configuration: `language-configuration.json`
- TextMate grammar: `syntaxes/simpl.tmLanguage.json`

If you update token scopes or auto-closing behavior, reload the VS Code window to verify changes.
