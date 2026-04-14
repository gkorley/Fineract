FROM fineract-custom:latest

USER root

# Install fonts and fontconfig for Pentaho report rendering (PDF/HTML output)
# ttf-dejavu: fallback unicode font; font-noto: broad coverage; ttf-liberation: Arial/Times/Courier metric-compatible substitutes
RUN apk add --no-cache fontconfig ttf-dejavu ttf-liberation font-noto && fc-cache -f

# Copy Pentaho-specific JARs (plugin + engine + polyglot dependencies only)
COPY libs/ /app/libs/

# Copy Pentaho report templates and resource bundle .properties files
COPY pentahoReports/ /tmp/.fineract/pentahoReports/

# Set report path and locale environment variables
ENV FINERACT_PENTAHO_REPORTS_PATH=/tmp/.fineract/pentahoReports/
ENV FINERACT_PENTAHO_REPORTS_LOCALE=en

# Append the new Pentaho JARs to the Jib classpath file.
# Jib uses an explicit classpath file; JARs added by COPY aren't included unless listed.
RUN cd /app/libs && \
    for jar in pentaho-plugin-*.jar classic-*.jar wizard-core-*.jar \
      libbase-*.jar libdocbundle-*.jar libfonts-*.jar libformat-*.jar \
      libformula-*.jar libloader-*.jar librepository-*.jar libserializer-*.jar \
      libxml-*.jar commons-vfs2-*.jar groovy-*.jar openpdf-2*.jar polyglot-*.jar js-language-*.jar truffle-*.jar \
      collections-2*.jar nativebridge-*.jar nativeimage-*.jar jniutils-*.jar \
      regex-2*.jar word-*.jar; do \
      if [ -f "$jar" ]; then \
        printf ":/app/libs/%s" "$jar" >> /app/jib-classpath-file; \
      fi; \
    done && \
    chown nobody:nogroup /app/jib-classpath-file && \
    chown -R nobody:nogroup /tmp/.fineract

USER nobody
