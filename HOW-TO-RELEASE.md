# Free Ruler Release Process

Free Ruler has two release tracks:

- GitHub release: a signed, notarized zip for direct download from GitHub.
- App Store release: an uploaded build submitted through App Store Connect.

This document covers the GitHub release path. The App Store path is still manual
for now.

## GitHub Release

Assuming you have the prerequisites listed below, follow these steps from a terminal in the Free Ruler repository.

1. Start from the latest `main`.

   ```sh
   git switch main
   git pull --ff-only origin main
   ```

2. Bump, commit, and push the version.

   ```sh
   npm run bump:version
   ```

   Press `M`, `m`, or `p` when prompted. This updates `package.json` and the
   Xcode `MARKETING_VERSION`, which is the version shown in the app's About
   dialog. It also updates the Xcode build number from the current git commit
   count. Confirm the second prompt to commit the changed files and push `main`.

3. Build, notarize, zip, and create a draft GitHub Release.

   ```sh
   npm run release:github
   ```

4. Publish the draft release.

   Open the [GitHub Releases
   page](https://github.com/pascalpp/FreeRuler/releases), review the draft,
   download and test the zip, then click **Publish release**.

GitHub Releases are the canonical home for downloadable release zips. Do not
commit release zips to the repository.

## Testing the Release Process

Use this when you want to test the release machinery without making a real
public release.

1. Test local archive/export/zip mechanics.

   ```sh
   npm run github:release:dryrun
   ```

   This is the fastest check. It does not contact Apple's notary service and it
   does not create a GitHub release. It replaces any existing dry-run zip for
   the current version.

2. Test the full path with a temporary draft release.

   ```sh
   RELEASE_TAG=vX.Y.Z-test.1 npm run release:github
   ```

   Replace `X.Y.Z` with the version currently in `package.json`. This creates a
   temporary tag and a draft GitHub Release. Draft releases are not public until
   they are published.

3. Download the zip from the draft release, open the app, and confirm it runs.

4. Delete the test release and tag before testing again.

   ```sh
   gh release delete vX.Y.Z-test.1 --yes
   git tag -d vX.Y.Z-test.1
   git push origin :refs/tags/vX.Y.Z-test.1
   ```

## Details

<details>

<summary>Prerequisites</summary>

The GitHub release command expects:

- A clean git working tree.
- `gh` authenticated with permission to create releases.
- Xcode signing working for the Free Ruler app target.
- A Developer ID Application certificate installed. If Keychain has more than
  one, use `DEVELOPER_ID_APPLICATION_IDENTITY` in `.env`.
- Notary credentials saved in Keychain.
- Local release environment configured. See **Release environment** below.
- Sparkle signing configured. See **Sparkle updates** below.

The documented commands assume the notary profile is named `FreeRulerNotary`.
Create that profile once with:

```sh
xcrun notarytool store-credentials "FreeRulerNotary"
```

Create a local `.env` file with release settings:

```sh
cat > .env <<'EOF'
NOTARYTOOL_PROFILE=FreeRulerNotary
DEVELOPER_ID_APPLICATION_IDENTITY=<Developer ID Application SHA-1>
SPARKLE_PUBLIC_ED_KEY=...
EOF
```

If Xcode needs to create or update signing assets during archive/export, set
`ALLOW_PROVISIONING_UPDATES=1`:

```sh
ALLOW_PROVISIONING_UPDATES=1 npm run release:github
```

</details>

<details>
<summary>Release environment</summary>

Release scripts read local settings from `.env` at the repository root. That
file is ignored by git. Values already set in the shell override `.env` values.

Example:

```sh
NOTARYTOOL_PROFILE=FreeRulerNotary
DEVELOPER_ID_APPLICATION_IDENTITY=<Developer ID Application SHA-1>
SPARKLE_PUBLIC_ED_KEY=...
```

To use a different file, set `RELEASE_ENV_FILE`:

```sh
RELEASE_ENV_FILE=~/FreeRuler.release.env npm run release:github
```

</details>

<details>
<summary>What the release command does</summary>

`npm run release:github` runs:

```sh
npm run release:github:check
npm run release:github:archive
npm run release:github:export
npm run release:github:notarize
npm run release:github:zip
npm run release:github:appcast
npm run release:github:publish
```

The final zip is written to:

```sh
build/release/free-ruler-X.Y.Z.zip
```

`build/release/` is ignored by git. New release zips are uploaded to the draft
GitHub Release and should not be copied into the repository. `.gitignore`
prevents future `dist/*.zip` artifacts from being added accidentally.

The GitHub release is created as a draft so release notes and the uploaded zip
can be reviewed before publishing.

</details>

<details>
<summary>Version commands</summary>

Show the current version:

```sh
npm run get:version
```

Bump the version interactively:

```sh
npm run bump:version
```

This also sets the Xcode build number from the current git commit count and can
commit and push the bump when confirmed.

Set an exact version:

```sh
npm run release:version -- X.Y.Z
```

Set an exact version and Xcode build number:

```sh
npm run release:version -- X.Y.Z 303
```

</details>

<details>
<summary>Sparkle updates</summary>

GitHub release builds enable Sparkle updates. The App Store target does not
include Sparkle.

Sparkle expects:

- Sparkle's `sign_update` tool on `PATH`, or `SPARKLE_SIGN_UPDATE` set to its
  full path.
- `SPARKLE_PUBLIC_ED_KEY` set to the public EdDSA update key. The matching
  private key must be available to Sparkle's signing tool when generating the
  appcast. `SPARKLE_PUBLIC_ED_KEY` can live in `.env`.

The release command writes the appcast to:

```sh
build/release/appcast.xml
```

The draft GitHub Release uploads both the zip and `appcast.xml`. Published
GitHub releases serve the update feed at:

```text
https://github.com/pascalpp/FreeRuler/releases/latest/download/appcast.xml
```

</details>

## Manual App Store Release

The App Store path is not automated yet.

1. Archive the app in Xcode.
2. Choose **Distribute App > App Store Connect > Upload**.
3. Visit App Store Connect.
4. Create a new version if needed.
5. Select the uploaded build.
6. Update release notes and metadata.
7. Submit for review.

Future automation should add a separate App Store export/upload path instead of
overloading the GitHub release scripts.
