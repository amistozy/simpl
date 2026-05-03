import * as vscode from "vscode";

const KEYWORDS = [
  ["if", "Conditional split"],
  ["then", "Then branch"],
  ["else", "Fallback branch"],
  ["do", "Sequence effect then body"],
  ["guard", "Guard expression"],
  ["with", "Pass trailing lambda"],
  ["end", "Implicit else nil"],
  ["is", "Pattern refinement"],
  ["as", "As-pattern binder"],
  ["and", "Nested refinement"],
  ["or", "Close nested split"],
  ["let", "Value binding"],
  ["rec", "Recursive binding"],
  ["fn", "Function or eta-expansion"],
];

const BUILTINS = [
  ["ref", "Create a mutable reference"],
  ["say", "Print a value"],
  ["map", "Map over a list"],
  ["filter", "Filter a list"],
  ["fold", "Reduce a list from the left"],
  ["length", "Length of a string or list"],
  ["reverse", "Reverse a string or list"],
  ["max", "Maximum of two ints or a list"],
  ["min", "Minimum of two ints or a list"],
  ["sum", "Sum a list of ints"],
];

export function activate(context) {
  const provider = vscode.languages.registerCompletionItemProvider(
    { language: "simpl" },
    {
      provideCompletionItems(document, position) {
        const range = document.getWordRangeAtPosition(
          position,
          /[A-Za-z_][A-Za-z0-9_]*/,
        );
        if (!range) {
          return undefined;
        }

        const text = document.getText(range);
        const query = text.toLowerCase();
        if (!query) {
          return undefined;
        }

        const keywordItems = KEYWORDS.filter(
          ([keyword]) => keyword.startsWith(query) && keyword !== query,
        ).map(([keyword, detail]) => {
          const item = new vscode.CompletionItem(
            keyword,
            vscode.CompletionItemKind.Keyword,
          );
          item.insertText = keyword;
          item.detail = detail;
          item.range = range;
          return item;
        });

        const builtinItems = BUILTINS.filter(
          ([name]) => name.startsWith(query) && name !== query,
        ).map(([name, detail]) => {
          const item = new vscode.CompletionItem(
            name,
            vscode.CompletionItemKind.Function,
          );
          item.insertText = name;
          item.detail = detail;
          item.range = range;
          return item;
        });

        const items = [...keywordItems, ...builtinItems];
        return items.length > 0 ? items : undefined;
      },
    },
  );

  context.subscriptions.push(provider);
}

export function deactivate() { }
