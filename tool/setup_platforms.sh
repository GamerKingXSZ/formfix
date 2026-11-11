#!/bin/sh
set -e
command -v flutter >/dev/null || { echo "flutter not found on PATH"; exit 1; }

flutter create --platforms=android,ios --project-name formfix .
flutter pub get

python3 - <<'PY'
import re, pathlib

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
t = m.read_text()
if 'android.permission.CAMERA' not in t:
    t = re.sub(r'(<manifest[^>]*>)',
               r'\1\n    <uses-permission android:name="android.permission.CAMERA"/>',
               t, count=1)
    m.write_text(t)
    print('Android: added CAMERA permission')

pl = pathlib.Path('ios/Runner/Info.plist')
t = pl.read_text()
add = {
  'NSCameraUsageDescription': 'FormFix uses the camera to scan documents. Nothing is uploaded.',
  'NSPhotoLibraryUsageDescription': 'FormFix reads photos you choose so it can resize them. Nothing is uploaded.',
}
block = ''.join(f'\t<key>{k}</key>\n\t<string>{v}</string>\n'
                for k, v in add.items() if k not in t)
if block:
    i = t.rindex('</dict>')
    pl.write_text(t[:i] + block + t[i:])
    print('iOS: added usage descriptions')

pf = pathlib.Path('ios/Podfile')
if pf.exists():
    t = pf.read_text()
    new = re.sub(r"^\s*#?\s*platform :ios,.*$", "platform :ios, '15.5'", t, count=1, flags=re.M)
    if new != t:
        pf.write_text(new)
        print("iOS: Podfile platform set to 15.5")
PY

echo "Done."
