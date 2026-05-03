# Simpl Language Support

VS Code language support for Simpl (`.simpl`) files.

This extension is focused on the essentials:

- syntax highlighting
- language-aware bracket and quote pairing
- lightweight completion for keywords and built-in functions
- Simpl-specific editor defaults for a smoother typing experience

It is a lightweight extension today. It does not currently provide a language
server, diagnostics, formatting, or completion.

## Features

## Syntax highlighting

The extension highlights the main parts of Simpl source, including:

- keywords such as `let`, `rec`, `if`, `then`, `else`, `guard`, `fn`, `with`, `is`, `and`, and `or`
- literals such as integers, negative integer literals, strings, `true`, `false`, and `nil`
- operators including arithmetic, comparison, logical, assignment, and ref-update operators
- the probe operator `=>` for result-printing forms
- variant tags such as `#Ok` and `#Err`
- built-in functions: `ref`, `say`, `map`, `filter`, `fold`, `length`, `max`, `min`, and `sum`

It also includes grammar support for several important Simpl-specific forms:

- ordinary calls like `f(1; 2)`
- trailing application like `f x`
- grouped trailing application like `say: (1 + 2) * 3`
- guard forms like `guard xs is [x; ..rest] else []; x`
- with forms like `with(v) use(41); v + 1` and `with run; 42`
- probe forms like `=> 1 + 2; it + 3`
- UFCS-style member calls like `value.render` and `1.add3(2; 3)`
- function definition sugar in bindings, record fields, and named arguments

## Editing behavior

The extension contributes:

- bracket matching for `()`, `[]`, and `{}`
- auto-closing pairs for brackets and double quotes
- surrounding pairs for brackets and double quotes
- a Simpl word pattern for identifiers, numbers, and variant names

For Simpl files, it also sets these editor defaults:

- `editor.autoClosingQuotes = "always"`
- `editor.autoClosingOvertype = "never"`
- `editor.tabSize = 2`

These defaults are especially helpful for Simpl's string-composition style:

```simpl
name" is "$age" years old"
```

## Comments

The extension treats `--` as the line comment syntax:

```simpl
-- comment
let x = 1
```

## Installation

## Install from the local folder

If you are working directly from this repository:

1. Open VS Code.
2. Open the Command Palette.
3. Run `Developer: Install Extension from Location...`.
4. Select `editors/vscode-simpl`.

## Package the extension

The extension manifest already includes a packaging script:

```powershell
npm install
npm run package
```

This uses `vsce` to produce a `.vsix` package that you can install manually in
VS Code.

## Project files

- `package.json`: extension manifest
- `language-configuration.json`: comments, brackets, pairs, and word pattern
- `syntaxes/simpl.tmLanguage.json`: TextMate grammar

## Current scope

This extension currently provides editor support only. If you want richer IDE
features later, the natural next steps would be:

- diagnostics from the Simpl parser
- formatter integration
- hover and go-to-definition support
- broader completion for built-ins and language constructs

## Related project

The language implementation lives in the parent repository. For language syntax
and runtime behavior, see the main project README and the docs in the repo root.
