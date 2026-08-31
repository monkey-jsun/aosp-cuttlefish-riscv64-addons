# Copyright (C) 2026 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0
#
# aosp_cf_riscv64_phone_js — stock Cuttlefish riscv64 phone plus preinstalled apps.
# No AOSP repo is patched; this product inherits the stock one and adds packages.

$(call inherit-product, device/google/cuttlefish/vsoc_riscv64/phone/aosp_cf.mk)

PRODUCT_NAME := aosp_cf_riscv64_phone_js
PRODUCT_MODEL := Cuttlefish riscv64 phone (js)

# aosp_cf.mk sets this only under `ifeq ($(TARGET_PRODUCT),aosp_cf_riscv64_phone)`,
# which stops firing once we rename. Must be set here or the build mode changes.
PRODUCT_SOONG_ONLY := $(RELEASE_SOONG_ONLY_CUTTLEFISH)

# TARGET_DEVICE stays vsoc_riscv64, so BoardConfig, the device tree and
# PRODUCT_IGNORE_ALL_ANDROIDMK := true are all inherited unchanged.

PRODUCT_PACKAGES += \
    webview_riscv64 \
    FDroid \
    init.js.rc

# No launcher customization: F-Droid declares android.intent.category.APP_MARKET,
# which the stock default_workspace_4x4.xml already places at screen 0, x=3, y=-1
# via a <resolve> block. Verified on k3-jun 2026-08-31.
