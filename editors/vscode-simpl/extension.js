"use strict";

const vscode = require("vscode");
const {
  LanguageClient,
  TransportKind,
} = require("vscode-languageclient/node");

let client = null;
let outputChannel = null;

function readServerConfig() {
  const config = vscode.workspace.getConfiguration("simpl.languageServer");
  const command = config.get("command", "").trim();
  const args = config.get("args", []);
  const cwdConfig = config.get("cwd", "").trim();
  const envConfig = config.get("env", {});

  let cwd = cwdConfig;
  if (!cwd) {
    const folder = vscode.workspace.workspaceFolders?.[0];
    if (folder) {
      cwd = folder.uri.fsPath;
    }
  }

  const env = { ...process.env, ...envConfig };

  return { command, args, cwd, env };
}

function createClient() {
  const { command, args, cwd, env } = readServerConfig();
  if (!command) {
    return null;
  }

  const executable = {
    command,
    args,
    transport: TransportKind.stdio,
    options: {
      cwd: cwd || undefined,
      env,
    },
  };

  const serverOptions = {
    run: executable,
    debug: executable,
  };

  const clientOptions = {
    documentSelector: [
      { scheme: "file", language: "simpl" },
      { scheme: "untitled", language: "simpl" },
    ],
    synchronize: {
      configurationSection: "simpl.languageServer",
      fileEvents: vscode.workspace.createFileSystemWatcher("**/*.simpl"),
    },
    outputChannel,
  };

  return new LanguageClient(
    "simplLanguageServer",
    "Simpl Language Server",
    serverOptions,
    clientOptions,
  );
}

async function startClient() {
  if (client) {
    return true;
  }
  const nextClient = createClient();
  if (!nextClient) {
    return false;
  }
  client = nextClient;
  try {
    await client.start();
    return true;
  } catch (error) {
    client = null;
    const message = error instanceof Error ? error.message : String(error);
    vscode.window.showErrorMessage(
      `Failed to start Simpl language server: ${message}`,
    );
    return false;
  }
}

async function stopClient() {
  if (!client) {
    return;
  }
  const active = client;
  client = null;
  await active.stop();
}

async function restartClient() {
  await stopClient();
  return startClient();
}

/**
 * @param {vscode.ExtensionContext} context
 */
async function activate(context) {
  outputChannel = vscode.window.createOutputChannel("Simpl Language Server");
  context.subscriptions.push(outputChannel);

  context.subscriptions.push(
    vscode.commands.registerCommand("simpl.restartLanguageServer", async () => {
      const started = await restartClient();
      if (started) {
        vscode.window.showInformationMessage("Simpl language server restarted.");
      } else {
        vscode.window.showWarningMessage(
          "Simpl language server command is not configured.",
        );
      }
    }),
  );

  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration(async (event) => {
      if (event.affectsConfiguration("simpl.languageServer")) {
        await restartClient();
      }
    }),
  );

  await startClient();
}

async function deactivate() {
  await stopClient();
}

module.exports = {
  activate,
  deactivate,
};
