# aosp-cuttlefish-riscv64-addons

Add-on layer for [aosp-cuttlefish-riscv64](https://github.com/monkey-jsun/aosp-cuttlefish-riscv64):
preinstalled apps for the AOSP riscv64 Cuttlefish guest on the SpaceMiT K3.

**No AOSP repo is patched.** This repo is injected into the manifest, declares its own
product inheriting the stock `aosp_cf_riscv64_phone`, and adds packages to it. Adding
another app later is a commit here and nothing else.

## How it attaches

`AndroidProducts.mk` is discovered by a tree-wide scan
(`build/make/core/product_config.mk:151` reads the list Soong's finder produces), so
no registration in AOSP is needed. Add to the manifest:

```xml
<remote name="github" fetch="https://github.com/"/>
<project name="monkey-jsun/aosp-cuttlefish-riscv64-addons" path="device/monkey-jsun/cuttlefish_riscv64"
         remote="github" revision="<pinned sha>"/>
```

Then build:

```sh
tools/fetch-apks.sh            # pull + verify the pinned APKs
source build/envsetup.sh
lunch aosp_cf_riscv64_phone_js-trunk_staging-userdebug
BUILD_NUMBER=v1.2 m dist
```

`TARGET_DEVICE` stays `vsoc_riscv64`, so the device tree, BoardConfig and
`PRODUCT_IGNORE_ALL_ANDROIDMK` are inherited unchanged. `PRODUCT_SOONG_ONLY` is set
explicitly because the stock makefile guards it on the product name.

## Contents

| path | what |
|---|---|
| `aosp_cf_js.mk` | the product: inherits stock, adds `PRODUCT_PACKAGES` |
| `apps/webview/` | Chromium 151 WebView provider (APK fetched, not in git) |
| `apps/fdroid/` | F-Droid client (APK fetched, not in git) |
| `etc/init.js.rc` | pre-grants F-Droid's "install unknown apps" AppOp at boot |
| `prebuilts/apk-pins.tsv` | size + sha256 + source for every third-party APK |
| `tools/fetch-apks.sh` | fetch and verify; idempotent, safe before every build |

## Notes worth knowing

**WebView.** AOSP ships no riscv64 WebView: `external/chromium-webview/Android.bp`
has no `riscv64` arm, so Soong disables the stock `webview` module silently and the
guest reports "Current WebView package is null". Everything else is already in the
image; only the APK is missing. We supply it as a separate module — the same approach
BayLibre uses, and there is no package-name collision because the stock module is
disabled on this arch. Chromium **151** specifically: 141 crashes when
`ro.vendor.api_level >= 202604`.

**F-Droid is stripped and re-signed by the build.** `strip_unused_jni_arch` is
mandatory, not an optimisation — a preinstalled system app whose native libs do not
match the device ABI is rejected at boot scan with `errorCode=-113`
(`INSTALL_FAILED_NO_MATCHING_ABIS`); the system-image path is not exempt. Because
that re-signs the APK, F-Droid's self-update from its own repo will fail on signature
mismatch, and the F-Droid Privileged Extension can never accept us (it hardcodes
F-Droid's release certificate hash). Users confirm each install; they are not asked
to grant permission first.

**No launcher customization.** F-Droid declares `android.intent.category.APP_MARKET`
and the stock `default_workspace_4x4.xml` already places that category at screen 0,
x=3 — so a preinstalled F-Droid lands on the home screen with nothing added here.

## Licences

This repo contains **no third-party binaries**. Both APKs are fetched at build time
from their upstream sources — a URL and a sha256, recorded in
`prebuilts/apk-pins.tsv` — so nothing here redistributes them. WebView comes from
BayLibre's `android_device_spacemit_common` (Chromium: BSD with LGPL components);
F-Droid from f-droid.org (GPL-3.0). Build files in this repo are Apache-2.0.
