# Simpl VS Code Extension

Language support for `.simpl` files.

## Features

- Syntax highlighting for Simpl keywords, literals, operators, and variant tags.
- File association for `*.simpl`.
- Basic editor behavior: bracket matching and auto-closing pairs.
- Configurable LSP client (starts your Simpl language server over stdio).

## Included Grammar Coverage

- Keywords: `let`, `rec`, `if`, `then`, `else`, `fn`, `do`, `end`, `is`, `and`, `or`, `not`
- Literals: integers, strings, `true`, `false`, `nil`
- Operators: arithmetic, comparison, logical, assignment, reference updates
- Variant tags: `#Tag`

## Run Locally

```powershell
cd editors/vscode-simpl
npm install
npm run package
```

Then open VS Code and install the generated `.vsix` file.

## LSP Client Setup

This extension provides an LSP client. Configure your server command in VS Code settings:

```json
{
  "simpl.languageServer.command": "moon",
  "simpl.languageServer.args": ["run", "cmd/main", "--", "--lsp"]
}
```

If your server executable is different, set `simpl.languageServer.command` and `simpl.languageServer.args` accordingly.

Useful command:

- `Simpl: Restart Language Server`

## Development

```powershell
cd editors/vscode-simpl
npm install
npx @vscode/vsce package
```
