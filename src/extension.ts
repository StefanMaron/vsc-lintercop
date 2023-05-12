// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import { stat } from 'fs';
import { userInfo } from 'os';
import { off, stdout } from 'process';
import { window, env, Uri, StatusBarItem, StatusBarAlignment, ExtensionContext, commands, extensions, workspace, ConfigurationTarget } from "vscode";

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: ExtensionContext) {

	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "businesscentral-lintercop" is now active!');
	var statusBarItem = window.createStatusBarItem(StatusBarAlignment.Left);
	var uri = GetCurrentFileURI();
	const linterCopConfig = workspace.getConfiguration('linterCop', uri)

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	let disposable = commands.registerCommand('businesscentral-lintercop.downloadCop', async () => {
		const { exec } = require('child_process');
		var lintercop = extensions.getExtension("stefanmaron.businesscentral-lintercop");
		var AlExtension = extensions.getExtension("ms-dynamics-smb.al");

		if (lintercop && AlExtension) {
			const os = require('os');
			let executable = ''
			
			if (os.platform() == 'win32') {
				executable = 'powershell.exe'
			}
			else {
				executable = 'pwsh'
			}

			const loadPreRelease = linterCopConfig.get('load-pre-releases')
			var DownloadScript = lintercop.extensionPath + '/DownloadFile.ps1';
			var targetPath = AlExtension.extensionPath + '/bin/Analyzers/"'
			var retvalue = exec(`. "${DownloadScript}" "${targetPath} "${loadPreRelease}"`, { 'shell': executable }, (error: string, stdout: string, stderr: string) => {
				var results = stdout.split("\n")
				if (results[1].trim() == "1") {
					window
						.showInformationMessage(`A new version of BusinessCentral.LinterCop was downloaded successfully.`, 'OK', 'Show release notes')
						.then(selection => {
							if (selection == 'Show release notes')
								env.openExternal(Uri.parse('https://github.com/StefanMaron/BusinessCentral.LinterCop/releases'));
						});

				}
			})
			window.showInformationMessage(retvalue)
		}
	});
	context.subscriptions.push(disposable);
	uri = GetCurrentFileURI();
	var currentAnalyzerSettings = workspace.getConfiguration('al', uri).inspect('codeAnalyzers');
	var activeAnalyzers = (workspace.getConfiguration('al', uri).get('codeAnalyzers') + '' as String).split(',');
	SetStatusBar(statusBarItem);

	var currentConfigTarget = ConfigurationTarget.WorkspaceFolder;

	disposable = commands.registerCommand('businesscentral-lintercop.selectAnalysers', async () => {
		var uri = GetCurrentFileURI();
		currentAnalyzerSettings = workspace.getConfiguration('al', uri).inspect('codeAnalyzers');
		activeAnalyzers = (workspace.getConfiguration('al', uri).get('codeAnalyzers') + '' as String).split(',');

		if (currentAnalyzerSettings?.globalValue)
			currentConfigTarget = ConfigurationTarget.Global;
		if (currentAnalyzerSettings?.workspaceValue)
			currentConfigTarget = ConfigurationTarget.Workspace;
		if (currentAnalyzerSettings?.workspaceFolderValue)
			currentConfigTarget = ConfigurationTarget.WorkspaceFolder;

		var analyzers = await window.showQuickPick(
			[
				{ label: 'CodeCop', setting: '${CodeCop}', picked: activeAnalyzers.includes('${CodeCop}') },
				{ label: 'UICop', setting: '${UICop}', picked: activeAnalyzers.includes('${UICop}') },
				{ label: 'PerTenantExtensionCop', setting: '${PerTenantExtensionCop}', picked: activeAnalyzers.includes('${PerTenantExtensionCop}') },
				{ label: 'AppSourceCop', setting: '${AppSourceCop}', picked: activeAnalyzers.includes('${AppSourceCop}') },
				{ label: 'BusinessCentral.LinterCop', setting: '${analyzerFolder}BusinessCentral.LinterCop.dll', picked: activeAnalyzers.includes('${analyzerFolder}BusinessCentral.LinterCop.dll') }
			],
			{ placeHolder: 'Select the view to show when opening a window.', canPickMany: true });

		if (analyzers) {
			var analyzersArray = ([] as string[]).concat.apply([] as string[], analyzers.map(item => item.setting))
			await workspace.getConfiguration('al', uri).update('codeAnalyzers', analyzersArray, currentConfigTarget);
		}
		SetStatusBar(statusBarItem);
	});
	context.subscriptions.push(disposable);

	const autoDownload = linterCopConfig.get('autoDownload')

	window.onDidChangeActiveTextEditor(e => SetStatusBar(statusBarItem));

	if (autoDownload) {
		commands.executeCommand('businesscentral-lintercop.downloadCop');
	}
}

function GetCurrentFileURI() {
	var uri = null;
	if (window.activeTextEditor)
		uri = window.activeTextEditor.document.uri;
	return uri;
}

function SetStatusBar(statusBarItem: StatusBarItem) {
	var activeAnalyzersShort = '';
	var uri = null;
	if (window.activeTextEditor)
		uri = window.activeTextEditor.document.uri;
	var activeAnalyzers = (workspace.getConfiguration('al', uri).get('codeAnalyzers') + '' as String).split(',');
	if (activeAnalyzers.includes('${CodeCop}')) {
		activeAnalyzersShort += 'Code/';
	}
	if (activeAnalyzers.includes('${UICop}')) {
		activeAnalyzersShort += 'UI/';
	}
	if (activeAnalyzers.includes('${PerTenantExtensionCop}')) {
		activeAnalyzersShort += 'PTE/';
	}
	if (activeAnalyzers.includes('${AppSourceCop}')) {
		activeAnalyzersShort += 'AppSrc/';
	}
	if (activeAnalyzers.includes('${analyzerFolder}BusinessCentral.LinterCop.dll')) {
		activeAnalyzersShort += 'BcLntr/';
	}
	activeAnalyzersShort = activeAnalyzersShort.substr(0, activeAnalyzersShort.length - 1);
	statusBarItem.command = 'businesscentral-lintercop.selectAnalysers';
	statusBarItem.text = 'AL Cops: ' + activeAnalyzersShort;
	statusBarItem.show();
}

// this method is called when your extension is deactivated
export function deactivate() { }
