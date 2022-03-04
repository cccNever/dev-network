  #!/bin/bash

function createOrg1() {
  infoln "Enrolling the CA admin"
  mkdir -p /organizations/fabric-ca/org1/admin/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/fabric-ca/org1/admin

  set -x
  fabric-ca-client enroll -u https://ca-org1-admin:ca-org1-adminpw@0.0.0.0:7053 --caname ca-org1 --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem" #注册组织，为组织生成一个可信证书文件列表
  { set +x; } 2>/dev/null
  if [ ! -d "organizations/peerOrganizations/org1.example.com/msp" ]; then
    mkdir -p organizations/peerOrganizations/org1.example.com/msp/
  fi

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7053-ca-org1.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7053-ca-org1.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7053-ca-org1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7053-ca-org1.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml"

  infoln "Registering peer1.org1.example.com"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name peer1-org1 --id.secret peerpw --id.type peer -u https://0.0.0.0:7053 --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem" #登录peer1
  { set +x; } 2>/dev/null

  infoln "Registering user1.org1.example.com"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name user1-org1 --id.secret userpw --id.type client -u https://0.0.0.0:7053 --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem" #在组织中登记user1
  { set +x; } 2>/dev/null

  infoln "Registering admin1.org1.example.com"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name admin1-org1 --id.secret adminpw --id.type admin -u https://0.0.0.0:7053 --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem" #在组织中登记admin1
  { set +x; } 2>/dev/null

  infoln "Generating the peer1.org1.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com
  set -x
  fabric-ca-client enroll -u https://peer1-org1:peerpw@0.0.0.0:7053 --caname ca-org1 -M "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp" --csr.hosts peer1.org1.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem" #为peer1生成msp
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/config.yaml" #这个注意一下
  
  ################登录tls-ca管理员账号，为org1的peer1、org2的peer1、orderorg的order1注册账号#########################
  infoln "Enrolling the TLS-CA admin"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/fabric-ca/tls-ca-node1/admin
  if [ ! -d "fabric-ca/tls-ca-node1/admin" ]; then
    mkdir -p /organizations/fabric-ca/tls-ca-node1/admin/
    set -x
    fabric-ca-client enroll -u https://tls-ca1-admin:tls-ca1-adminpw@0.0.0.0:7052 --caname tls-ca-node1 --tls.certfiles "${PWD}/organizations/fabric-ca/tls-ca-node1/ca-cert.pem" #登录TLS-CA admin
    { set +x; } 2>/dev/null
  fi
  
  infoln "Registering peer1.org1.example.com"
  set -x
  fabric-ca-client register --caname tls-ca-node1 --id.name peer1-org1 --id.secret peerpw --id.type peer -u https://0.0.0.0:7052 --tls.certfiles "${PWD}/organizations/fabric-ca/tls-ca-node1/ca-cert.pem" #在组织中登记user1
  { set +x; } 2>/dev/null



  #########################生成tls-ca 加密材料#################################
  infoln "Generating the peer1.org1.example.com tls certificates"
  
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/

  set -x
  fabric-ca-client enroll -u https://peer1-org1:peerpw@0.0.0.0:7052 --caname tls-ca-node1 -M "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls-msp" --enrollment.profile tls --csr.hosts peer1.org1.example.com  --tls.certfiles "${PWD}/organizations/fabric-ca/tls-ca-node1/ca-cert.pem" 
  { set +x; } 2>/dev/null

  ##重命名私钥，之后要用
  mv "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls-msp/keystore/"*_sk "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls-msp/keystore/key.pem"

  infoln "Generating the user1.org1.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.example.com/users/user1.org1.example.com
  set -x
  fabric-ca-client enroll -u https://user1-org1:userpw@0.0.0.0:7053 --caname ca-org1 -M "${PWD}/organizations/peerOrganizations/org1.example.com/users/user1.org1.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org1.example.com/users/user1.org1.example.com/msp/config.yaml"

  infoln "Generating the org admin1.org1.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.example.com/users/admin1.org1.example.com
  set -x
  fabric-ca-client enroll -u https://admin1-org1:adminpw@0.0.0.0:7053 --caname ca-org1 -M "${PWD}/organizations/peerOrganizations/org1.example.com/users/admin1.org1.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org1.example.com/users/admin1.org1.example.com/msp/config.yaml"

  ## 将组织管理员的证书移到peer和user的admincerts中
  mkdir -p "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/admincerts"
  cp "${PWD}/organizations/peerOrganizations/org1.example.com/users/admin1.org1.example.com/msp/signcerts/cert.pem" "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/admincerts/org1-admin-cert.pem"
  mkdir -p "${PWD}/organizations/peerOrganizations/org1.example.com/users/user1.org1.example.com/msp/admincerts"
  cp "${PWD}/organizations/peerOrganizations/org1.example.com/users/admin1.org1.example.com/msp/signcerts/cert.pem" "${PWD}/organizations/peerOrganizations/org1.example.com/users/user1.org1.example.com/msp/admincerts/org1-admin-cert.pem"

  ##构建组织的通道msp
  #mkdir -p "${PWD}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts"
  cp -r "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls-msp/tlscacerts" "${PWD}/organizations/peerOrganizations/org1.example.com/msp/"

  #mkdir -p "${PWD}/organizations/peerOrganizations/org1.example.com/msp/cacerts"
  cp -r "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/cacerts" "${PWD}/organizations/peerOrganizations/org1.example.com/msp/"

  #mkdir -p "${PWD}/organizations/peerOrganizations/org1.example.com/msp/admincerts"
  cp -r "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp/admincerts" "${PWD}/organizations/peerOrganizations/org1.example.com/msp/"

  
}

