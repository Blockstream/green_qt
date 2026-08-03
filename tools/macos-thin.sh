#!/bin/bash
set -eo pipefail

# macdeployqt copies Qt's universal frameworks into the bundle as-is, which roughly
# doubles the size of the single-architecture dmgs. Drop every slice but $ARCH.
# Must run before codesign: lipo invalidates existing signatures.

APP=$1
ARCH=$2

if [ -z "$APP" ] || [ -z "$ARCH" ]; then
    echo "usage: $0 <bundle> <arch>" >&2
    exit 1
fi

# guard against thinning a bundle to the wrong architecture
MAIN_ARCHS=$(lipo -archs "$APP/Contents/MacOS/Blockstream")
if [ "$MAIN_ARCHS" != "$ARCH" ]; then
    echo "$APP is $MAIN_ARCHS, refusing to thin to $ARCH" >&2
    exit 1
fi

while IFS= read -r file; do
    # not a Mach-O file
    archs=$(lipo -archs "$file" 2>/dev/null) || continue
    case " $archs " in
        *" $ARCH "*) ;;
        *)
            echo "$file has no $ARCH slice ($archs)" >&2
            exit 1
            ;;
    esac
    if [ "$archs" = "$ARCH" ]; then
        continue
    fi
    echo "thinning $file ($archs)"
    lipo "$file" -thin "$ARCH" -output "$file.thin"
    chmod "$(stat -f %Lp "$file")" "$file.thin"
    mv -f "$file.thin" "$file"
done < <(find "$APP" -type f)
