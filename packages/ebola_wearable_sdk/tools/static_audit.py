#!/usr/bin/env python3
"""Read-only shell audit. Does NOT compile Dart or connect to a device."""
import json, re, sys
from pathlib import Path
root = Path(__file__).resolve().parent.parent
errors=[]
files=list(root.rglob('*'))
source=[p for p in files if p.suffix=='.dart']
for p in source:
    t=p.read_text(encoding='utf-8')
    for rel in re.findall(r"(?:import|export|part)\s+'([^']+)'",t):
        if rel.startswith('dart:') or rel.startswith('package:'):
            if rel.startswith('package:ebola_wearable_sdk/') and not (root/'lib'/rel.split('/',1)[1]).is_file():
                errors.append(f'{p.relative_to(root)}: missing {rel}')
            continue
        if not (p.parent/rel).is_file():
            errors.append(f'{p.relative_to(root)}: missing {rel}')
for name in ['pubspec.yaml','lib/ebola_wearable_sdk.dart',
             'test/models_test.dart','test/licensing_test.dart',
             'api/licensing_contract.json','docs/SECURITY.md']:
    if not (root/name).is_file(): errors.append('missing '+name)
for p in root.rglob('*.json'):
    try: json.loads(p.read_text())
    except Exception as e: errors.append(f'{p.relative_to(root)}: invalid JSON {e}')
print('EBOLA SDK STATIC AUDIT')
print('DART_FILES=',len(source),'ALL_FILES=',len([p for p in files if p.is_file()]))
print('DART_COMPILATION=NOT_RUN_BY_THIS_SCRIPT')
print('HARDWARE_TEST=NOT_RUN_BY_THIS_SCRIPT')
for issue in errors:print('FAIL:',issue)
print('STATIC_AUDIT='+('PASS' if not errors else 'FAIL'))
sys.exit(bool(errors))
