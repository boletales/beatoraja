#!/bin/bash

cd "$(dirname "$0")"

# === Settings ===

# beatoraja 0.8.8+ requires JRE 17+ and JavaFX!
# Since Java 11, JavaFX is no longer bundled with most JDKs, you need a JRE with JavaFX included (e.g., Liberica JRE Full) or place OpenJFX separately.

# Set JRE_PATH if you use a portable JRE/JDK (e.g. if you placed Liberica JRE Full 25.0.5.0.3+5 at <beatoraja folder>/jre-25.0.5.0.3-full, set JRE_PATH="jre-25.0.5.0.3-full")
JRE_PATH=""

# Set JAVAFX_PATH if you use a portable JavaFX (e.g. if you placed OpenJFX 27.0.1 at <beatoraja folder>/javafx-sdk-27.0.1, set JAVAFX_PATH="javafx-sdk-27.0.1")
JAVAFX_PATH=""

# beatoraja runtime options
JAVA_OPTS="-Djava.library.path=./natives -Xms1g -Xmx4g -XX:+UseZGC"

# ======

# Set java PATH
if [ -n "$JRE_PATH" ]; then
  if [ -d "$JRE_PATH" ]; then
    export JAVA_HOME="$(cd "$JRE_PATH" && pwd -P)"
    export PATH="$JAVA_HOME/bin:$PATH"
    if [ ! -x "$JAVA_HOME/bin/java" ]; then
      echo "[beatoraja-config.command] Error: java executable not found in $JAVA_HOME/bin."
      read -p "Press Enter to exit..."
      exit 1
    fi
  else
    echo "[beatoraja-config.command] Error: JRE_PATH is set but the directory does not exist: $JRE_PATH."
    read -p "Press Enter to exit..."
    exit 1
  fi
fi

# Check if Java exists
if ! command -v java &> /dev/null; then
  echo "[beatoraja-config.command] Error: Java not found. Please install JRE 17+ or set JRE_PATH in beatoraja-config.command."
  read -p "Press Enter to exit..."
  exit 1
fi

# Check Java version and location
JAVA_PROPS=$(java -XshowSettings:properties -version 2>&1)
java_prop() { printf '%s\n' "$JAVA_PROPS" | sed -n "s/^ *$1 = //p"; }
JAVA_VERSION=$(java_prop 'java\.version')
JAVA_SPEC_VERSION=$(java_prop 'java\.specification\.version')
JAVA_RUNTIME_HOME=$(java_prop 'java\.home')
JAVA_MAJOR_VERSION=${JAVA_SPEC_VERSION#1.}

if ! [ "$JAVA_MAJOR_VERSION" -ge 17 ] 2>/dev/null; then
  echo "[beatoraja-config.command] Error: beatoraja requires Java 17 or higher. Detected version: ${JAVA_VERSION:-Unknown}"
  read -p "Press Enter to exit..."
  exit 1
fi

if [ -n "$JRE_PATH" ]; then
  echo "[beatoraja-config.command] Using Java from JRE_PATH: ${JAVA_RUNTIME_HOME:-unknown} (version: $JAVA_VERSION)"
else
  echo "[beatoraja-config.command] Using system Java: ${JAVA_RUNTIME_HOME:-unknown} (version: $JAVA_VERSION)"
fi

# Set JavaFX PATH to JDK_JAVA_OPTIONS if defined
if [ -n "$JAVAFX_PATH" ]; then
  if [ -d "$JAVAFX_PATH/lib" ]; then
    RESOLVED_JAVAFX="$(cd "$JAVAFX_PATH" && pwd -P)"
    # The IR worker (0.8.9+) runs as a separate process and does not inherit command-line options, so JavaFX must be passed via JDK_JAVA_OPTIONS.
    export JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS:+$JDK_JAVA_OPTIONS }--module-path \"$RESOLVED_JAVAFX/lib\" --add-modules=javafx.controls,javafx.fxml"
  else
    echo "[beatoraja-config.command] Error: JAVAFX_PATH is set but the directory does not exist: $JAVAFX_PATH."
    read -p "Press Enter to exit..."
    exit 1
  fi
fi


# Check if JavaFX exists
if ! java --describe-module javafx.controls &> /dev/null; then
  if [ -n "$JAVAFX_PATH" ] && [ -f "$RESOLVED_JAVAFX/lib/javafx.controls.jar" ]; then
    FX_VERSION=$(sed -n 's/^javafx\.version=//p' "$RESOLVED_JAVAFX/lib/javafx.properties" 2>/dev/null)
    echo "[beatoraja-config.command] Error: JavaFX ${FX_VERSION:-(unknown version)} was found in JAVAFX_PATH, but Java $JAVA_MAJOR_VERSION could not load it."
    echo "  The JavaFX SDK is probably too new for your Java. Use JavaFX 21 (works with Java 17+) or a newer Java."
  else
    echo "[beatoraja-config.command] Error: JavaFX not found. Use a JRE with JavaFX included (e.g., Liberica JRE Full) or place OpenJFX and set JAVAFX_PATH in beatoraja-config.command."
  fi
  read -p "Press Enter to exit..."
  exit 1
fi

if [ -n "$JAVAFX_PATH" ]; then
  echo "[beatoraja-config.command] Using JavaFX from JAVAFX_PATH: $RESOLVED_JAVAFX"
else
  echo "[beatoraja-config.command] Using JavaFX included in Java runtime"
fi

echo "[beatoraja-config.command] Starting beatoraja"

# Run beatoraja
export JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS:+$JDK_JAVA_OPTIONS }-Dfile.encoding=UTF-8"
exec java $JAVA_OPTS -cp "beatoraja.jar:ir/*" bms.player.beatoraja.MainLoader
