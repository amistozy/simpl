# Simpl Language Support for VS Code

This extension provides language support for Simpl files (`.simpl`) in Visual Studio Code.

## What You Get

- Syntax highlighting for core Simpl syntax:
  - keywords (`let`, `rec`, `if`, `then`, `else`, `fn`, `do`, `with`, `end`, `is`, `and`, `or`)
  - literals (integers, strings, `true`, `false`, `nil`)
  - operators (arithmetic, comparison, logical, assignment, reference updates)
  - variant tags (for example `#Tag`)
- Function-call highlighting for both styles:
  - parenthesized call: `f(...)`
  - trailing application: `f x`
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

## Installation

Install from a local VSIX package:

1. Package the extension (see commands below).
2. In VS Code, open Extensions view.
3. Use `...` menu -> `Install from VSIX...`.
4. Select the generated `.vsix` file.

## Build and Package

```powershell
cd editors/vscode-simpl
npm install
npm run package
```

Alternative command:

```powershell
cd editors/vscode-simpl
npm install
npx @vscode/vsce package
```

## Development Notes

- Extension manifest: `package.json`
- Language configuration: `language-configuration.json`
- TextMate grammar: `syntaxes/simpl.tmLanguage.json`

If you update token scopes or auto-closing behavior, reload the VS Code window to verify changes.
