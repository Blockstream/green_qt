include(version.pri)

DEFINES += "VERSION_MAJOR=$$VERSION_MAJOR"\
   "VERSION_MINOR=$$VERSION_MINOR"\
   "VERSION_PATCH=$$VERSION_PATCH" \
   "VERSION_PRERELEASE=\"$$VERSION_PRERELEASE\"" \

CI = $$(CI)
CI_BUILD_TAG = $$(CI_BUILD_TAG)
CI_COMMIT_SHORT_SHA = $$(CI_COMMIT_SHORT_SHA)

equals(CI, "true") {
    equals(CI_BUILD_TAG, "") {
        DEFINES += "VERSION=\"$${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}-$${CI_COMMIT_SHORT_SHA}\""
    } else {
        DEFINES += "VERSION=\"$${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}\""
    }
} else:system(git --version) {
    VERSION = $$system(git describe --tags --dirty --long)
    VERSION = $$split(VERSION, "_")
    VERSION = $$member(VERSION, 1)
    DEFINES += "VERSION=\"$${VERSION}\""
} else {
    DEFINES += "VERSION=\"$${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}\""
}
