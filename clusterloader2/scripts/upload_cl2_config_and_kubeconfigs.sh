set -eu

USAGE="./scripts/upload_cl2_config_and_kubeconfigs.sh <s3-bucket> <config-dir-path> <config-filename> [<kubeconfig-path>...]"

# Currently we expect atleast 2 clusters, so 2 kubeconfigs + 3 other args = atleast 5 args total.
if [ "$#" -lt 5 ]; then
    echo "USAGE:"
    echo $USAGE
    exit 1
fi

BUCKET=$1
CD_PATH=$2
C_NAME=$3

config_prefix="cl2_config/$(date +"%Y-%m-%d-%H%M")"
echo "Uploading config to: s3://$BUCKET/$config_prefix/"
aws s3 cp --recursive $CD_PATH s3://$BUCKET/$config_prefix/

for kubeconfig in "${@:4}"
do
    aws s3 cp $kubeconfig s3://$BUCKET/$config_prefix/
done

echo "\n Set 'configS3Prefix' to $config_prefix in lib/app.ts in ASGInstanceRefreshHelperCDK"
