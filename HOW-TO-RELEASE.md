# Free Ruler Release Process

Free Ruler has two release tracks:

- GitHub release: a signed, notarized zip for direct download from GitHub.
- App Store release: an uploaded build submitted through App Store Connect.

This document currently automates the GitHub release path with npm scripts. The
App Store path is still manual and should be automated separately.

## Versioning

Free Ruler keeps the marketing version in both `package.json` and the Xcode
project `MARKETING_VERSION`. Keep those values in sync before releasing.

Useful commands:

```sh
npm run get:version
npm run get:commits
npm run bump:version
```

After bumping `package.json`, update Xcode's `MARKETING_VERSION` to match. Use
the commit count or another intentional value for `CURRENT_PROJECT_VERSION`.

## GitHub Release

The GitHub release scripts build and export a Developer ID app, notarize and
staple it, zip it, then create or update a draft GitHub Release.

### Prerequisites

Required command line tools:

```sh
git
gh
node
npm
xcodebuild
xcrun
ditto
```

Required signing/notarization setup:

- A Developer ID Application certificate available to Xcode.
- Xcode signing configured for the Free Ruler app target.
- GitHub CLI authenticated with permission to create releases.
- Notary credentials configured with either:
  - `NOTARYTOOL_PROFILE`, created with `xcrun notarytool store-credentials`
  - or `NOTARYTOOL_APPLE_ID`, `NOTARYTOOL_PASSWORD`, and `NOTARYTOOL_TEAM_ID`

If Xcode needs to update signing assets during archive/export, run with:

```sh
ALLOW_PROVISIONING_UPDATES=1 npm run release:github
```

### One-command flow

Run this from a clean checkout on the commit you want to release:

```sh
npm run release:github
```

This runs:

```sh
npm run release:github:check
npm run release:github:archive
npm run release:github:export
npm run release:github:notarize
npm run release:github:zip
npm run release:github:publish
```

The final zip is written to ignored release output:

```sh
build/release/free-ruler-X.Y.Z.zip
```

The release is created as a draft so release notes can be reviewed before
publishing.

### Rehearsal without publishing

To exercise the local build/export/zip flow without creating tags or GitHub
releases, run:

```sh
RELEASE_DRY_RUN=1 npm run release:github
```

Dry-run mode allows an existing version tag, skips the clean-worktree check, and
prints what the GitHub publish step would do.

To rehearse without contacting Apple's notary service:

```sh
npm run github:release:dryrun
```

The resulting zip is useful for checking packaging mechanics, but it is not a
notarized release artifact.

To test publishing a real draft release without using the production version
tag, override the tag:

```sh
RELEASE_TAG=vX.Y.Z-test.1 npm run release:github
```

After testing, delete the draft release and test tag:

```sh
gh release delete vX.Y.Z-test.1 --yes
git tag -d vX.Y.Z-test.1
git push origin :refs/tags/vX.Y.Z-test.1
```

### Step-by-step flow

Use the step scripts when debugging signing, export, notarization, or GitHub
release creation:

```sh
npm run release:github:check
npm run release:github:archive
npm run release:github:export
npm run release:github:notarize
npm run release:github:zip
npm run release:github:publish
```

Build products and the release zip are written under `build/release/`, which is
ignored by git. Historical release zips in `dist/` are left alone; future policy
for those checked-in artifacts is tracked separately.

If a zip for the current version already exists, the zip step fails. To replace
it intentionally:

```sh
RELEASE_OVERWRITE=1 npm run release:github:zip
```

## App Store Release

The App Store path is still manual for now:

1. Archive the app in Xcode.
2. Choose Distribute App > App Store Connect > Upload.
3. Visit App Store Connect.
4. Create a new version if needed.
5. Select the uploaded build.
6. Update release notes and metadata.
7. Submit for review.

Future automation should add a separate App Store export/upload path instead of
overloading the GitHub release scripts. That follow-up should cover App Store
Connect API credentials, export options, upload validation, and review-submission
steps.
