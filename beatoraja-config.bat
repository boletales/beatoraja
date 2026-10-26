set _JAVA_OPTIONS=-Dfile.encoding="UTF-8"
pushd %~dp0
java -Xms1g -Xmx4g -cp "beatoraja.jar:ir/*" bms.player.beatoraja.MainLoader
popd
