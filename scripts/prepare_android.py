#!/usr/bin/env python3
"""Prepare generated Android test app, preserving unrelated source files."""
import pathlib,sys,xml.etree.ElementTree as ET,re
app=pathlib.Path(sys.argv[1]).resolve() if len(sys.argv)>1 else pathlib.Path('.').resolve()
manifest=app/'android/app/src/main/AndroidManifest.xml'
if not manifest.exists():
    sys.exit('ERROR: Android manifest missing: run flutter create first')
content=manifest.read_text(encoding='utf-8')
permissions=['android.permission.BLUETOOTH_SCAN','android.permission.BLUETOOTH_CONNECT','android.permission.ACCESS_FINE_LOCATION','android.permission.ACCESS_WIFI_STATE','android.permission.CHANGE_WIFI_STATE','android.permission.INTERNET']
# Android namespace exists in generated Flutter manifest.
for p in permissions:
    if f'android:name="{p}"' not in content:
        content=content.replace('<application',f'    <uses-permission android:name="{p}" />\n    <application',1)
manifest.write_text(content,encoding='utf-8')
try: ET.parse(manifest)
except Exception as exc: sys.exit(f'ERROR: invalid AndroidManifest.xml: {exc}')
# Enforce plugin minSDK without guessing Gradle structure.
gradles=[app/'android/app/build.gradle.kts',app/'android/app/build.gradle']
found=[]
for path in gradles:
    if not path.exists(): continue
    c=path.read_text(encoding='utf-8')
    before=c
    c,n=re.subn(r'(?m)^(\s*minSdk\s*=\s*)flutter\.minSdkVersion\b',r'\g<1>24',c)
    if not n: c,n=re.subn(r'(?m)^(\s*minSdkVersion\s+)flutter\.minSdkVersion\b',r'\g<1>24',c)
    if not n:
        c,n=re.subn(r'(?m)^(\s*minSdk\s*=\s*)\d+',r'\g<1>24',c)
    if not n:
        c,n=re.subn(r'(?m)^(\s*minSdkVersion\s+)\d+',r'\g<1>24',c)
    if not n: sys.exit(f'ERROR: could not locate minSdk setting in {path}; do not guess')
    path.write_text(c,encoding='utf-8')
    found.append(str(path))
if not found: sys.exit('ERROR: Android Gradle build file missing')
print('PASS Android manifest well-formed')
print('PASS required BLE/WiFi/Internet permissions present')
print('PASS minSdkVersion 24 set:', ', '.join(found))
print('NOTE: Android 12+ Bluetooth permissions still require runtime consent in app.')
