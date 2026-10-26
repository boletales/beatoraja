#!/bin/bash
export _JAVA_OPTIONS=-Dfile.encoding="UTF-8"
cd "$(dirname "$0")"
exec java -Xms1g -Xmx4g -XX:+UseZGC -Djava.library.path=./natives -cp "beatoraja.jar:ir/*" bms.player.beatoraja.MainLoader
