# BusinessCentral.LinterCop

This extensions provides auto updates for the BusinessCentral.LinterCop. This cop is basically just an dll file and needs to be placed into the folder of the AL vs code extension. If you want to do this manually, you dont need this extension ;)

By default the extension checks if the dll is still there (and did not get deleted due to updates of the AL Extension) and if a new version is released.
If one case is true, the latest version of the dll will be downloaded.

In order to activate the LinterCop you need to add this line `"${analyzerfolder}BusinessCentral.LinterCop.dll"` to the `"al.codeAnalyzers"`. For example like this:

```
"al.codeAnalyzers": [
    "${CodeCop}",
    "${UICop}",
    "${analyzerfolder}BusinessCentral.LinterCop.dll"
],
```

## Extension Settings

* `linterCop.autoDownload`: enable/disable automatic download and updates of the linter dll. If you disable it, you can still always trigger the download manually with the command `LC: Download Linter Cop`. 