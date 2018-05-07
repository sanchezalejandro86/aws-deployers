#!/bin/bash -e

case "$1" in
  gammat)
	;;
  gammatraders)
	;;
  *)
        echo "Usage: $0 {gammat|gammatraders} {dev|test|prod}"
        exit 1
esac

case "$2" in
  dev)
	REGION=us-east-1
	;;
  test)
	REGION=us-east-1
	;;
  prod)
	REGION=sa-east-1
	;;
  *)
        echo "Usage: $0 {gammat|gammatraders} {dev|test|prod}"
        exit 1
esac

PROJECT=$1
ENVIRONMENT=$2

BUCKET=bucket=$ENVIRONMENT.$PROJECT.com
BUCKET_CONFIG=key=terraform/aws/terraform.tfstate
REGION_CONFIG=region=$REGION

if [ -z $PROFILE ]
then	
	PROFILE=$ENVIRONMENT.$PROJECT.com
fi 

AWS_PROFILE=profile=$PROFILE

rm -R .terraform || true
rm terraform.tfvars || true

eval 'echo -e clustername=\"$ENVIRONMENT-$PROJECT-com\" \\nregion=\"$REGION\" \\nkeypair=\"ec2-$ENVIRONMENT-$PROJECT-com\" \\nprofile=\"$PROFILE\"' > terraform.tfvars

echo "Actualizando ambiente $1 $2"

terraform init -backend-config=$BUCKET -backend-config=$BUCKET_CONFIG -backend-config=$REGION_CONFIG -backend-config=$AWS_PROFILE

terraform plan
terraform apply -auto-approve 

exit 0
