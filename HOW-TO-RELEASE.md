# Free Ruler Release Process

Mostly notes for myself.

- Merge any PRs to be included in the release.
- Read the current version: `npm get:version`
- Create a new branch from main named vX.X.X
- Get the number of commits: `npm get:commits`
- Bump the version number in package.json, using `npm version patch` (or minor, or major)

- In XCode, bump the version and build number, using the number of commits as the build number. Example https://github.com/pascalpp/FreeRuler/commit/ed9f8db186b00125a78629a5e5569dfda9dd6285
- In Xcode, choose Product > Archive
- In the Archives window, click Validate App. May require visiting https://developer.apple.com to accept updated licensing agreements, etc.

## Github Release

- In the XCode Archives window, click Distribute App > Direct Distribution > Distribute.
- Wait for notification from Apple notary service, usually less than a minute.
- Export the build to `dist/Free Ruler.app`. Compress Free Ruler.app as free-ruler-X.X.X.zip. `npm run build:zip`
- Delete the app and any extra folders created by the build process. (Should be handled by above command.)
- Commit the modified XCode project and the new zip file with the commit message 'Build vX.X.X' `npm run build:commit`
- Create a PR for the branch back to main. `npm run build:pr`
- Review and merge the PR.
- Switch to main and pull latest.
- Create a tag for the release. `git build:tag`
- Create a draft release: `git build:release`
- Update the release notes. Describe changes with #XX references to closed tickets.
- Publish the release.

## App Store Release

- In the XCode Archives window, click Distribute App > App Store Connect > Upload.
- Visit https://appstoreconnect.apple.com and submit the new build for review.
- Create a new version (green plus button).
- Add the new build.
- Update release information with new features, etc.
- Save
- Submit for Review
