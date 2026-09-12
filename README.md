# aosp-cuttlefish-riscv64-addons

The AOSP guest image for [aosp-cuttlefish-riscv64](https://github.com/monkey-jsun/aosp-cuttlefish-riscv64):
an Android riscv64 phone image that runs as a Cuttlefish guest on a riscv64 host such as the SpaceMiT K3.

This repo is the image's home:
- definition of product `aosp_cf_riscv64_phone_js`, inheriting the stock `aosp_cf_riscv64_phone`
- the manifest that pins the AOSP tree it is built from
- pre-installed add-on apps for convenience
  - **A WebView provider** — AOSP ships none for riscv64. BayLibre's build.
  - **F-Droid**, app store of open-source apps

## Build from source

### Prerequisites

- Linux **x86_64** build host — AOSP does not support riscv64 as a build host.
- ~150 GB to sync, ~320 GB once built. A clean first build is ~2–4 h; incremental
  rebuilds are minutes.
- The [`repo`](https://gerrit.googlesource.com/git-repo/) tool.

### Get the source

```sh
mkdir android17-release && cd android17-release
repo init --partial-clone --no-use-superproject \
    -u https://github.com/monkey-jsun/aosp-cuttlefish-riscv64-addons \
    -b main \
    -m manifests/aosp-cf-js-baseline.xml
repo sync -j8 -c --no-tags --optimized-fetch --retry-fetches=3
```

`-b main` gives the current baseline. To reproduce a released image, use its tag instead:
`-b v1.3.2`.

### Fetch the pinned APKs

Third-party APKs are not stored in git. They are downloaded and sha256-verified against
[`prebuilts/apk-pins.tsv`](prebuilts/apk-pins.tsv). Idempotent, so it is safe to re-run
before any build.

```sh
device/monkey-jsun/cuttlefish_riscv64/tools/fetch-apks.sh
```

### Build

```sh
source build/envsetup.sh
lunch aosp_cf_riscv64_phone_js-trunk_staging-userdebug
BUILD_NUMBER=v1.3.2 m dist
```

Output: `out/dist/aosp_cf_riscv64_phone_js-img-v1.3.2.zip` (~900 MB).

### Cutting a release (maintainers)

The manifest pins this repo by SHA, so the commit that records the manifest cannot be the
one it pins. A cut is therefore two commits:

1. Commit the product changes. Build from that tree and verify it.
2. Snapshot what was built and commit the record:
   ```sh
   repo manifest -r -o device/monkey-jsun/cuttlefish_riscv64/manifests/aosp-cf-js-baseline.xml
   ```
3. Tag that second commit `vX.Y.Z` and release the zip on it:
   ```sh
   gh release create vX.Y.Z --title vX.Y.Z --notes "<notes>" out/dist/aosp_cf_riscv64_phone_js-img-vX.Y.Z.zip
   ```

Reproducing `-b vX.Y.Z` reads the manifest from the tagged commit and checks this repo out
one commit earlier — at what was actually built.

## Run it

Refer to
[umbrella README](https://github.com/monkey-jsun/aosp-cuttlefish-riscv64#readme)

## Contents

This repo is attached at `device/monkey-jsun/cuttlefish_riscv64` in the AOSP source tree.

| path | what |
|---|---|
| `manifests/aosp-cf-js-baseline.xml` | the pinned AOSP tree; versioned by this repo's tags |
| `aosp_cf_js.mk` | the product: inherits stock, adds `PRODUCT_PACKAGES` |
| `apps/webview/` | Chromium 151 WebView provider (APK fetched, not in git) |
| `apps/fdroid/` | F-Droid client (APK fetched, not in git) |
| `prebuilts/apk-pins.tsv` | size + sha256 + source for every third-party APK |
| `tools/fetch-apks.sh` | fetch and verify; idempotent, safe before every build |

## Licences

Third-party apps are fetched at build time from their upstream sources — a URL and a sha256, recorded in `prebuilts/apk-pins.tsv`.

- WebView from BayLibre's `android_device_spacemit_common` (Chromium: BSD with LGPL components)
- F-Droid from f-droid.org (GPL-3.0)
- Build files in this repo are Apache-2.0
