# Free Ruler Release Process

Mostly notes for myself.

- Merge any PRs to be included in the release.
- Create a new branch from main named vX.X.X
- Get the number of commits:

```
git log --pretty=oneline | wc -l
```

- In XCode, bump the version and build number, using the number of commits as the build number. Example https://github.com/pascalpp/FreeRuler/commit/ed9f8db186b00125a78629a5e5569dfda9dd6285
- In Xcode, choose Product > Archive
- In the Archives window, click Validate App. May require visiting https://developer.apple.com to accept updated licensing agreements, etc.

## Github Release

- In the XCode Archives window, click Distribute App > Copy App.
- Export the build to the `dist` folder in the repo. Compress just Free Ruler.app as free-ruler-X.X.X.zip. Delete the app and any extra folders created by the build process.
- Commit the modified XCode project and the new zip file with the commit message 'Build vX.X.X'
- Create a PR for the branch back to master.
- Review and merge the PR.
- Draft a new Github release https://github.com/pascalpp/FreeRuler/releases/new. Use v.X.X.X as the title and tag for the release. Describe changes with #XX references to closed tickets. Attach the new zip file to the release.
- Publish.

## App Store Release

- In the XCode Archives window, click Distribute App > App Store Connect > Upload.
- Visit https://appstoreconnect.apple.com and submit the new build for review.
- Create a new version (green plus button).
- Add the new build.
- Update release information with new features, etc.
- Save
- Submit for Review
