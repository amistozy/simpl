# Simpl VS Code Extension

Language support for `.simpl` files.

## Features

- Syntax highlighting for Simpl keywords, literals, operators, and variant tags.
- File association for `*.simpl`.
- Basic editor behavior: bracket matching and auto-closing pairs.

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

## Development

```powershell
cd editors/vscode-simpl
npm install
npx @vscode/vsce package
```
