#!/bin/bash

set -e

REGION="us-east-1"
BUCKET="contabil-11111992"
BASE="https://s3.${REGION}.amazonaws.com/${BUCKET}"

# Criação do Key Pair
KEY_NAME="code-server"
KEY_FILE="${HOME}/${KEY_NAME}.pem"

if aws ec2 describe-key-pairs \
  --key-names "${KEY_NAME}" \
  --region "${REGION}" \
  >/dev/null 2>&1
then
  echo "Key Pair '${KEY_NAME}' já existe na região ${REGION}."

  if [[ -f "${KEY_FILE}" ]]; then
    chmod 400 "${KEY_FILE}"
    echo "Chave privada disponível em: ${KEY_FILE}"
  else
    echo "ATENÇÃO: o arquivo ${KEY_FILE} não existe."
    echo "A AWS não permite recuperar novamente a chave privada de um Key Pair existente."
  fi
else
  echo "Criando Key Pair '${KEY_NAME}'..."

  aws ec2 create-key-pair \
    --key-name "${KEY_NAME}" \
    --key-type rsa \
    --region "${REGION}" \
    --query 'KeyMaterial' \
    --output text > "${KEY_FILE}"

  chmod 400 "${KEY_FILE}"

  echo "Key Pair criado."
  echo "Chave privada salva em: ${KEY_FILE}"
fi

# ####################################################################
# Deploy
deploy(){
  local stack="$1"
  local template="$2"
  shift 2 

  echo "=============================================================="
  echo "Deploy: ${stack}"
  echo "Template: ${template}"
  echo "=============================================================="

  local template_file="/tmp/${stack}-template.yaml"

  aws s3 cp \
    s3://${BUCKET}/${template} \
    ${template_file}

  aws cloudformation deploy \
    --stack-name "${stack}" \
    --template-file "${template_file}" \
    --region "${REGION}" \
    --parameter-overrides "$@"
}

deploy "infraContabil" "main.yaml" \
  BucketS3="${BUCKET}.s3.${REGION}" \
  NameVPC="codeserver"

deploy "vscodeServer" "EC2/codeserver.yaml" \
  EC2Modelo="t3.medium" \
  KeyName="${KEY_NAME}" \
  NomeInstancia="codeserver2"
