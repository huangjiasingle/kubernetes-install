
function main() {

    echo -e "\\033[2J"

    read -p "Welcome to install Kubernetes, What would you like to do?
        D)   Install Docker(DO NOT USE)
        E)   Install Etcd
        K)   Install Kubernetes 
        C)   Install Calico
        UD)  Uninstall Docker(DO NOT USE)
        UE)  Uninstall Etcd
        UK)  Uninstall Kubernetes
        UC)  Uninstall Calico
        Q) Quit
     >" cmd


     if [ "$cmd" == "q" -o "$cmd" == "Q" ] ; then
         exit 0
     elif [ "$cmd" == "D" ] ; then
         source ./docker/util.sh
         docker-up
         exit 0
     elif [ "$cmd" == "UD" ] ; then
         source ./docker/util.sh
         docker-down
         exit 0
     elif [ "$cmd" == "K" ] ; then
         source ./kubernetes/util.sh
         kube-up
         exit 0
     elif [ "$cmd" == "UK" ] ; then
         source ./kubernetes/util.sh
         kube-down
         exit 0
     elif [ "$cmd" == "E" ] ; then
         source ./etcd/util.sh
         etcd-up
         exit 0
     elif [ "$cmd" == "UE" ] ; then
         source ./etcd/util.sh
         etcd-down
         exit 0
     elif [ "$cmd" == "C" ] ; then
         source ./calico/util.sh
         calico-up
         exit 0
     elif [ "$cmd" == "UC" ] ; then
         source ./calico/util.sh
         calico-down
         exit 0
     else 
        echo "Invalid input. Please enter a correct str: " && main
     fi
}

main
