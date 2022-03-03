function createOrg3() {
  infoln "Enrolling the CA admin"
  mkdir -p ../organizations/fabric-ca/org3/admin/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/fabric-ca/org3/admin

  set -x
  fabric-ca-client enroll -u https://ca-org3-admin:ca-org3-adminpw@0.0.0.0:7056 --caname ca-org3 --tls.certfiles "${PWD}/../organizations/fabric-ca/org3/ca-cert.pem"#注册组织，为组织生成一个可信证书文件列表
  { set +x; } 2>/dev/null
  if [ ! -d "../organizations/peerOrganizations/org3.example.com/msp/" ]; then
    mkdir -p ../organizations/peerOrganizations/org3.example.com/msp/
  fi
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7056-ca-org3.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7056-ca-org3.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7056-ca-org3.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7056-ca-org3.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/config.yaml"

  infoln "Registering peer1.org3.example.com"
  set -x
  fabric-ca-client register --caname ca-org3 --id.name peer1-org3 --id.secret peerpw --id.type peer -u https://0.0.0.0:7056 --tls.certfiles "${PWD}/../organizations/fabric-ca/org3/ca-cert.pem" #登录peer1
  { set +x; } 2>/dev/null

  infoln "Registering user1.org3.example.com"
  set -x
  fabric-ca-client register --caname ca-org3 --id.name user1-org3 --id.secret userpw --id.type client -u https://0.0.0.0:7056 --tls.certfiles "${PWD}/../organizations/fabric-ca/org3/ca-cert.pem" #在组织中登记user1
  { set +x; } 2>/dev/null

  infoln "Registering admin1.org3.example.com"
  set -x
  fabric-ca-client register --caname ca-org3 --id.name admin1-org3 --id.secret adminpw --id.type admin -u https://0.0.0.0:7056 --tls.certfiles "${PWD}/../organizations/fabric-ca/org3/ca-cert.pem" #在组织中登记admin1
  { set +x; } 2>/dev/null

  infoln "Generating the peer1.org3.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com
  set -x
  fabric-ca-client enroll -u https://peer1-org3:peerpw@0.0.0.0:7056 --caname ca-org3 -M "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/msp" --csr.hosts peer1.org3.example.com --tls.certfiles "${PWD}/../organizations/fabric-ca/org3/ca-cert.pem" #为peer1生成msp
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/msp/config.yaml" #这个注意一下
  
  ################登录tls-ca管理员账号，为org3的peer1、org2的peer1、orderorg的order1注册账号#########################
  infoln "Enrolling the TLS-CA admin"
  export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/fabric-ca/tls-ca-node1/admin
  if [ ! -d "fabric-ca/tls-ca-node1/admin/" ]; then
    mkdir -p ../organizations/fabric-ca/tls-ca-node1/admin/
    set -x
    fabric-ca-client enroll -u https://tls-ca1-admin:tls-ca1-adminpw@0.0.0.0:7052 --caname tls-ca-node1 --tls.certfiles "${PWD}/../organizations/fabric-ca/tls-ca-node1/ca-cert.pem" #登录TLS-CA admin
    { set +x; } 2>/dev/null
  fi
  
  infoln "Registering peer1.org3.example.com"
  set -x
  fabric-ca-client register --caname tls-ca-node1 --id.name peer1-org3 --id.secret peerpw --id.type peer -u https://0.0.0.0:7052 --tls.certfiles "${PWD}/../organizations/fabric-ca/tls-ca-node1/ca-cert.pem" #在组织中登记user1
  { set +x; } 2>/dev/null



  #########################生成tls-ca 加密材料#################################
  infoln "Generating the peer1.org3.example.com tls certificates"
  
  export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/

  set -x
  fabric-ca-client enroll -u https://peer1-org3:peerpw@0.0.0.0:7052 --caname tls-ca-node1 -M "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls-msp" --enrollment.profile tls --csr.hosts peer1.org3.example.com  --tls.certfiles "${PWD}/../organizations/fabric-ca/tls-ca-node1/ca-cert.pem" 
  { set +x; } 2>/dev/null

  ##重命名私钥，之后要用
  mv "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls-msp/keystore/*_sk" "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls-msp/keystore/key.pem"

  infoln "Generating the user1.org3.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/org3.example.com/users/user1.org3.example.com
  set -x
  fabric-ca-client enroll -u https://user1-org3:userpw@0.0.0.0:7056 --caname ca-org3 -M "${PWD}/../organizations/peerOrganizations/org3.example.com/users/user1.org3.example.com/msp" --tls.certfiles "${PWD}/../organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/org3.example.com/users/user1.org3.example.com/msp/config.yaml"

  infoln "Generating the org admin1.org3.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/org3.example.com/users/admin1.org3.example.com
  set -x
  fabric-ca-client enroll -u https://admin1-org3:adminpw@0.0.0.0:7056 --caname ca-org3 -M "${PWD}/../organizations/peerOrganizations/org3.example.com/users/admin1.org3.example.com/msp" --tls.certfiles "${PWD}/../organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/org3.example.com/users/admin1.org3.example.com/msp/config.yaml"

  ## 将组织管理员的证书移到peer和user的admincerts中
  mkdir -p "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/msp/admincerts"
  cp "${PWD}/../organizations/peerOrganizations/org3.example.com/users/admin1.org3.example.com/msp/signcerts/cert.pem" "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/msp/admincerts/org3-admin-cert.pem"
  mkdir -p "${PWD}/../organizations/peerOrganizations/org3.example.com/users/user1.org3.example.com/msp/admincerts"
  cp "${PWD}/../organizations/peerOrganizations/org3.example.com/users/admin1.org3.example.com/msp/signcerts/cert.pem" "${PWD}/../organizations/peerOrganizations/org3.example.com/users/user1.org3.example.com/msp/admincerts/org3-admin-cert.pem"

  ##构建组织的通道msp
  mkdir -p "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/tlscacerts"
  cp "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls-msp/tlscacerts/*" "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/tlscacerts/"

  mkdir -p "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/cacerts"
  cp "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/msp/cacerts/*" "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/cacerts/"

  mkdir -p "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/admincerts"
  cp "${PWD}/../organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/msp/admincerts/*" "${PWD}/../organizations/peerOrganizations/org3.example.com/msp/admincerts/"

  
}