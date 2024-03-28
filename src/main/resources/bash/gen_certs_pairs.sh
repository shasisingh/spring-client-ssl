#!/bin/bash

rm -rf certs/

mkdir "certs"

function gen_extfile()
{
    domain1=$1
    domain2=$2
    cat << EOF
        authorityKeyIdentifier=keyid,issuer\n
    basicConstraints=CA:FALSE\n
        keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment\n
    subjectAltName = @alt_names\n
    [alt_names]\n
        DNS.1 = $domain1
        DNS.2 = $domain2
EOF
}

PASSWORD=test123

extFile=$(gen_extfile "localhost" "127.0.0.1")

echo "generating key of RootCa"
openssl genrsa -des3 -out certs/RootCa.key -passout pass:$PASSWORD 2048

echo "generating RootCa's certificate (.pem)"
openssl req -x509 -new -nodes -key certs/RootCa.key -sha256 -days 30000 -out certs/RootCa.pem -config default-ca.cnf -passout pass:$PASSWORD -passin pass:$PASSWORD

echo "converting RootCa.pem to pkcs12"
openssl pkcs12 -export -out certs/RootCa.p12 -in certs/RootCa.pem -inkey certs/RootCa.key -passout pass:$PASSWORD -passin pass:$PASSWORD

echo "preparing an empty keystore"
keytool -genkey -keyalg RSA -alias empty -keystore certs/my_trust_store.jks -dname "cn=ACDC, ou=Payments, o=Rabobank, c=NL" -ext SAN=dns:localhost,IP:127.0.0.1 -storepass $PASSWORD -keypass $PASSWORD -validity 30000 -noprompt

echo "preparing an empty making"
keytool -delete -alias empty -keystore certs/my_trust_store.jks -storepass $PASSWORD -keypass $PASSWORD -noprompt

echo "creating the truststore (this command needs an existing jks)"
keytool -import -v -trustcacerts -alias payments.CA.com -file certs/RootCa.pem -keystore certs/my_trust_store.jks -storepass $PASSWORD -keypass $PASSWORD -noprompt

echo "generating key(client) 1"
openssl genrsa -out certs/client1.key 2048

echo "generating key(server) 2"
openssl genrsa -out certs/server.key 2048

echo "generating csr(client1) 1"
openssl req -new -key certs/client1.key -out certs/client1.csr -config default-ssl.cnf

echo "generating csr(server) 2"
openssl req -new -key certs/server.key -out certs/server.csr -config default-server-ssl.cnf

echo "generating certificate (client) 1 signed by ca key"
openssl x509 -req -passin pass:$PASSWORD -days 1800 -in certs/client1.csr -CA certs/RootCa.pem -CAkey certs/RootCa.key -CAcreateserial -out certs/client1.crt -sha256 -extfile <(printf "$extFile")

echo "generating certificate (server)2 signed by ca key"
openssl x509 -req -passin pass:$PASSWORD -days 1800 -in certs/server.csr -CA certs/RootCa.pem -CAkey certs/RootCa.key -CAcreateserial -out certs/server.crt -sha256 -extfile <(printf "$extFile")

echo "generating key-store 1 containing certificate 1 signed by ca key"
openssl pkcs12 -export -in certs/client1.crt -inkey certs/client1.key -name "client1" -out certs/client1.p12 -passin pass:$PASSWORD -passout pass:$PASSWORD

echo "generating key-store 2 containing certificate 2 signed by ca key"
openssl pkcs12 -export -in certs/server.crt -inkey certs/server.key -name "server" -out certs/server.p12 -passin pass:$PASSWORD -passout pass:$PASSWORD
