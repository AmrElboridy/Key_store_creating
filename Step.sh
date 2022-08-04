##############################################
######   Create Certificate Authority   ######
##############################################
#1-
mkdir openssl && cd openssl
#2-
openssl req -x509 \
            -sha256 -days 356 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/CN=demo.mlopshub.com/C=US/L=San Fransisco" \
            -keyout rootCA.key -out rootCA.crt 
##############################################
######     Self-Signed Certificate      ######
##############################################
#1. Create the Server Private Key
openssl genrsa -out server.key 2048
##########################################################################
#2. Create Certificate Signing Request Configuration
## you should know the Ethernet interface
ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)


cat > csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = California
L = San Fransisco
O = MLopsHub
OU = MlopsHub Dev
CN = demo.voda.com

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = demo.mlopshub.com
IP.1 = $ip4

EOF
##########################################################################
##3. Generate Certificate Signing Request (CSR) Using Server Private Key

openssl req -new -key server.key -out server.csr -config csr.conf
##########################################################################
##4. Create a external file
#Execute the following to create cert.conf for the SSL certificate. 
#Replace demo.mlopshub.com with your domain name or IP address.

cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = demo.mlopshub.com

EOF
##########################################################################
##5. Generate SSL certificate With self signed CA
openssl x509 -req \
    -in server.csr \
    -CA rootCA.crt -CAkey rootCA.key \
    -CAcreateserial -out server.crt \
    -days 365 \
    -sha256 -extfile cert.conf
##############################################
######             keystore             ######
##############################################
#1- 
openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12
#2-
keytool -importkeystore -srckeystore server.p12 \
        -srcstoretype PKCS12 \
        -destkeystore server.jks \
        -deststoretype JKS