function createOrg2() {
  infoln "Enrolling the CA admin"
  mkdir -p /organizations/fabric-ca/org2/admin/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/fabric-ca/org2/admin

  set -x
  fabric-ca-client enroll -u https://ca-org2-admin:ca-org2-adminpw@0.0.0.0:7054 --caname ca-org2 --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem" #注册组织，为组织生成一个可信证书文件列表
  { set +x; } 2>/dev/null
  if [ ! -d "organizations/peerOrganizations/org2.example.com/msp" ]; then
    mkdir -p organizations/peerOrganizations/org2.example.com/msp/
  fi
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054-ca-org2.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054-ca-org2.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054-ca-org2.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054-ca-org2.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml"

  infoln "Registering peer1.org2.example.com"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name peer1-org2 --id.secret peerpw --id.type peer -u https://0.0.0.0:7054 --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem" #登录peer1
  { set +x; } 2>/dev/null

  infoln "Registering user1.org2.example.com"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name user1-org2 --id.secret userpw --id.type client -u https://0.0.0.0:7054 --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem" #在组织中登记user1
  { set +x; } 2>/dev/null

  infoln "Registering admin1.org2.example.com"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name admin1-org2 --id.secret adminpw --id.type admin -u https://0.0.0.0:7054 --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem" #在组织中登记admin1
  { set +x; } 2>/dev/null

  infoln "Generating the peer1.org2.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com
  set -x
  fabric-ca-client enroll -u https://peer1-org2:peerpw@0.0.0.0:7054 --caname ca-org2 -M "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/msp" --csr.hosts peer1.org2.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem" #为peer1生成msp
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/msp/config.yaml" #这个注意一下
  
  ################登录tls-ca管理员账号，为org1的peer1、org2的peer1、orderorg的order1注册账号#########################
  infoln "Enrolling the TLS-CA admin"

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/fabric-ca/tls-ca-node1/admin

  if [ ! -d "fabric-ca/tls-ca-node1/admin" ]; then
    mkdir -p /organizations/fabric-ca/tls-ca-node1/admin
    set -x
    fabric-ca-client enroll -u https://tls-ca1-admin:tls-ca1-adminpw@0.0.0.0:7052 --caname tls-ca-node1 --tls.certfiles "${PWD}/organizations/fabric-ca/tls-ca-node1/ca-cert.pem" #登录TLS-CA admin
    { set +x; } 2>/dev/null
  fi

  infoln "Registering peer1.org2.example.com"
  set -x
  fabric-ca-client register --caname tls-ca-node1 --id.name peer1-org2 --id.secret peerpw --id.type peer -u https://0.0.0.0:7052 --tls.certfiles "${PWD}/organizations/fabric-ca/tls-ca-node1/ca-cert.pem" #在组织中登记admin1
  { set +x; } 2>/dev/null


  #########################生成tls-ca 加密材料#################################
  infoln "Generating the peer1.org2.example.com tls certificates"
  
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/

  set -x
  fabric-ca-client enroll -u https://peer1-org2:peerpw@0.0.0.0:7052 --caname tls-ca-node1 -M "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls-msp" --enrollment.profile tls --csr.hosts peer1.org2.example.com  --tls.certfiles "${PWD}/organizations/fabric-ca/tls-ca-node1/ca-cert.pem" 
  { set +x; } 2>/dev/null

  ##重命名私钥，之后要用
  mv "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls-msp/keystore/"*_sk "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls-msp/keystore/key.pem"

  infoln "Generating the user1.org2.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org2.example.com/users/user1.org2.example.com
  set -x
  fabric-ca-client enroll -u https://user1-org2:userpw@0.0.0.0:7054 --caname ca-org2 -M "${PWD}/organizations/peerOrganizations/org2.example.com/users/user1.org2.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org2.example.com/users/user1.org2.example.com/msp/config.yaml"

  infoln "Generating the admin1.org2.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org2.example.com/users/admin1.org2.example.com
  set -x
  fabric-ca-client enroll -u https://admin1-org2:adminpw@0.0.0.0:7054 --caname ca-org2 -M "${PWD}/organizations/peerOrganizations/org2.example.com/users/admin1.org2.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org2.example.com/users/admin1.org2.example.com/msp/config.yaml"

  ## 将组织管理员的证书移到peer和user的admincerts中
  mkdir -p "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/msp/admincerts"
  cp "${PWD}/organizations/peerOrganizations/org2.example.com/users/admin1.org2.example.com/msp/signcerts/cert.pem" "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/msp/admincerts/org2-admin-cert.pem"
  mkdir -p "${PWD}/organizations/peerOrganizations/org2.example.com/users/user1.org2.example.com/msp/admincerts"
  cp "${PWD}/organizations/peerOrganizations/org2.example.com/users/admin1.org2.example.com/msp/signcerts/cert.pem" "${PWD}/organizations/peerOrganizations/org2.example.com/users/user1.org2.example.com/msp/admincerts/org2-admin-cert.pem"

  ##构建组织的通道msp
  #mkdir -p "${PWD}/organizations/peerOrganizations/org2.example.com/msp/tlscacerts"
  cp -r "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls-msp/tlscacerts" "${PWD}/organizations/peerOrganizations/org2.example.com/msp/"

  #mkdir -p "${PWD}/organizations/peerOrganizations/org2.example.com/msp/cacerts"
  cp -r "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/msp/cacerts" "${PWD}/organizations/peerOrganizations/org2.example.com/msp/"

  #mkdir -p "${PWD}/organizations/peerOrganizations/org2.example.com/msp/admincerts"
  cp -r "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/msp/admincerts" "${PWD}/organizations/peerOrganizations/org2.example.com/msp/"

}

