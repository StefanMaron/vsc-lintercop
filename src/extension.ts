import { window, env, Uri, StatusBarItem, StatusBarAlignment, ExtensionContext, commands, extensions, workspace, ConfigurationTarget, OutputChannel } from 'vscode';
import * as https from 'https';
import * as fs from 'fs';
import * as path from 'path';

let outputChannel: OutputChannel;

export function activate(context: ExtensionContext) {
    console.log('Activating BusinessCentral LinterCop extension...');
    
    // Initialize the output channel
    outputChannel = window.createOutputChannel('LinterCop');
    outputChannel.show(true);
    outputChannel.appendLine('Output channel created.');

    console.log('Congratulations, your extension "businesscentral-lintercop" is now active!');
    outputChannel.appendLine('Congratulations, your extension "businesscentral-lintercop" is now active!');
    
    var statusBarItem = window.createStatusBarItem(StatusBarAlignment.Left);
    var uri = GetCurrentFileURI();
    const linterCopConfig = workspace.getConfiguration('linterCop', uri);

    let disposable = commands.registerCommand('businesscentral-lintercop.downloadCop', async () => {
        console.log('Command businesscentral-lintercop.downloadCop executed.');
        outputChannel.appendLine('Command businesscentral-lintercop.downloadCop executed.');

        var lintercop = extensions.getExtension("stefanmaron.businesscentral-lintercop");
        var AlExtension = extensions.getExtension("ms-dynamics-smb.al");

        if (lintercop && AlExtension) {
            const loadPreRelease = linterCopConfig.get('load-pre-releases') as boolean;
            var targetPath = path.join(AlExtension.extensionPath, 'bin', 'Analyzers');
            var alLanguageVersion = AlExtension.packageJSON.version;
            var downloadUrl = await getDownloadUrl(loadPreRelease, alLanguageVersion);

            try {
                const latestReleaseDate = await getLatestVersion(loadPreRelease);
                const currentVersionDate = getCurrentVersionDate(path.join(targetPath, 'BusinessCentral.LinterCop.dll'));

                console.log(`latestReleaseDate: ${latestReleaseDate}`);
                console.log(`currentVersionDate: ${currentVersionDate}`);
                outputChannel.appendLine(`latestReleaseDate: ${latestReleaseDate}`);
                outputChannel.appendLine(`currentVersionDate: ${currentVersionDate}`);

                if (latestReleaseDate && (!currentVersionDate || latestReleaseDate > currentVersionDate)) {
                    await downloadFile(downloadUrl, path.join(targetPath, 'BusinessCentral.LinterCop.dll'));
                    window.showInformationMessage(`A new version of BusinessCentral.LinterCop was downloaded successfully.`, 'OK', 'Show release notes')
                        .then(selection => {
                            if (selection == 'Show release notes')
                                env.openExternal(Uri.parse('https://github.com/StefanMaron/BusinessCentral.LinterCop/releases'));
                        });
                }
            } catch (err) {
                if (err instanceof Error) {
                    console.error(`Error: ${err.message}`);
                    window.showErrorMessage(`Error: ${err.message}`);
                    outputChannel.appendLine(`Error: ${err.message}`);
                } else {
                    console.error('Unknown error');
                    window.showErrorMessage('Unknown error');
                    outputChannel.appendLine('Unknown error');
                }
            }
        }
    });
    context.subscriptions.push(disposable);
    uri = GetCurrentFileURI();
    var currentAnalyzerSettings = workspace.getConfiguration('al', uri).inspect('codeAnalyzers');
    var activeAnalyzers = (workspace.getConfiguration('al', uri).get('codeAnalyzers') + '' as String).split(',');
    SetStatusBar(statusBarItem);

    var currentConfigTarget = ConfigurationTarget.WorkspaceFolder;

    disposable = commands.registerCommand('businesscentral-lintercop.selectAnalysers', async () => {
        console.log('Command businesscentral-lintercop.selectAnalysers executed.');
        outputChannel.appendLine('Command businesscentral-lintercop.selectAnalysers executed.');

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
            var analyzersArray = ([] as string[]).concat.apply([] as string[], analyzers.map(item => item.setting));
            await workspace.getConfiguration('al', uri).update('codeAnalyzers', analyzersArray, currentConfigTarget);
        }
        SetStatusBar(statusBarItem);
    });
    context.subscriptions.push(disposable);

    const autoDownload = linterCopConfig.get('autoDownload');

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

async function getLatestVersion(loadPreRelease: boolean): Promise<number | null> {
    return new Promise((resolve, reject) => {
        https.get('https://api.github.com/repos/StefanMaron/BusinessCentral.LinterCop/releases', {
            headers: { 'User-Agent': 'Node.js' }
        }, response => {
            let data = '';
            response.on('data', chunk => {
                data += chunk;
            });
            response.on('end', () => {
                const releases = JSON.parse(data);
                const latestRelease = releases.find((release: any) => loadPreRelease || !release.prerelease);
                if (latestRelease) {
                    resolve(new Date(latestRelease.created_at).getTime());
                } else {
                    resolve(null);
                }
            });
        }).on('error', err => {
            reject(err);
        });
    });
}

function getCurrentVersionDate(filePath: string): number | null {
    if (fs.existsSync(filePath)) {
        const stats = fs.statSync(filePath);
        return stats.mtime.getTime();
    }
    return null;
}

async function getDownloadUrl(loadPreRelease: boolean, alLanguageVersion: string): Promise<string> {
    return new Promise((resolve, reject) => {
        https.get('https://api.github.com/repos/StefanMaron/BusinessCentral.LinterCop/releases/latest', {
            headers: { 'User-Agent': 'Node.js' }
        }, response => {
            let data = '';
            response.on('data', chunk => {
                data += chunk;
            });
            response.on('end', () => {
                const release = JSON.parse(data);
                if (release.message && release.message.includes("API rate limit exceeded")) {
                    reject(new Error('GitHub API rate limit exceeded. Please try again later.'));
                    return;
                }
                const asset = release.assets.find((asset: any) => asset.name.includes('BusinessCentral.LinterCop') && asset.name.includes(alLanguageVersion));
                if (asset) {
                    resolve(asset.browser_download_url);
                } else {
                    reject(new Error('No suitable asset found in the latest release.'));
                }
            });
        }).on('error', err => {
            reject(err);
        });
    });
}

function downloadFile(url: string, dest: string): Promise<void> {
    return new Promise((resolve, reject) => {
        const tempFilePath = dest + '.tmp';
        const file = fs.createWriteStream(tempFilePath);
        const request = https.get(url, response => {
            if (response.statusCode === 302 && response.headers.location) {
                // Follow redirect
                downloadFile(response.headers.location, dest).then(resolve).catch(reject);
                return;
            }
            if (response.statusCode !== 200) {
                fs.unlink(tempFilePath, () => reject(new Error(`Failed to get '${url}' (${response.statusCode})`)));
                return;
            }
            response.pipe(file);
            file.on('finish', () => {
                file.close();
                fs.rename(tempFilePath, dest, err => {
                    if (err) {
                        fs.unlink(tempFilePath, () => reject(err));
                    } else {
                        resolve();
                    }
                });
            });
        });
        request.on('error', err => {
            fs.unlink(tempFilePath, () => reject(err));
        });
    });
}

export function deactivate() { }