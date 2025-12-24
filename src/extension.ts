import { window, env, Uri, StatusBarItem, StatusBarAlignment, ExtensionContext, commands, extensions, workspace, ConfigurationTarget, OutputChannel } from 'vscode';
import * as https from 'https';
import * as fs from 'fs';
import * as path from 'path';

let outputChannel: OutputChannel;

export function activate(context: ExtensionContext) {
    console.log('Activating BusinessCentral LinterCop extension...');

    // Initialize the output channel
    outputChannel = window.createOutputChannel('LinterCop');
    outputChannel.appendLine('LinterCop output channel created.');

    console.log('BusinessCentral LinterCop extension is now active!');
    outputChannel.appendLine('BusinessCentral LinterCop extension is now active!');

    var statusBarItem = window.createStatusBarItem(StatusBarAlignment.Left);
    var uri = GetCurrentFileURI();
    const linterCopConfig = workspace.getConfiguration('linterCop', uri);

    let disposable = commands.registerCommand('businesscentral-lintercop.downloadCop', async () => {
        outputChannel.appendLine('Executing command: businesscentral-lintercop.downloadCop');

        var lintercop = extensions.getExtension("stefanmaron.businesscentral-lintercop");
        var AlExtension = extensions.getExtension("ms-dynamics-smb.al");

        if (lintercop && AlExtension) {
            const loadPreRelease = linterCopConfig.get('load-pre-releases') as boolean;
            var targetPath = path.join(AlExtension.extensionPath, 'bin', 'Analyzers');
            var alLanguageVersion = AlExtension.packageJSON.version;
            const repositories = linterCopConfig.get('repositories') as { url: string, token: string, fileName: string, shortName: string }[];

            for (const repo of repositories) {
                try {
                    const apiUrl = convertToApiUrl(repo.url);

                    const latestReleaseDate = await getLatestVersion(apiUrl, loadPreRelease, repo.token, alLanguageVersion, repo.fileName);
                    const currentVersionDate = getCurrentVersionDate(path.join(targetPath, repo.fileName));

                    if (latestReleaseDate && (!currentVersionDate || latestReleaseDate > currentVersionDate)) {
                        var downloadUrl = await getDownloadUrl(apiUrl, loadPreRelease, alLanguageVersion, repo.token, repo.fileName);
                        await downloadFile(downloadUrl, path.join(targetPath, repo.fileName), repo.token);
                        window.showInformationMessage(`A new version of ${repo.shortName} was downloaded successfully from ${repo.url}.`, 'OK', 'Show release notes')
                            .then(selection => {
                                if (selection == 'Show release notes')
                                    env.openExternal(Uri.parse(`${repo.url}/releases`));
                            });
                        outputChannel.appendLine(`Downloaded new version of ${repo.shortName} from ${repo.url}.`);
                    } else {
                        outputChannel.appendLine(`No new version available for ${repo.shortName} from ${repo.url}.`);
                    }
                } catch (err) {
                    if (err instanceof Error) {
                        window.showErrorMessage(`Failed to download ${repo.shortName}: ${err.message}`);
                        outputChannel.appendLine(`Error downloading ${repo.shortName} from ${repo.url}: ${err.message}`);
                    } else {
                        window.showErrorMessage(`Unknown error occurred while downloading ${repo.shortName}.`);
                        outputChannel.appendLine(`Unknown error occurred while downloading ${repo.shortName} from ${repo.url}.`);
                    }
                }
            }
        } else {
            outputChannel.appendLine('Required extensions are not available.');
        }
    });
    context.subscriptions.push(disposable);

    disposable = commands.registerCommand('businesscentral-lintercop.selectAnalysers', async () => {
        outputChannel.appendLine('Executing command: businesscentral-lintercop.selectAnalysers');

        var uri = GetCurrentFileURI();
        var currentAnalyzerSettings = workspace.getConfiguration('al', uri).inspect('codeAnalyzers');
        var activeAnalyzers = (workspace.getConfiguration('al', uri).get('codeAnalyzers') + '' as String).split(',');

        var currentConfigTarget = ConfigurationTarget.WorkspaceFolder;
        if (currentAnalyzerSettings?.globalValue)
            currentConfigTarget = ConfigurationTarget.Global;
        if (currentAnalyzerSettings?.workspaceValue)
            currentConfigTarget = ConfigurationTarget.Workspace;
        if (currentAnalyzerSettings?.workspaceFolderValue)
            currentConfigTarget = ConfigurationTarget.WorkspaceFolder;

        const linterCopConfig = workspace.getConfiguration('linterCop', uri);
        const repositories = linterCopConfig.get('repositories') as { url: string, token: string, fileName: string, shortName: string }[];

        const analyzerOptions = [
            { label: 'CodeCop', setting: '${CodeCop}', picked: activeAnalyzers.includes('${CodeCop}') },
            { label: 'UICop', setting: '${UICop}', picked: activeAnalyzers.includes('${UICop}') },
            { label: 'PerTenantExtensionCop', setting: '${PerTenantExtensionCop}', picked: activeAnalyzers.includes('${PerTenantExtensionCop}') },
            { label: 'AppSourceCop', setting: '${AppSourceCop}', picked: activeAnalyzers.includes('${AppSourceCop}') },
            ...repositories.map(repo => ({
                label: repo.shortName,
                setting: `\${analyzerFolder}${repo.fileName}`,
                picked: activeAnalyzers.includes(`\${analyzerFolder}${repo.fileName}`)
            }))
        ];

        var analyzers = await window.showQuickPick(analyzerOptions, {
            placeHolder: 'Select the analyzers to use.',
            canPickMany: true
        });

        if (analyzers) {
            var analyzersArray = ([] as string[]).concat.apply([] as string[], analyzers.map(item => item.setting));
            await workspace.getConfiguration('al', uri).update('codeAnalyzers', analyzersArray, currentConfigTarget);
            outputChannel.appendLine('Updated analyzers configuration.');
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
    const linterCopConfig = workspace.getConfiguration('linterCop', uri);
    const repositories = linterCopConfig.get('repositories') as { url: string, token: string, fileName: string, shortName: string }[];

    // Default analyzers
    const defaultAnalyzers = [
        { label: 'CodeCop', setting: '${CodeCop}', shortName: 'Code' },
        { label: 'UICop', setting: '${UICop}', shortName: 'UI' },
        { label: 'PerTenantExtensionCop', setting: '${PerTenantExtensionCop}', shortName: 'PTE' },
        { label: 'AppSourceCop', setting: '${AppSourceCop}', shortName: 'AppSrc' }
    ];

    // Check default analyzers
    for (const analyzer of defaultAnalyzers) {
        if (activeAnalyzers.includes(analyzer.setting)) {
            activeAnalyzersShort += `${analyzer.shortName}/`;
        }
    }

    // Check custom analyzers from repositories
    for (const repo of repositories) {
        if (activeAnalyzers.includes(`\${analyzerFolder}${repo.fileName}`)) {
            activeAnalyzersShort += `${repo.shortName}/`;
        }
    }

    activeAnalyzersShort = activeAnalyzersShort.substr(0, activeAnalyzersShort.length - 1);
    statusBarItem.command = 'businesscentral-lintercop.selectAnalysers';
    statusBarItem.text = 'AL Cops: ' + activeAnalyzersShort;
    statusBarItem.show();
}

function convertToApiUrl(repoUrl: string): string {
    const match = repoUrl.match(/github\.com\/([^\/]+)\/([^\/]+)/);
    if (match) {
        const owner = match[1];
        const repo = match[2];
        return `https://api.github.com/repos/${owner}/${repo}`;
    }
    throw new Error('Invalid GitHub repository URL');
}

async function getLatestVersion(apiUrl: string, loadPreRelease: boolean, token: string, alLanguageVersion: string, fileName: string): Promise<number | null> {
    return new Promise((resolve, reject) => {
        const options: https.RequestOptions = {
            headers: { 'User-Agent': 'Node.js' }
        };
        if (token) {
            (options.headers as any)['Authorization'] = `token ${token}`;
        }
        https.get(`${apiUrl}/releases`, options, response => {
            let data = '';
            response.on('data', chunk => {
                data += chunk;
            });
            response.on('end', () => {
                const releases = JSON.parse(data);
                const latestRelease = releases.find((release: any) => loadPreRelease || !release.prerelease);

                if (latestRelease) {
                    let asset = latestRelease.assets.find((asset: any) => asset.name.includes(alLanguageVersion));
                    if (!asset) {
                        asset = latestRelease.assets.find((asset: any) => asset.name.includes(fileName));
                    }
                    resolve(new Date(asset.created_at).getTime());
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

async function getDownloadUrl(apiUrl: string, loadPreRelease: boolean, alLanguageVersion: string, token: string, fileName: string): Promise<string> {
    return new Promise((resolve, reject) => {
        const options: https.RequestOptions = {
            headers: { 'User-Agent': 'Node.js' }
        };
        if (token) {
            (options.headers as any)['Authorization'] = `token ${token}`;
        }
        https.get(`${apiUrl}/releases`, options, response => {
            let data = '';
            response.on('data', chunk => {
                data += chunk;
            });
            response.on('end', () => {
                const releases = JSON.parse(data);
                const latestRelease = releases.find((release: any) => loadPreRelease || !release.prerelease);
                if (latestRelease.message && latestRelease.message.includes("API rate limit exceeded")) {
                    reject(new Error('GitHub API rate limit exceeded. Please try again later.'));
                    return;
                }

                // Try to find an asset that matches the AL version
                let asset = latestRelease.assets.find((asset: any) => asset.name.includes(alLanguageVersion));

                // If no matching AL version asset is found, try to find an asset that matches the file name
                if (!asset) {
                    asset = latestRelease.assets.find((asset: any) => asset.name.includes(fileName));
                }

                if (asset) {
                    if (token) {
                        resolve(asset.url);
                    } else {
                        resolve(asset.browser_download_url);
                    }
                } else {
                    reject(new Error('No suitable asset found in the latest release.'));
                }
            });
        }).on('error', err => {
            reject(err);
        });
    });
}

function downloadFile(url: string, dest: string, token: string): Promise<void> {
    return new Promise((resolve, reject) => {
        const tempFilePath = dest + '.tmp';
        const file = fs.createWriteStream(tempFilePath);
        const options: https.RequestOptions = {
            headers: { 'User-Agent': 'Node.js' }
        };
        if (token) {
            (options.headers as any)['Authorization'] = `token ${token}`;
            (options.headers as any)['Accept'] = 'application/octet-stream';
        }
        const request = https.get(url, options, response => {
            if (response.statusCode === 302 && response.headers.location) {
                // Follow redirect
                downloadFile(response.headers.location, dest, token).then(resolve).catch(reject);
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