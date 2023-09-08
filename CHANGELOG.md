# Change Log

All notable changes to the "businesscentral-lintercop" extension will be documented in this file.

## [0.1.6]

- fixed bug that prevented prerelease from donwloading correctly


## [0.1.5]

- Json Syntax for LinterCop.json #7 thanks @jwikman
- Always support TLS1.2 #8 thanks @jwikman 
- Changed download script to load both, current and next major .dll


## [0.1.4]

- digital signed for the PS downloadscript. To Use the extension it is now enough to have `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`

## [0.1.3]

- bugfix in download script leading to always download the prerelease if it is the latest

## [0.1.2]

- added link to the linter cop change log in message window thats shows up when a new version got loaded

## [0.1.1]

- bugfix in the download script preventing download of a release when prerelease is activated

## [0.1.0]

- added license
- added  changelog
- the repository link now points to the correct repository
- added a first draft of a logo

## [0.0.8]

- indroduced a new setting `linterCop.load-pre-releases` to allow the externsion to download pre-releases of the linter

## [0.0.7]

- added information about the active code cops in the status bar
- its now possible to change the cops by clicking on the code cop status bar indicator

## [0.0.1]

- Initial release
