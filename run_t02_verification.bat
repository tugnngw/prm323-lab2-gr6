@echo off
echo === RUNNING FLUTTER ANALYZE === > t02_verification.log
call flutter analyze >> t02_verification.log 2>&1
echo ANALYZE_EXIT=%ERRORLEVEL% >> t02_verification.log

echo === RUNNING FLUTTER TEST === >> t02_verification.log
call flutter test >> t02_verification.log 2>&1
echo TEST_EXIT=%ERRORLEVEL% >> t02_verification.log

echo === RUNNING FLUTTER BUILD APK DEBUG === >> t02_verification.log
call flutter build apk --debug >> t02_verification.log 2>&1
echo BUILD_EXIT=%ERRORLEVEL% >> t02_verification.log

if exist docs\t02-test.tmp del docs\t02-test.tmp
echo === VERIFICATION COMPLETE === >> t02_verification.log
