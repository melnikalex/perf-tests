# NOTE:
# * <config-url> <config-name> <kubeconfig-name> argumetns are required to run startup.sh
# * to build run: docker build -t $(IMAGE):$(TAG) -f Dockerfile

FROM amazon/aws-cli

WORKDIR clusterloader_dir

COPY bin/clusterloader_linux clusterloader

COPY scripts/startup.sh startup.sh

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin
RUN yum -y install jq

ENTRYPOINT ["./startup.sh"]
