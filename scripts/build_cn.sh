#!/bin/bash
# Husk CN build: Chinese UI + translation-layer crash hardening, linking the
# prebuilt QEMU/ANGLE/MoltenVK blobs taken from the official 3.0 IPA.
# Produces an unsigned Husk-3.0-cn.ipa at the repo root.
set -euo pipefail
HUSK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HUSK_ROOT"

echo "===== 1/5 fetch official 3.0 IPA (prebuilt blobs + guest resources) ====="
rm -rf official_payload
mkdir -p official_payload
curl -sL --retry 3 -o /tmp/husk-official.ipa https://github.com/Leviidev/Husk/releases/download/3.0/Husk.ipa
SZ=$(wc -c < /tmp/husk-official.ipa | tr -d ' ')
echo "IPA size: $SZ"
[ "$SZ" -gt 100000000 ] || { echo "IPA download too small -- aborting"; exit 1; }
(cd official_payload && unzip -q /tmp/husk-official.ipa)
mv official_payload/Payload/Husk.app official_payload/Husk.app
rmdir official_payload/Payload
ls official_payload/Husk.app/Frameworks/

echo "===== 1.5/5 stage prebuilt dylibs into build/ layout ====="
OFF=official_payload/Husk.app
mkdir -p build/ios-arm64/lib build/ios-arm64/sysroot/lib
cp "$OFF/Frameworks/libqemu-aarch64-softmmu.dylib" build/ios-arm64/lib/
cp "$OFF/Frameworks/libhuskps4.dylib" build/ios-arm64/lib/
cp "$OFF/Frameworks/libANGLE-shared.dylib" build/ios-arm64/sysroot/lib/
cp -R "$OFF/Frameworks/MoltenVK.framework" build/ios-arm64/lib/MoltenVK.framework
ls -la build/ios-arm64/lib build/ios-arm64/sysroot/lib

echo "===== 2/5 rust: build libhusk_rppairing.a ====="
rustup target add aarch64-apple-ios 2>/dev/null || true
./scripts/build_rppairing_ios.sh

echo "===== 3/5 xcodegen ====="
command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
(cd src/app && xcodegen generate)

echo "===== 4/5 xcodebuild (unsigned) ====="
set -o pipefail
xcodebuild -project src/app/Husk.xcodeproj -scheme Husk -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/dd \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build 2>&1 | {
  # keep the tail visible but fail on BUILD FAILED / errors
  tee /tmp/xc.log | grep -E "error:|warning: Swift|BUILD|CompileSwift|SwiftCompile|Ld " | tail -60
}
grep -q "BUILD SUCCEEDED" /tmp/xc.log || { echo "BUILD FAILED -- last errors:"; grep -B2 -A8 "error:" /tmp/xc.log | tail -80; exit 1; }

echo "===== 5/5 package IPA ====="
APP="build/dd/Build/Products/Release-iphoneos/Husk.app"
test -d "$APP" || { echo "app missing"; exit 1; }
rm -rf Payload Husk-3.0-cn.ipa
mkdir -p Payload
cp -R "$APP" Payload/
zip -qry Husk-3.0-cn.ipa Payload
ls -la Husk-3.0-cn.ipa
echo "DONE"
