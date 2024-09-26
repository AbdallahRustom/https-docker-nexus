#!/usr/bin/env bash

cp -r /mnt/ssl/ /opt/sonatype/nexus/nexus-3.30.0-01/etc/
cp /mnt/nexus-default.properties /opt/sonatype/nexus/nexus-3.30.0-01/etc/nexus-default.properties
cd /opt/sonatype/nexus/nexus-3.30.0-01/etc/ssl
set -x
set -eo pipefail

if [ ! -f "$NEXUS_SSL/keystore.jks" ]; then

  if [ ! -f $NEXUS_SSL/$PUBLIC_CERT ] && [ ! -f $NEXUS_SSL/$PRIVATE_KEY ]; then
    openssl req -nodes -new -x509 -keyout $PRIVATE_KEY -out $PUBLIC_CERT -subj "${PUBLIC_CERT_SUBJ}"
  fi
  if [ ! -f $NEXUS_SSL/jetty.key ]; then
    openssl pkcs12 -export -in $PUBLIC_CERT -inkey $PRIVATE_KEY -out $NEXUS_SSL/keystore.p12 -name jetty -passout pass:$PRIVATE_KEY_PASSWORD
  fi   
  $JAVA_HOME/bin/keytool -importkeystore -noprompt -deststorepass $PRIVATE_KEY_PASSWORD -destkeypass $PRIVATE_KEY_PASSWORD -destkeystore $NEXUS_SSL/keystore.jks -srckeystore $NEXUS_SSL/keystore.p12 -srcstoretype PKCS12 -alias jetty -srcstorepass $PRIVATE_KEY_PASSWORD
  sed -r '/<Set name="(KeyStore|KeyManager|TrustStore)Password">/ s:>.*$:>'$PRIVATE_KEY_PASSWORD'</Set>:' -i $NEXUS_HOME/etc/jetty/jetty-https.xml
fi
mkdir -p "$NEXUS_DATA"
chown -R nexus:nexus "$NEXUS_DATA"

JETTY_HTTPS_FILE="/opt/sonatype/nexus/nexus-3.30.0-01/etc/jetty/jetty-https.xml"
TEMP_FILE=$(mktemp)

while IFS= read -r line; do
  if [[ "$line" == *"<Set name=\"KeyStorePath\">"* ]]; then
    INDENTATION=$(echo "$line" | sed 's/[^ ]//g')
    echo "${INDENTATION}<Set name=\"KeyStorePath\">/opt/sonatype/nexus/nexus-3.30.0-01/etc/ssl/keystore.jks</Set>" >> "$TEMP_FILE"
    echo "${INDENTATION}<Set name=\"certAlias\">jetty</Set>" >> "$TEMP_FILE"
  elif [[ "$line" == *"<Set name=\"TrustStorePath\">"* ]]; then
    INDENTATION=$(echo "$line" | sed 's/[^ ]//g')
    echo "${INDENTATION}<Set name=\"TrustStorePath\">/opt/sonatype/nexus/nexus-3.30.0-01/etc/ssl/keystore.jks</Set>" >> "$TEMP_FILE"
  else
    echo "$line" >> "$TEMP_FILE"
  fi
done < "$JETTY_HTTPS_FILE"

mv "$TEMP_FILE" "$JETTY_HTTPS_FILE"

echo "certAlias line added successfully."



exec /opt/sonatype/nexus/nexus-3.30.0-01/bin/nexus run

exec "$@"
