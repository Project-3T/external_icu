#
# Copyright (C) 2014 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

# User-supplied locale service providers (using the java.text.spi or
# java.util.spi mechanisms) are not supported in Android:
#
# http://developer.android.com/reference/java/util/Locale.html

icu4j_src_files := \
    $(filter-out main/classes/localespi/%, \
    $(call all-java-files-under,main/classes))

icu4j_test_src_files := \
    $(filter-out main/tests/localespi/%, \
    $(call all-java-files-under,main/tests))

# Not all src dirs contain resources, some instead contain other random files
# that should not be included as resources. The ones that should be included
# can be identifed by the fact that they contain particular subdir trees.

define all-subdir-with-subdir
$(patsubst $(LOCAL_PATH)/%/$(2),%,$(wildcard $(LOCAL_PATH)/$(1)/$(2)))
endef

icu4j_resource_dirs := \
    $(filter-out main/classes/localespi/%, \
    $(call all-subdir-with-subdir,main/classes/*/src,com/ibm/icu))

icu4j_test_resource_dirs := \
    $(filter-out main/tests/localespi/%, \
    $(call all-subdir-with-subdir,main/tests/*/src,com/ibm/icu/dev))

# For each data *.jar file, define a corresponding icu4j-* target.
icu4j_data_jars := \
    $(shell find $(LOCAL_PATH)/main/shared/data -name "*.jar" \
    | sed "s,^$(LOCAL_PATH)/\(.*/\(.*\)\.jar\)$$,icu4j-\2:\1,")

include $(CLEAR_VARS)
LOCAL_PREBUILT_STATIC_JAVA_LIBRARIES := $(icu4j_data_jars)
include $(BUILD_MULTI_PREBUILT)

include $(CLEAR_VARS)
LOCAL_IS_HOST_MODULE := true
LOCAL_PREBUILT_STATIC_JAVA_LIBRARIES := $(subst :,-host:,$(icu4j_data_jars))
include $(BUILD_MULTI_PREBUILT)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(icu4j_src_files)
LOCAL_JAVA_RESOURCE_DIRS := $(icu4j_resource_dirs)
LOCAL_MODULE := icu4j
include $(BUILD_STATIC_JAVA_LIBRARY)

# Path to the ICU4C data files in the Android device file system:
icu4c_data := /system/usr/icu
icu4j_config_root := $(LOCAL_PATH)/main/classes/core/src
include external/icu/icu4j/adjust_icudt_path.mk

include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(icu4j_src_files)
LOCAL_JAVA_RESOURCE_DIRS := $(icu4j_resource_dirs)
LOCAL_STATIC_JAVA_LIBRARIES := icu4j-icudata-host icu4j-icutzdata-host
LOCAL_MODULE := icu4j-host
include $(BUILD_HOST_JAVA_LIBRARY)

ifeq ($(HOST_OS),linux)
include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(icu4j_src_files)
LOCAL_JAVA_RESOURCE_DIRS := $(icu4j_resource_dirs)
LOCAL_STATIC_JAVA_LIBRARIES := icu4j-icudata-host icu4j-icutzdata-host
LOCAL_MODULE := icu4j-hostdex
include $(BUILD_HOST_DALVIK_JAVA_LIBRARY)
endif  # HOST_OS == linux

include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(icu4j_test_src_files)
LOCAL_JAVA_RESOURCE_DIRS := $(icu4j_test_resource_dirs)
LOCAL_STATIC_JAVA_LIBRARIES := icu4j-testdata
LOCAL_JAVA_LIBRARIES := icu4j
LOCAL_MODULE := icu4j-tests
include $(BUILD_STATIC_JAVA_LIBRARY)

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_EXTRA_JAR_ARGS += \
    -C "$(LOCAL_PATH)/main/tests/core/src" \
    "com/ibm/icu/dev/test/serializable/data"

include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(icu4j_test_src_files)
LOCAL_JAVA_RESOURCE_DIRS := $(icu4j_test_resource_dirs)
LOCAL_STATIC_JAVA_LIBRARIES := icu4j-testdata-host
LOCAL_JAVA_LIBRARIES := icu4j-host
LOCAL_MODULE := icu4j-tests-host
include $(BUILD_HOST_JAVA_LIBRARY)

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_EXTRA_JAR_ARGS += \
    -C "$(LOCAL_PATH)/main/tests/core/src" \
    "com/ibm/icu/dev/test/serializable/data"

ifeq ($(HOST_OS),linux)
include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(icu4j_test_src_files)
LOCAL_JAVA_RESOURCE_DIRS := $(icu4j_test_resource_dirs)
LOCAL_STATIC_JAVA_LIBRARIES := icu4j-testdata-host
LOCAL_JAVA_LIBRARIES := icu4j-hostdex
LOCAL_MODULE := icu4j-tests-hostdex
include $(BUILD_HOST_DALVIK_JAVA_LIBRARY)

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_EXTRA_JAR_ARGS += \
    -C "$(LOCAL_PATH)/main/tests/core/src" \
    "com/ibm/icu/dev/test/serializable/data"

endif  # HOST_OS == linux

# LayoutLib (frameworks/base/tools/layoutlib) needs JarJar'd versions of the
# icudata and icutzdata, so add rules for it.
include $(CLEAR_VARS)
LOCAL_STATIC_JAVA_LIBRARIES := icu4j-icudata-host
LOCAL_JARJAR_RULES := $(LOCAL_PATH)/liblayout-jarjar-rules.txt
LOCAL_MODULE := icu4j-icudata-host-jarjar
include $(BUILD_HOST_JAVA_LIBRARY)

include $(CLEAR_VARS)
LOCAL_STATIC_JAVA_LIBRARIES := icu4j-icutzdata-host
LOCAL_JARJAR_RULES := $(LOCAL_PATH)/liblayout-jarjar-rules.txt
LOCAL_MODULE := icu4j-icutzdata-host-jarjar
include $(BUILD_HOST_JAVA_LIBRARY)

# build repackaged ICU tests
#
# Builds against core-libart and core-oj so that it can access all the
# repackaged android.icu classes and methods and not just the ones available
# through the Android API.
include $(CLEAR_VARS)

android_icu4j_tests := ../android_icu4j/src/main/tests

# Don't include this package in any target
LOCAL_MODULE_TAGS := tests
LOCAL_SRC_FILES := \
	$(call all-java-files-under,$(android_icu4j_tests))
LOCAL_JAVA_RESOURCE_DIRS := $(android_icu4j_tests)
LOCAL_JAVA_LIBRARIES := \
	core-oj \
	core-libart
LOCAL_NO_STANDARD_LIBRARIES := true
LOCAL_MODULE := android-icu4j-tests
include $(BUILD_STATIC_JAVA_LIBRARY)
