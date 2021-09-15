set -eu

USAGE="./scripts/add_roles_to_cluster.sh <kubeconfig-path> [<role>...]"

if [ "$#" -lt 2 ]; then
    echo "USAGE:"
    echo $USAGE
    exit 1
fi

KUBECONFIG_PATH=$1
echo "Using cluster $KUBECONFIG_PATH..."

for role in "${@:2}"
do
    kubectl --kubeconfig $KUBECONFIG_PATH get cm -n kube-system aws-auth -oyaml > /tmp/aws-auth.yaml
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    if cat /tmp/aws-auth.yaml | grep $role > /dev/null; then
        echo "Role already exists in aws-auth configmap"
    else
        echo "Applying $role to cluster $KUBECONFIG_PATH..."
        line=$(grep -n 'mapRoles: |' /tmp/aws-auth.yaml  | cut -d ":" -f 1)
        { head -n $(($line)) /tmp/aws-auth.yaml; cat $SCRIPT_DIR/auth-injection.yaml | sed "s|ROLE_ARN|$role|"; tail -n +$(($line+1)) /tmp/aws-auth.yaml; } > /tmp/new-aws-auth.yaml
        kubectl --kubeconfig $KUBECONFIG_PATH apply -f /tmp/new-aws-auth.yaml
    fi
done

