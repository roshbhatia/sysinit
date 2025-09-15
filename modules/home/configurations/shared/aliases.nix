{
  kubectl = {
    # Basic kubectl commands
    k = "kubectl";
    ksys = "kubectl --namespace=kube-system";
    ka = "kubectl apply --recursive -f";
    ksysa = "kubectl --namespace=kube-system apply --recursive -f";
    kak = "kubectl apply -k";
    kk = "kubectl kustomize";

    # Execute and logs
    kex = "kubectl exec -i -t";
    ksysex = "kubectl --namespace=kube-system exec -i -t";
    klo = "kubectl logs -f";
    ksyslo = "kubectl --namespace=kube-system logs -f";
    klop = "kubectl logs -f -p";
    ksyslop = "kubectl --namespace=kube-system logs -f -p";

    # Networking
    kp = "kubectl proxy";
    kpf = "kubectl port-forward";

    # CRUD operations
    kg = "kubectl get";
    ksysg = "kubectl --namespace=kube-system get";
    kd = "kubectl describe";
    ksysd = "kubectl --namespace=kube-system describe";
    krm = "kubectl delete";
    ksysrm = "kubectl --namespace=kube-system delete";

    # Run commands
    krun = "kubectl run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t";
    ksysrun = "kubectl --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t";

    # Pods
    kgpo = "kubectl get pods";
    ksysgpo = "kubectl --namespace=kube-system get pods";
    kdpo = "kubectl describe pods";
    ksysdpo = "kubectl --namespace=kube-system describe pods";
    krmpo = "kubectl delete pods";
    ksysrmpo = "kubectl --namespace=kube-system delete pods";

    # Deployments
    kgdep = "kubectl get deployment";
    ksysgdep = "kubectl --namespace=kube-system get deployment";
    kddep = "kubectl describe deployment";
    ksysddep = "kubectl --namespace=kube-system describe deployment";
    krmdep = "kubectl delete deployment";
    ksysrmdep = "kubectl --namespace=kube-system delete deployment";

    # Statefulsets
    kgsts = "kubectl get statefulset";
    ksysgsts = "kubectl --namespace=kube-system get statefulset";
    kdsts = "kubectl describe statefulset";
    ksysdsts = "kubectl --namespace=kube-system describe statefulset";
    krmsts = "kubectl delete statefulset";
    ksysrmsts = "kubectl --namespace=kube-system delete statefulset";

    # Services
    kgsvc = "kubectl get service";
    ksysgsvc = "kubectl --namespace=kube-system get service";
    kdsvc = "kubectl describe service";
    ksysdsvc = "kubectl --namespace=kube-system describe service";
    krmsvc = "kubectl delete service";
    ksysrmsvc = "kubectl --namespace=kube-system delete service";

    # Ingresses
    kging = "kubectl get ingress";
    ksysging = "kubectl --namespace=kube-system get ingress";
    kding = "kubectl describe ingress";
    ksysding = "kubectl --namespace=kube-system describe ingress";
    krming = "kubectl delete ingress";
    ksysrming = "kubectl --namespace=kube-system delete ingress";

    # ConfigMaps
    kgcm = "kubectl get configmap";
    ksysgcm = "kubectl --namespace=kube-system get configmap";
    kdcm = "kubectl describe configmap";
    ksysdcm = "kubectl --namespace=kube-system describe configmap";
    krmcm = "kubectl delete configmap";
    ksysrmcm = "kubectl --namespace=kube-system delete configmap";

    # Secrets
    kgsec = "kubectl get secret";
    ksysgsec = "kubectl --namespace=kube-system get secret";
    kdsec = "kubectl describe secret";
    ksysdsec = "kubectl --namespace=kube-system describe secret";
    krmsec = "kubectl delete secret";
    ksysrmsec = "kubectl --namespace=kube-system delete secret";

    # Nodes and namespaces
    kgno = "kubectl get nodes";
    kdno = "kubectl describe nodes";
    kgns = "kubectl get namespaces";
    kdns = "kubectl describe namespaces";
    krmns = "kubectl delete namespaces";

    # Output formats
    kgoyaml = "kubectl get -o=yaml";
    ksysgoyaml = "kubectl --namespace=kube-system get -o=yaml";
    kgpooyaml = "kubectl get pods -o=yaml";
    ksysgpooyaml = "kubectl --namespace=kube-system get pods -o=yaml";
    kgdepoyaml = "kubectl get deployment -o=yaml";
    ksysgdepoyaml = "kubectl --namespace=kube-system get deployment -o=yaml";
    kgstsoyaml = "kubectl get statefulset -o=yaml";
    ksysgstsoyaml = "kubectl --namespace=kube-system get statefulset -o=yaml";
    kgsvcoyaml = "kubectl get service -o=yaml";
    ksysgsvcoyaml = "kubectl --namespace=kube-system get service -o=yaml";
    kgingoyaml = "kubectl get ingress -o=yaml";
    ksysgingoyaml = "kubectl --namespace=kube-system get ingress -o=yaml";
    kgcmoyaml = "kubectl get configmap -o=yaml";
    ksysgcmoyaml = "kubectl --namespace=kube-system get configmap -o=yaml";
    kgsecoyaml = "kubectl get secret -o=yaml";
    ksysgsecoyaml = "kubectl --namespace=kube-system get secret -o=yaml";
    kgnooyaml = "kubectl get nodes -o=yaml";
    kgnsoyaml = "kubectl get namespaces -o=yaml";

    # Wide output
    kgowide = "kubectl get -o=wide";
    ksysgowide = "kubectl --namespace=kube-system get -o=wide";
    kgpoowide = "kubectl get pods -o=wide";
    ksysgpoowide = "kubectl --namespace=kube-system get pods -o=wide";
    kgdepowide = "kubectl get deployment -o=wide";
    ksysgdepowide = "kubectl --namespace=kube-system get deployment -o=wide";
    kgstsowide = "kubectl get statefulset -o=wide";
    ksysgstsowide = "kubectl --namespace=kube-system get statefulset -o=wide";
    kgsvcowide = "kubectl get service -o=wide";
    ksysgsvcowide = "kubectl --namespace=kube-system get service -o=wide";
    kgingowide = "kubectl get ingress -o=wide";
    ksysgingowide = "kubectl --namespace=kube-system get ingress -o=wide";
    kgcmowide = "kubectl get configmap -o=wide";
    ksysgcmowide = "kubectl --namespace=kube-system get configmap -o=wide";
    kgsecowide = "kubectl get secret -o=wide";
    ksysgsecowide = "kubectl --namespace=kube-system get secret -o=wide";
    kgnoowide = "kubectl get nodes -o=wide";
    kgnsowide = "kubectl get namespaces -o=wide";

    # JSON output
    kgojson = "kubectl get -o=json";
    ksysgojson = "kubectl --namespace=kube-system get -o=json";
    kgpoojson = "kubectl get pods -o=json";
    ksysgpoojson = "kubectl --namespace=kube-system get pods -o=json";
    kgdepojson = "kubectl get deployment -o=json";
    ksysgdepojson = "kubectl --namespace=kube-system get deployment -o=json";
    kgstsojson = "kubectl get statefulset -o=json";
    ksysgstsojson = "kubectl --namespace=kube-system get statefulset -o=json";
    kgsvcojson = "kubectl get service -o=json";
    ksysgsvcojson = "kubectl --namespace=kube-system get service -o=json";
    kgingojson = "kubectl get ingress -o=json";
    ksysgingojson = "kubectl --namespace=kube-system get ingress -o=json";
    kgcmojson = "kubectl get configmap -o=json";
    ksysgcmojson = "kubectl --namespace=kube-system get configmap -o=json";
    kgsecojson = "kubectl get secret -o=json";
    ksysgsecojson = "kubectl --namespace=kube-system get secret -o=json";
    kgnoojson = "kubectl get nodes -o=json";
    kgnsojson = "kubectl get namespaces -o=json";

    # All namespaces
    kgall = "kubectl get --all-namespaces";
    kdall = "kubectl describe --all-namespaces";
    kgpoall = "kubectl get pods --all-namespaces";
    kdpoall = "kubectl describe pods --all-namespaces";
    kgdepall = "kubectl get deployment --all-namespaces";
    kddepall = "kubectl describe deployment --all-namespaces";
    kgstsall = "kubectl get statefulset --all-namespaces";
    kdstsall = "kubectl describe statefulset --all-namespaces";
    kgsvcall = "kubectl get service --all-namespaces";
    kdsvcall = "kubectl describe service --all-namespaces";
    kgingall = "kubectl get ingress --all-namespaces";
    kdingall = "kubectl describe ingress --all-namespaces";
    kgcmall = "kubectl get configmap --all-namespaces";
    kdcmall = "kubectl describe configmap --all-namespaces";
    kgsecall = "kubectl get secret --all-namespaces";
    kdsecall = "kubectl describe secret --all-namespaces";

    # Watch mode
    kgpow = "kubectl get pods --watch";
    ksysgpow = "kubectl --namespace=kube-system get pods --watch";
    kgdepw = "kubectl get deployment --watch";
    ksysgdepw = "kubectl --namespace=kube-system get deployment --watch";
    kgstsw = "kubectl get statefulset --watch";
    ksysgstsw = "kubectl --namespace=kube-system get statefulset --watch";
    kgsvcw = "kubectl get service --watch";
    ksysgsvcw = "kubectl --namespace=kube-system get service --watch";
    kgingw = "kubectl get ingress --watch";
    ksysgingw = "kubectl --namespace=kube-system get ingress --watch";
    kgcmw = "kubectl get configmap --watch";
    ksysgcmw = "kubectl --namespace=kube-system get configmap --watch";
    kgsecw = "kubectl get secret --watch";
    ksysgsecw = "kubectl --namespace=kube-system get secret --watch";
    kgnow = "kubectl get nodes --watch";
    kgnsw = "kubectl get namespaces --watch";

    # Clean up
    krmall = "kubectl delete --all";
    krmpoall = "kubectl delete pods --all";
    krmdepall = "kubectl delete deployment --all";
    krmstsall = "kubectl delete statefulset --all";
    krmsvcall = "kubectl delete service --all";
    krmingall = "kubectl delete ingress --all";
    krmcmall = "kubectl delete configmap --all";
    krmsecall = "kubectl delete secret --all";
  };

  # Zoxide aliases
  zoxide = {
    z = "__zoxide_z";
    zi = "__zoxide_zi";
  };
}
