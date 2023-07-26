(module vscode-poke
  (:import
    piglet:vscode))

(vscode:vscode.window.showInformationMessage
  "hello from Piglet!")
