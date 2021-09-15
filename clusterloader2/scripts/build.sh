set -eu

USAGE="./scripts/build.sh <ecr-url>"

if [ "$#" -ne 1 ]; then
    echo "USAGE:"
    echo $USAGE
    exit 1
fi

ECR_URL=$1

echo "building clusterloader binary..."
mkdir -p bin
GOOS=linux GOARCH=amd64 GOPROXY=direct go build -o bin/clusterloader_linux ./cmd/
echo "building docker image..."
docker build -t $ECR_URL:latest -f Dockerfile .
echo "logging into ecr..."
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URL
echo "pushing to ecr..."
docker push $ECR_URL:latest
