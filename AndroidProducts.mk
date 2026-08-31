# Copyright (C) 2026 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0
#
# Discovered automatically: the build scans the whole tree for AndroidProducts.mk
# (build/make/core/product_config.mk:151 reads the list produced by Soong's finder),
# so this repo works at any checkout path. No registration in AOSP is required.

PRODUCT_MAKEFILES := \
    aosp_cf_riscv64_phone_js:$(LOCAL_DIR)/aosp_cf_js.mk

COMMON_LUNCH_CHOICES := \
    aosp_cf_riscv64_phone_js-trunk_staging-userdebug
