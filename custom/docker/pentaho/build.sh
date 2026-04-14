#!/bin/bash
# Build fineract-custom with Pentaho Reporting Plugin
#
# Prerequisites:
#   1. Build the base fineract-custom image first:
#      cd /path/to/Fineract && ./gradlew :custom:docker:jibDockerBuild
#   2. Build the mifos-reporting-plugin:
#      cd /path/to/mifos-reporting-plugin && ./mvnw -Dmaven.test.skip=true clean package
#      ./mvnw dependency:copy-dependencies -DoutputDirectory=target/libs -DincludeScope=runtime -Dmaven.test.skip=true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="${MIFOS_PLUGIN_DIR:-$(cd "$SCRIPT_DIR/../../../../mifos-reporting-plugin" && pwd)}"
REPORTS_DIR="${PLUGIN_DIR}/pentahoReports/Postgresql/Legacy"

echo "Plugin dir: $PLUGIN_DIR"
echo "Reports dir: $REPORTS_DIR"

# Prepare build context
BUILD_CONTEXT="$SCRIPT_DIR/build-context"
rm -rf "$BUILD_CONTEXT"
mkdir -p "$BUILD_CONTEXT/libs" "$BUILD_CONTEXT/pentahoReports"

# Download Pentaho transitive deps that Maven can't resolve (corrupt parent POM at Hitachi repo).
EXTRA_JARS=(
    "https://repo1.maven.org/maven2/org/apache/commons/commons-vfs2/2.9.0/commons-vfs2-2.9.0.jar"
    "https://repo1.maven.org/maven2/org/apache/groovy/groovy/4.0.24/groovy-4.0.24.jar"
    "https://repo1.maven.org/maven2/org/apache/groovy/groovy-jsr223/4.0.24/groovy-jsr223-4.0.24.jar"
    "https://repo1.maven.org/maven2/org/apache/groovy/groovy-sql/4.0.24/groovy-sql-4.0.24.jar"
    "https://repo1.maven.org/maven2/com/github/librepdf/openpdf/2.0.3/openpdf-2.0.3.jar"
)
LIBS_DIR="$PLUGIN_DIR/target/libs"
for url in "${EXTRA_JARS[@]}"; do
    name=$(basename "$url")
    if [ ! -f "$LIBS_DIR/$name" ]; then
        echo "Downloading $name ..."
        curl -sL "$url" -o "$LIBS_DIR/$name"
    fi
done

# Copy ONLY the pentaho-plugin JAR and Pentaho-specific dependencies.
# Do NOT copy all transitive deps — they conflict with JARs in the base image.
PENTAHO_PATTERNS=(
    "pentaho-plugin-*.jar"
    "classic-core-*.jar"
    "classic-extensions-*.jar"
    "classic-extensions-scripting-*.jar"
    "wizard-core-*.jar"
    "libbase-*.jar"
    "libdocbundle-*.jar"
    "libfonts-*.jar"
    "libformat-*.jar"
    "libformula-*.jar"
    "libloader-*.jar"
    "librepository-*.jar"
    "libserializer-*.jar"
    "libxml-*.jar"
    # Pentaho transitive dependencies not resolved by Maven (corrupt parent POM)
    "commons-vfs2-*.jar"
    "groovy-*.jar"
    "openpdf-2*.jar"
    # GraalVM/Polyglot JARs for Pentaho scripting support
    "polyglot-*.jar"
    "js-language-*.jar"
    "truffle-api-*.jar"
    "truffle-compiler-*.jar"
    "truffle-enterprise-*.jar"
    "truffle-runtime-*.jar"
    "collections-*.jar"
    "nativebridge-*.jar"
    "nativeimage-*.jar"
    "jniutils-*.jar"
    "regex-*.jar"
    "word-*.jar"
)

for pattern in "${PENTAHO_PATTERNS[@]}"; do
    for f in "$PLUGIN_DIR/target/libs/"$pattern; do
        [ -f "$f" ] && cp "$f" "$BUILD_CONTEXT/libs/"
    done
done

# Copy PostgreSQL report templates AND resource bundle .properties files
cp "$REPORTS_DIR/"*.prpt "$BUILD_CONTEXT/pentahoReports/" 2>/dev/null
cp "$REPORTS_DIR/"*.properties "$BUILD_CONTEXT/pentahoReports/" 2>/dev/null
cp "$REPORTS_DIR/"*.PROPERTIES "$BUILD_CONTEXT/pentahoReports/" 2>/dev/null

echo "JARs: $(ls "$BUILD_CONTEXT/libs/"*.jar 2>/dev/null | wc -l)"
echo "Reports: $(ls "$BUILD_CONTEXT/pentahoReports/"*.prpt 2>/dev/null | wc -l)"
echo "Bundles: $(ls "$BUILD_CONTEXT/pentahoReports/"*.properties "$BUILD_CONTEXT/pentahoReports/"*.PROPERTIES 2>/dev/null | wc -l)"

# Build the extended image
cp "$SCRIPT_DIR/Dockerfile" "$BUILD_CONTEXT/"
docker build -t fineract-pentaho:latest "$BUILD_CONTEXT"

# Cleanup
rm -rf "$BUILD_CONTEXT"

echo "Done. Image: fineract-pentaho:latest"
