include(version.pri)

DEFINES += "VERSION_MAJOR=$$VERSION_MAJOR"\
   "VERSION_MINOR=$$VERSION_MINOR"\
   "VERSION_PATCH=$$VERSION_PATCH" \
   "VERSION_PRERELEASE=\"$$VERSION_PRERELEASE\"" \

CI = $$(CI)
CI_COMMIT_SHORT_SHA = $$(CI_COMMIT_SHORT_SHA)

equals(CI, "true") {
    DEFINES += "VERSION=\"$${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}-$${CI_COMMIT_SHORT_SHA}\""
} else:system(git --version) {
    VERSION = $$system(git describe --tags --dirty --long | cut -c9-)
    DEFINES += "VERSION=\"$${VERSION}\""
} else {
    DEFINES += "VERSION=\"$${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}\""
}
