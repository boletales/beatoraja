#!/bin/bash

cd "$(dirname "$0")"

# === Settings ===

# beatoraja 0.8.8+ requires JRE 17+ and JavaFX!
# Since OpenJDK 17 no longer includes JavaFX, you need a JRE with JavaFX included (e.g., Liberica JRE Full) or place OpenJFX separately.

# Set JRE_PATH if you use a portable JRE (e.g. if you placed Liberica JRE Full 25.0.5.0.3+5 in the beatoraja folder, set JRE_PATH="jre-25.0.5.0.3-full")
JRE_PATH=""

# Set JavaFX_PATH if you use a portable JavaFX (e.g. if you placed OpenJFX 27.0.1 in the beatoraja folder, set JAVA_FX_PATH="javafx-sdk-27.0.1")
JAVAFX_PATH=""

# beatoraja runtime options
JAVA_OPTS="-Xms1g -Xmx4g -XX:+UseZGC -Djava.library.path=./natives"

# ======

# Set java PATH
if [ -n "$JRE_PATH" ]; then
  if [ -d "$JRE_PATH" ]; then
    export JAVA_HOME="$(cd "$JRE_PATH" && pwd -P)"
    export PATH="$JAVA_HOME/bin:$PATH"
  else
    echo "[beatoraja-config.command] Error: JRE_PATH is set but the directory does not exist: $JRE_PATH."
    read -p "Press Enter to exit..."
    exit 1
  fi
fi

# Check if Java exists
if ! command -v java &> /dev/null; then
  if [ -n "$JRE_PATH" ]; then
    echo "[beatoraja-config.command] Error: Java not found in the specified JRE_PATH: $JRE_PATH. Please check the path or install JRE 17+."
  else
    echo "[beatoraja-config.command] Error: Java not found. Please install JRE 17+ or set JRE_PATH in beatoraja-config.command."
  fi
  read -p "Press Enter to exit..."
  exit 1
fi

# Check if java comes from the specified JRE_PATH
if [ -n "$JRE_PATH" ]; then
  JAVA_PATH=$(command -v java)
  if [[ "$JAVA_PATH" != *"$JRE_PATH"* ]]; then
    echo "[beatoraja-config.command] Warning: System Java is being used instead of the specified JRE_PATH. JRE_PATH: $JRE_PATH, Detected Java path: $JAVA_PATH"
  fi
fi

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
JAVA_MAJOR_VERSION=$(echo "$JAVA_VERSION" | awk -F. '{print $1}')
if [ "$JAVA_MAJOR_VERSION" -lt 17 ]; then
  echo "[beatoraja-config.command] Error: beatoraja requires Java 17 or higher. Detected version: $JAVA_VERSION"
  read -p "Press Enter to exit..."
  exit 1
fi

# Set JavaFX
if [ -n "$JAVAFX_PATH" ]; then
  # since beatoraja 0.8.9, child processes needs JavaFX too.
  export JDK_JAVA_OPTIONS="--module-path \"$PWD/$JAVAFX_PATH/lib\" --add-modules=javafx.controls,javafx.fxml"
fi

# Check if JavaFX exists
if ! java --describe-module javafx.controls &> /dev/null; then
  echo "[beatoraja-config.command] Error: JavaFX not found. Use a JRE with JavaFX included (e.g., Liberica JRE Full) or place OpenJFX and set JAVAFX_PATH in beatoraja-config.command."
  read -p "Press Enter to exit..."
  exit 1
fi

# Run beatoraja
export _JAVA_OPTIONS=-Dfile.encoding="UTF-8"
exec java $JAVA_OPTS -cp "beatoraja.jar:ir/*" bms.player.beatoraja.MainLoader