function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p /organizations/fabric-ca/orderOrg1/admin

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/fabric-ca/ordererOrg1/admin

  set -x
  fabric-ca-client enroll -u https://ca-ordererorg1-admin:ca-ordererorg1-adminpw@0.0.0.0:7055 --caname ca-ordererOrg1 --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg1/ca-cert.pem" #注册组织，为组织生成一个可信证书文件列表
  { set +x; } 2>/dev/null
  if [ ! -d "organizations/ordererOrganizations/ordererOrg1.example.com/msp" ]; then
    mkdir -p organizations/ordererOrganizations/ordererOrg1.example.com/msp
  fi
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055-ca-ordererOrg1.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055-ca-ordererOrg1.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055-ca-ordererOrg1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7055-ca-ordererOrg1.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/config.yaml"

  infoln "Registering orderer1.ordererOrg1.example.com"
  set -x
  fabric-ca-client register --caname ca-ordererOrg1 --id.name orderer1-ordererorg1 --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7055 --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg1/ca-cert.pem" #登录peer1
  { set +x; } 2>/dev/null

  infoln "Registering admin1.ordererOrg1.example.com"
  set -x
  fabric-ca-client register --caname ca-ordererOrg1 --id.name admin1-ordererorg1 --id.secret adminpw --id.type admin -u https://0.0.0.0:7055 --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg1/ca-cert.pem" #在组织中登记admin1
  { set +x; } 2>/dev/null

  infoln "Generating the orderer1.ordererOrg1.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com
  set -x
  fabric-ca-client enroll -u https://orderer1-ordererorg1:ordererpw@0.0.0.0:7055 --caname ca-ordererOrg1 -M "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/msp" --csr.hosts orderer1.ordererOrg1.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg1/ca-cert.pem" #为peer1生成msp
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/msp/config.yaml" #这个注意一下
  
  ################登录tls-ca管理员账号，为org1的peer1、org2的peer1、ordererorg的orderer1注册账号#########################
  infoln "Enrolling the TLS-CA admin"

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/fabric-ca/tls-ca-node1/admin

  if [ ! -d "fabric-ca/tls-ca-node1/admin" ]; then
    mkdir -p /organizations/fabric-ca/tls-ca-node1/admin/
    set -x
    fabric-ca-client enroll -u https://tls-ca1-admin:tls-ca1-adminpw@0.0.0.0:7052 --caname tls-ca-node1 --tls.certfiles "${PWD}/organizations/fabric-ca/tls-ca-node1/ca-cert.pem" #登录TLS-CA admin
    { set +x; } 2>/dev/null
  fi

  infoln "Registering orderer1.ordererOrg1.example.com"
  set -x
  fabric-ca-client register --caname tls-ca-node1 --id.name orderer1-ordererorg1 --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7052 --tls.certfiles "${PWD}/organizations/fabric-ca/tls-ca-node1/ca-cert.pem" #在组织中登记admin1
  { set +x; } 2>/dev/null


  #########################生成tls-ca 加密材料#################################
  infoln "Generating the orderer1.ordererOrg1.example.com tls certificates"
  
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/

  set -x
  fabric-ca-client enroll -u https://orderer1-ordererorg1:ordererpw@0.0.0.0:7052 --caname tls-ca-node1 -M "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/tls-msp" --enrollment.profile tls --csr.hosts orderer1.ordererOrg1.example.com  --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg1/ca-cert.pem" 
  { set +x; } 2>/dev/null

  ##重命名私钥，之后要用
  mv "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/tls-msp/keystore/"*_sk "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/tls-msp/keystore/key.pem"

  infoln "Generating the admin1.ordererOrg1.example.com msp"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/users/admin1.ordererOrg1.example.com
  set -x
  fabric-ca-client enroll -u https://admin1-ordererorg1:adminpw@0.0.0.0:7055 --caname ca-ordererOrg1 -M "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/users/admin1.ordererOrg1.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg1/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/users/admin1.ordererOrg1.example.com/msp/config.yaml"

  ## 将组织管理员的证书移到peer和user的admincerts中
  mkdir -p "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/msp/admincerts"
  cp "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/users/admin1.ordererOrg1.example.com/msp/signcerts/cert.pem" "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/msp/admincerts/ordererOrg1-admin-cert.pem"
  ##构建组织的通道msp
 # mkdir -p "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/tlscacerts"
  cp -r "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/tls-msp/tlscacerts" "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/"

  #mkdir -p "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/cacerts"
  cp -r "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/msp/cacerts" "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/"

  #mkdir -p "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/admincerts"
  cp -r "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer1.ordererOrg1.example.com/msp/admincerts" "${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/msp/"
}
