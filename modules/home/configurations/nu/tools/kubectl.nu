alias k = kubectl
alias ksys = kubectl --namespace=kube-system
alias ka = kubectl apply --recursive -f
alias ksysa = kubectl --namespace=kube-system apply --recursive -f
alias kak = kubectl apply -k
alias kk = kubectl kustomize
alias kex = kubectl exec -i -t
alias ksysex = kubectl --namespace=kube-system exec -i -t
alias klo = kubectl logs -f
alias ksyslo = kubectl --namespace=kube-system logs -f
alias klop = kubectl logs -f -p
alias ksyslop = kubectl --namespace=kube-system logs -f -p
alias kp = kubectl proxy
alias kpf = kubectl port-forward
alias kg = kubectl get
alias ksysg = kubectl --namespace=kube-system get
alias kd = kubectl describe
alias ksysd = kubectl --namespace=kube-system describe
alias krm = kubectl delete
alias ksysrm = kubectl --namespace=kube-system delete
alias krun = kubectl run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t
alias ksysrun = kubectl --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t
alias kgpo = kubectl get pods
alias ksysgpo = kubectl --namespace=kube-system get pods
alias kdpo = kubectl describe pods
alias ksysdpo = kubectl --namespace=kube-system describe pods
alias krmpo = kubectl delete pods
alias ksysrmpo = kubectl --namespace=kube-system delete pods
alias kgdep = kubectl get deployment
alias ksysgdep = kubectl --namespace=kube-system get deployment
alias kddep = kubectl describe deployment
alias ksysddep = kubectl --namespace=kube-system describe deployment
alias krmdep = kubectl delete deployment
alias ksysrmdep = kubectl --namespace=kube-system delete deployment
alias kgsts = kubectl get statefulset
alias ksysgsts = kubectl --namespace=kube-system get statefulset
alias kdsts = kubectl describe statefulset
alias ksysdsts = kubectl --namespace=kube-system describe statefulset
alias krmsts = kubectl delete statefulset
alias ksysrmsts = kubectl --namespace=kube-system delete statefulset
alias kgsvc = kubectl get service
alias ksysgsvc = kubectl --namespace=kube-system get service
alias kdsvc = kubectl describe service
alias ksysdsvc = kubectl --namespace=kube-system describe service
alias krmsvc = kubectl delete service
alias ksysrmsvc = kubectl --namespace=kube-system delete service
alias kging = kubectl get ingress
alias ksysging = kubectl --namespace=kube-system get ingress
alias kding = kubectl describe ingress
alias ksysding = kubectl --namespace=kube-system describe ingress
alias krming = kubectl delete ingress
alias ksysrming = kubectl --namespace=kube-system delete ingress
alias kgcm = kubectl get configmap
alias ksysgcm = kubectl --namespace=kube-system get configmap
alias kdcm = kubectl describe configmap
alias ksysdcm = kubectl --namespace=kube-system describe configmap
alias krmcm = kubectl delete configmap
alias ksysrmcm = kubectl --namespace=kube-system delete configmap
alias kgsec = kubectl get secret
alias ksysgsec = kubectl --namespace=kube-system get secret
alias kdsec = kubectl describe secret
alias ksysdsec = kubectl --namespace=kube-system describe secret
alias krmsec = kubectl delete secret
alias ksysrmsec = kubectl --namespace=kube-system delete secret
alias kgno = kubectl get nodes
alias kdno = kubectl describe nodes
alias kgns = kubectl get namespaces
alias kdns = kubectl describe namespaces
alias krmns = kubectl delete namespaces
alias kgoyaml = kubectl get -o=yaml
alias ksysgoyaml = kubectl --namespace=kube-system get -o=yaml
alias kgpooyaml = kubectl get pods -o=yaml
alias ksysgpooyaml = kubectl --namespace=kube-system get pods -o=yaml
alias kgdepoyaml = kubectl get deployment -o=yaml
alias ksysgdepoyaml = kubectl --namespace=kube-system get deployment -o=yaml
alias kgstsoyaml = kubectl get statefulset -o=yaml
alias ksysgstsoyaml = kubectl --namespace=kube-system get statefulset -o=yaml
alias kgsvcoyaml = kubectl get service -o=yaml
alias ksysgsvcoyaml = kubectl --namespace=kube-system get service -o=yaml
alias kgingoyaml = kubectl get ingress -o=yaml
alias ksysgingoyaml = kubectl --namespace=kube-system get ingress -o=yaml
alias kgcmoyaml = kubectl get configmap -o=yaml
alias ksysgcmoyaml = kubectl --namespace=kube-system get configmap -o=yaml
alias kgsecoyaml = kubectl get secret -o=yaml
alias ksysgsecoyaml = kubectl --namespace=kube-system get secret -o=yaml
alias kgnooyaml = kubectl get nodes -o=yaml
alias kgnsoyaml = kubectl get namespaces -o=yaml
alias kgowide = kubectl get -o=wide
alias ksysgowide = kubectl --namespace=kube-system get -o=wide
alias kgpoowide = kubectl get pods -o=wide
alias ksysgpoowide = kubectl --namespace=kube-system get pods -o=wide
alias kgdepowide = kubectl get deployment -o=wide
alias ksysgdepowide = kubectl --namespace=kube-system get deployment -o=wide
alias kgstsowide = kubectl get statefulset -o=wide
alias ksysgstsowide = kubectl --namespace=kube-system get statefulset -o=wide
alias kgsvcowide = kubectl get service -o=wide
alias ksysgsvcowide = kubectl --namespace=kube-system get service -o=wide
alias kgingowide = kubectl get ingress -o=wide
alias ksysgingowide = kubectl --namespace=kube-system get ingress -o=wide
alias kgcmowide = kubectl get configmap -o=wide
alias ksysgcmowide = kubectl --namespace=kube-system get configmap -o=wide
alias kgsecowide = kubectl get secret -o=wide
alias ksysgsecowide = kubectl --namespace=kube-system get secret -o=wide
alias kgnoowide = kubectl get nodes -o=wide
alias kgnsowide = kubectl get namespaces -o=wide
alias kgojson = kubectl get -o=json
alias ksysgojson = kubectl --namespace=kube-system get -o=json
alias kgpoojson = kubectl get pods -o=json
alias ksysgpoojson = kubectl --namespace=kube-system get pods -o=json
alias kgdepojson = kubectl get deployment -o=json
alias ksysgdepojson = kubectl --namespace=kube-system get deployment -o=json
alias kgstsojson = kubectl get statefulset -o=json
alias ksysgstsojson = kubectl --namespace=kube-system get statefulset -o=json
alias kgsvcojson = kubectl get service -o=json
alias ksysgsvcojson = kubectl --namespace=kube-system get service -o=json
alias kgingojson = kubectl get ingress -o=json
alias ksysgingojson = kubectl --namespace=kube-system get ingress -o=json
alias kgcmojson = kubectl get configmap -o=json
alias ksysgcmojson = kubectl --namespace=kube-system get configmap -o=json
alias kgsecojson = kubectl get secret -o=json
alias ksysgsecojson = kubectl --namespace=kube-system get secret -o=json
alias kgnoojson = kubectl get nodes -o=json
alias kgnsojson = kubectl get namespaces -o=json
alias kgall = kubectl get --all-namespaces
alias kdall = kubectl describe --all-namespaces
alias kgpoall = kubectl get pods --all-namespaces
alias kdpoall = kubectl describe pods --all-namespaces
alias kgdepall = kubectl get deployment --all-namespaces
alias kddepall = kubectl describe deployment --all-namespaces
alias kgstsall = kubectl get statefulset --all-namespaces
alias kdstsall = kubectl describe statefulset --all-namespaces
alias kgsvcall = kubectl get service --all-namespaces
alias kdsvcall = kubectl describe service --all-namespaces
alias kgingall = kubectl get ingress --all-namespaces
alias kdingall = kubectl describe ingress --all-namespaces
alias kgcmall = kubectl get configmap --all-namespaces
alias kdcmall = kubectl describe configmap --all-namespaces
alias kgsecall = kubectl get secret --all-namespaces
alias kdsecall = kubectl describe secret --all-namespaces
alias kgnsall = kubectl get namespaces --all-namespaces
alias kdnsall = kubectl describe namespaces --all-namespaces
alias kgsl = kubectl get --show-labels
alias ksysgsl = kubectl --namespace=kube-system get --show-labels
alias kgposl = kubectl get pods --show-labels
alias ksysgposl = kubectl --namespace=kube-system get pods --show-labels
alias kgdepsl = kubectl get deployment --show-labels
alias ksysgdepsl = kubectl --namespace=kube-system get deployment --show-labels
alias kgstssl = kubectl get statefulset --show-labels
alias ksysgstssl = kubectl --namespace=kube-system get statefulset --show-labels
alias kgsvcsl = kubectl get service --show-labels
alias ksysgsvcsl = kubectl --namespace=kube-system get service --show-labels
alias kgingsl = kubectl get ingress --show-labels
alias ksysgingsl = kubectl --namespace=kube-system get ingress --show-labels
alias kgcmsl = kubectl get configmap --show-labels
alias ksysgcmsl = kubectl --namespace=kube-system get configmap --show-labels
alias kgsecsl = kubectl get secret --show-labels
alias ksysgsecsl = kubectl --namespace=kube-system get secret --show-labels
alias kgnosl = kubectl get nodes --show-labels
alias kgnssl = kubectl get namespaces --show-labels
alias krmall = kubectl delete --all
alias ksysrmall = kubectl --namespace=kube-system delete --all
alias krmpoall = kubectl delete pods --all
alias ksysrmpoall = kubectl --namespace=kube-system delete pods --all
alias krmdepall = kubectl delete deployment --all
alias ksysrmdepall = kubectl --namespace=kube-system delete deployment --all
alias krmstsall = kubectl delete statefulset --all
alias ksysrmstsall = kubectl --namespace=kube-system delete statefulset --all
alias krmsvcall = kubectl delete service --all
alias ksysrmsvcall = kubectl --namespace=kube-system delete service --all
alias krmingall = kubectl delete ingress --all
alias ksysrmingall = kubectl --namespace=kube-system delete ingress --all
alias krmcmall = kubectl delete configmap --all
alias ksysrmcmall = kubectl --namespace=kube-system delete configmap --all
alias krmsecall = kubectl delete secret --all
alias ksysrmsecall = kubectl --namespace=kube-system delete secret --all
alias krmnsall = kubectl delete namespaces --all
alias kgw = kubectl get --watch
alias ksysgw = kubectl --namespace=kube-system get --watch
alias kgpow = kubectl get pods --watch
alias ksysgpow = kubectl --namespace=kube-system get pods --watch
alias kgdepw = kubectl get deployment --watch
alias ksysgdepw = kubectl --namespace=kube-system get deployment --watch
alias kgstsw = kubectl get statefulset --watch
alias ksysgstsw = kubectl --namespace=kube-system get statefulset --watch
alias kgsvcw = kubectl get service --watch
alias ksysgsvcw = kubectl --namespace=kube-system get service --watch
alias kgingw = kubectl get ingress --watch
alias ksysgingw = kubectl --namespace=kube-system get ingress --watch
alias kgcmw = kubectl get configmap --watch
alias ksysgcmw = kubectl --namespace=kube-system get configmap --watch
alias kgsecw = kubectl get secret --watch
alias ksysgsecw = kubectl --namespace=kube-system get secret --watch
alias kgnow = kubectl get nodes --watch
alias kgnsw = kubectl get namespaces --watch
alias kgoyamlall = kubectl get -o=yaml --all-namespaces
alias kgpooyamlall = kubectl get pods -o=yaml --all-namespaces
alias kgdepoyamlall = kubectl get deployment -o=yaml --all-namespaces
alias kgstsoyamlall = kubectl get statefulset -o=yaml --all-namespaces
alias kgsvcoyamlall = kubectl get service -o=yaml --all-namespaces
alias kgingoyamlall = kubectl get ingress -o=yaml --all-namespaces
alias kgcmoyamlall = kubectl get configmap -o=yaml --all-namespaces
alias kgsecoyamlall = kubectl get secret -o=yaml --all-namespaces
alias kgnsoyamlall = kubectl get namespaces -o=yaml --all-namespaces
alias kgalloyaml = kubectl get --all-namespaces -o=yaml
alias kgpoalloyaml = kubectl get pods --all-namespaces -o=yaml
alias kgdepalloyaml = kubectl get deployment --all-namespaces -o=yaml
alias kgstsalloyaml = kubectl get statefulset --all-namespaces -o=yaml
alias kgsvcalloyaml = kubectl get service --all-namespaces -o=yaml
alias kgingalloyaml = kubectl get ingress --all-namespaces -o=yaml
alias kgcmalloyaml = kubectl get configmap --all-namespaces -o=yaml
alias kgsecalloyaml = kubectl get secret --all-namespaces -o=yaml
alias kgnsalloyaml = kubectl get namespaces --all-namespaces -o=yaml
alias kgwoyaml = kubectl get --watch -o=yaml
alias ksysgwoyaml = kubectl --namespace=kube-system get --watch -o=yaml
alias kgpowoyaml = kubectl get pods --watch -o=yaml
alias ksysgpowoyaml = kubectl --namespace=kube-system get pods --watch -o=yaml
alias kgdepwoyaml = kubectl get deployment --watch -o=yaml
alias ksysgdepwoyaml = kubectl --namespace=kube-system get deployment --watch -o=yaml
alias kgstswoyaml = kubectl get statefulset --watch -o=yaml
alias ksysgstswoyaml = kubectl --namespace=kube-system get statefulset --watch -o=yaml
alias kgsvcwoyaml = kubectl get service --watch -o=yaml
alias ksysgsvcwoyaml = kubectl --namespace=kube-system get service --watch -o=yaml
alias kgingwoyaml = kubectl get ingress --watch -o=yaml
alias ksysgingwoyaml = kubectl --namespace=kube-system get ingress --watch -o=yaml
alias kgcmwoyaml = kubectl get configmap --watch -o=yaml
alias ksysgcmwoyaml = kubectl --namespace=kube-system get configmap --watch -o=yaml
alias kgsecwoyaml = kubectl get secret --watch -o=yaml
alias ksysgsecwoyaml = kubectl --namespace=kube-system get secret --watch -o=yaml
alias kgnowoyaml = kubectl get nodes --watch -o=yaml
alias kgnswoyaml = kubectl get namespaces --watch -o=yaml
alias kgowideall = kubectl get -o=wide --all-namespaces
alias kgpoowideall = kubectl get pods -o=wide --all-namespaces
alias kgdepowideall = kubectl get deployment -o=wide --all-namespaces
alias kgstsowideall = kubectl get statefulset -o=wide --all-namespaces
alias kgsvcowideall = kubectl get service -o=wide --all-namespaces
alias kgingowideall = kubectl get ingress -o=wide --all-namespaces
alias kgcmowideall = kubectl get configmap -o=wide --all-namespaces
alias kgsecowideall = kubectl get secret -o=wide --all-namespaces
alias kgnsowideall = kubectl get namespaces -o=wide --all-namespaces
alias kgallowide = kubectl get --all-namespaces -o=wide
alias kgpoallowide = kubectl get pods --all-namespaces -o=wide
alias kgdepallowide = kubectl get deployment --all-namespaces -o=wide
alias kgstsallowide = kubectl get statefulset --all-namespaces -o=wide
alias kgsvcallowide = kubectl get service --all-namespaces -o=wide
alias kgingallowide = kubectl get ingress --all-namespaces -o=wide
alias kgcmallowide = kubectl get configmap --all-namespaces -o=wide
alias kgsecallowide = kubectl get secret --all-namespaces -o=wide
alias kgnsallowide = kubectl get namespaces --all-namespaces -o=wide
alias kgowidesl = kubectl get -o=wide --show-labels
alias ksysgowidesl = kubectl --namespace=kube-system get -o=wide --show-labels
alias kgpoowidesl = kubectl get pods -o=wide --show-labels
alias ksysgpoowidesl = kubectl --namespace=kube-system get pods -o=wide --show-labels
alias kgdepowidesl = kubectl get deployment -o=wide --show-labels
alias ksysgdepowidesl = kubectl --namespace=kube-system get deployment -o=wide --show-labels
alias kgstsowidesl = kubectl get statefulset -o=wide --show-labels
alias ksysgstsowidesl = kubectl --namespace=kube-system get statefulset -o=wide --show-labels
alias kgsvcowidesl = kubectl get service -o=wide --show-labels
alias ksysgsvcowidesl = kubectl --namespace=kube-system get service -o=wide --show-labels
alias kgingowidesl = kubectl get ingress -o=wide --show-labels
alias ksysgingowidesl = kubectl --namespace=kube-system get ingress -o=wide --show-labels
alias kgcmowidesl = kubectl get configmap -o=wide --show-labels
alias ksysgcmowidesl = kubectl --namespace=kube-system get configmap -o=wide --show-labels
alias kgsecowidesl = kubectl get secret -o=wide --show-labels
alias ksysgsecowidesl = kubectl --namespace=kube-system get secret -o=wide --show-labels
alias kgnoowidesl = kubectl get nodes -o=wide --show-labels
alias kgnsowidesl = kubectl get namespaces -o=wide --show-labels
alias kgslowide = kubectl get --show-labels -o=wide
alias ksysgslowide = kubectl --namespace=kube-system get --show-labels -o=wide
alias kgposlowide = kubectl get pods --show-labels -o=wide
alias ksysgposlowide = kubectl --namespace=kube-system get pods --show-labels -o=wide
alias kgdepslowide = kubectl get deployment --show-labels -o=wide
alias ksysgdepslowide = kubectl --namespace=kube-system get deployment --show-labels -o=wide
alias kgstsslowide = kubectl get statefulset --show-labels -o=wide
alias ksysgstsslowide = kubectl --namespace=kube-system get statefulset --show-labels -o=wide
alias kgsvcslowide = kubectl get service --show-labels -o=wide
alias ksysgsvcslowide = kubectl --namespace=kube-system get service --show-labels -o=wide
alias kgingslowide = kubectl get ingress --show-labels -o=wide
alias ksysgingslowide = kubectl --namespace=kube-system get ingress --show-labels -o=wide
alias kgcmslowide = kubectl get configmap --show-labels -o=wide
alias ksysgcmslowide = kubectl --namespace=kube-system get configmap --show-labels -o=wide
alias kgsecslowide = kubectl get secret --show-labels -o=wide
alias ksysgsecslowide = kubectl --namespace=kube-system get secret --show-labels -o=wide
alias kgnoslowide = kubectl get nodes --show-labels -o=wide
alias kgnsslowide = kubectl get namespaces --show-labels -o=wide
alias kgwowide = kubectl get --watch -o=wide
alias ksysgwowide = kubectl --namespace=kube-system get --watch -o=wide
alias kgpowowide = kubectl get pods --watch -o=wide
alias ksysgpowowide = kubectl --namespace=kube-system get pods --watch -o=wide
alias kgdepwowide = kubectl get deployment --watch -o=wide
alias ksysgdepwowide = kubectl --namespace=kube-system get deployment --watch -o=wide
alias kgstswowide = kubectl get statefulset --watch -o=wide
alias ksysgstswowide = kubectl --namespace=kube-system get statefulset --watch -o=wide
alias kgsvcwowide = kubectl get service --watch -o=wide
alias ksysgsvcwowide = kubectl --namespace=kube-system get service --watch -o=wide
alias kgingwowide = kubectl get ingress --watch -o=wide
alias ksysgingwowide = kubectl --namespace=kube-system get ingress --watch -o=wide
alias kgcmwowide = kubectl get configmap --watch -o=wide
alias ksysgcmwowide = kubectl --namespace=kube-system get configmap --watch -o=wide
alias kgsecwowide = kubectl get secret --watch -o=wide
alias ksysgsecwowide = kubectl --namespace=kube-system get secret --watch -o=wide
alias kgnowowide = kubectl get nodes --watch -o=wide
alias kgnswowide = kubectl get namespaces --watch -o=wide
alias kgojsonall = kubectl get -o=json --all-namespaces
alias kgpoojsonall = kubectl get pods -o=json --all-namespaces
alias kgdepojsonall = kubectl get deployment -o=json --all-namespaces
alias kgstsojsonall = kubectl get statefulset -o=json --all-namespaces
alias kgsvcojsonall = kubectl get service -o=json --all-namespaces
alias kgingojsonall = kubectl get ingress -o=json --all-namespaces
alias kgcmojsonall = kubectl get configmap -o=json --all-namespaces
alias kgsecojsonall = kubectl get secret -o=json --all-namespaces
alias kgnsojsonall = kubectl get namespaces -o=json --all-namespaces
alias kgallojson = kubectl get --all-namespaces -o=json
alias kgpoallojson = kubectl get pods --all-namespaces -o=json
alias kgdepallojson = kubectl get deployment --all-namespaces -o=json
alias kgstsallojson = kubectl get statefulset --all-namespaces -o=json
alias kgsvcallojson = kubectl get service --all-namespaces -o=json
alias kgingallojson = kubectl get ingress --all-namespaces -o=json
alias kgcmallojson = kubectl get configmap --all-namespaces -o=json
alias kgsecallojson = kubectl get secret --all-namespaces -o=json
alias kgnsallojson = kubectl get namespaces --all-namespaces -o=json
alias kgwojson = kubectl get --watch -o=json
alias ksysgwojson = kubectl --namespace=kube-system get --watch -o=json
alias kgpowojson = kubectl get pods --watch -o=json
alias ksysgpowojson = kubectl --namespace=kube-system get pods --watch -o=json
alias kgdepwojson = kubectl get deployment --watch -o=json
alias ksysgdepwojson = kubectl --namespace=kube-system get deployment --watch -o=json
alias kgstswojson = kubectl get statefulset --watch -o=json
alias ksysgstswojson = kubectl --namespace=kube-system get statefulset --watch -o=json
alias kgsvcwojson = kubectl get service --watch -o=json
alias ksysgsvcwojson = kubectl --namespace=kube-system get service --watch -o=json
alias kgingwojson = kubectl get ingress --watch -o=json
alias ksysgingwojson = kubectl --namespace=kube-system get ingress --watch -o=json
alias kgcmwojson = kubectl get configmap --watch -o=json
alias ksysgcmwojson = kubectl --namespace=kube-system get configmap --watch -o=json
alias kgsecwojson = kubectl get secret --watch -o=json
alias ksysgsecwojson = kubectl --namespace=kube-system get secret --watch -o=json
alias kgnowojson = kubectl get nodes --watch -o=json
alias kgnswojson = kubectl get namespaces --watch -o=json
alias kgallsl = kubectl get --all-namespaces --show-labels
alias kgpoallsl = kubectl get pods --all-namespaces --show-labels
alias kgdepallsl = kubectl get deployment --all-namespaces --show-labels
alias kgstsallsl = kubectl get statefulset --all-namespaces --show-labels
alias kgsvcallsl = kubectl get service --all-namespaces --show-labels
alias kgingallsl = kubectl get ingress --all-namespaces --show-labels
alias kgcmallsl = kubectl get configmap --all-namespaces --show-labels
alias kgsecallsl = kubectl get secret --all-namespaces --show-labels
alias kgnsallsl = kubectl get namespaces --all-namespaces --show-labels
alias kgslall = kubectl get --show-labels --all-namespaces
alias kgposlall = kubectl get pods --show-labels --all-namespaces
alias kgdepslall = kubectl get deployment --show-labels --all-namespaces
alias kgstsslall = kubectl get statefulset --show-labels --all-namespaces
alias kgsvcslall = kubectl get service --show-labels --all-namespaces
alias kgingslall = kubectl get ingress --show-labels --all-namespaces
alias kgcmslall = kubectl get configmap --show-labels --all-namespaces
alias kgsecslall = kubectl get secret --show-labels --all-namespaces
alias kgnsslall = kubectl get namespaces --show-labels --all-namespaces
alias kgallw = kubectl get --all-namespaces --watch
alias kgpoallw = kubectl get pods --all-namespaces --watch
alias kgdepallw = kubectl get deployment --all-namespaces --watch
alias kgstsallw = kubectl get statefulset --all-namespaces --watch
alias kgsvcallw = kubectl get service --all-namespaces --watch
alias kgingallw = kubectl get ingress --all-namespaces --watch
alias kgcmallw = kubectl get configmap --all-namespaces --watch
alias kgsecallw = kubectl get secret --all-namespaces --watch
alias kgnsallw = kubectl get namespaces --all-namespaces --watch
alias kgwall = kubectl get --watch --all-namespaces
alias kgpowall = kubectl get pods --watch --all-namespaces
alias kgdepwall = kubectl get deployment --watch --all-namespaces
alias kgstswall = kubectl get statefulset --watch --all-namespaces
alias kgsvcwall = kubectl get service --watch --all-namespaces
alias kgingwall = kubectl get ingress --watch --all-namespaces
alias kgcmwall = kubectl get configmap --watch --all-namespaces
alias kgsecwall = kubectl get secret --watch --all-namespaces
alias kgnswall = kubectl get namespaces --watch --all-namespaces
alias kgslw = kubectl get --show-labels --watch
alias ksysgslw = kubectl --namespace=kube-system get --show-labels --watch
alias kgposlw = kubectl get pods --show-labels --watch
alias ksysgposlw = kubectl --namespace=kube-system get pods --show-labels --watch
alias kgdepslw = kubectl get deployment --show-labels --watch
alias ksysgdepslw = kubectl --namespace=kube-system get deployment --show-labels --watch
alias kgstsslw = kubectl get statefulset --show-labels --watch
alias ksysgstsslw = kubectl --namespace=kube-system get statefulset --show-labels --watch
alias kgsvcslw = kubectl get service --show-labels --watch
alias ksysgsvcslw = kubectl --namespace=kube-system get service --show-labels --watch
alias kgingslw = kubectl get ingress --show-labels --watch
alias ksysgingslw = kubectl --namespace=kube-system get ingress --show-labels --watch
alias kgcmslw = kubectl get configmap --show-labels --watch
alias ksysgcmslw = kubectl --namespace=kube-system get configmap --show-labels --watch
alias kgsecslw = kubectl get secret --show-labels --watch
alias ksysgsecslw = kubectl --namespace=kube-system get secret --show-labels --watch
alias kgnoslw = kubectl get nodes --show-labels --watch
alias kgnsslw = kubectl get namespaces --show-labels --watch
alias kgwsl = kubectl get --watch --show-labels
alias ksysgwsl = kubectl --namespace=kube-system get --watch --show-labels
alias kgpowsl = kubectl get pods --watch --show-labels
alias ksysgpowsl = kubectl --namespace=kube-system get pods --watch --show-labels
alias kgdepwsl = kubectl get deployment --watch --show-labels
alias ksysgdepwsl = kubectl --namespace=kube-system get deployment --watch --show-labels
alias kgstswsl = kubectl get statefulset --watch --show-labels
alias ksysgstswsl = kubectl --namespace=kube-system get statefulset --watch --show-labels
alias kgsvcwsl = kubectl get service --watch --show-labels
alias ksysgsvcwsl = kubectl --namespace=kube-system get service --watch --show-labels
alias kgingwsl = kubectl get ingress --watch --show-labels
alias ksysgingwsl = kubectl --namespace=kube-system get ingress --watch --show-labels
alias kgcmwsl = kubectl get configmap --watch --show-labels
alias kgstsallwoyaml = kubectl get statefulset --all-namespaces --watch -o=yaml
alias kgsvcallwoyaml = kubectl get service --all-namespaces --watch -o=yaml
alias kgingallwoyaml = kubectl get ingress --all-namespaces --watch -o=yaml
alias kgcmallwoyaml = kubectl get configmap --all-namespaces --watch -o=yaml
alias kgsecallwoyaml = kubectl get secret --all-namespaces --watch -o=yaml
alias kgnsallwoyaml = kubectl get namespaces --all-namespaces --watch -o=yaml
alias kgwalloyaml = kubectl get --watch --all-namespaces -o=yaml
alias kgpowalloyaml = kubectl get pods --watch --all-namespaces -o=yaml
alias kgdepwalloyaml = kubectl get deployment --watch --all-namespaces -o=yaml
alias kgstswalloyaml = kubectl get statefulset --watch --all-namespaces -o=yaml
alias kgdepowideallsl = kubectl get deployment -o=wide --all-namespaces --show-labels
alias kgstsowideallsl = kubectl get statefulset -o=wide --all-namespaces --show-labels
alias kgsvcowideallsl = kubectl get service -o=wide --all-namespaces --show-labels
alias kgingowideallsl = kubectl get ingress -o=wide --all-namespaces --show-labels
alias kgcmowideallsl = kubectl get configmap -o=wide --all-namespaces --show-labels
alias kgsecowideallsl = kubectl get secret -o=wide --all-namespaces --show-labels
alias kgnsowideallsl = kubectl get namespaces -o=wide --all-namespaces --show-labels
alias kgowideslall = kubectl get -o=wide --show-labels --all-namespaces
alias kgpoowideslall = kubectl get pods -o=wide --show-labels --all-namespaces
alias kgdepowideslall = kubectl get deployment -o=wide --show-labels --all-namespaces
alias kgstsowideslall = kubectl get statefulset -o=wide --show-labels --all-namespaces
alias kgsvcowideslall = kubectl get service -o=wide --show-labels --all-namespaces
alias kgingowideslall = kubectl get ingress -o=wide --show-labels --all-namespaces
alias kgcmowideslall = kubectl get configmap -o=wide --show-labels --all-namespaces
alias kgsecowideslall = kubectl get secret -o=wide --show-labels --all-namespaces
alias kgnsowideslall = kubectl get namespaces -o=wide --show-labels --all-namespaces
alias kgallowidesl = kubectl get --all-namespaces -o=wide --show-labels
alias kgpoallowidesl = kubectl get pods --all-namespaces -o=wide --show-labels
alias kgdepallowidesl = kubectl get deployment --all-namespaces -o=wide --show-labels
alias kgstsallowidesl = kubectl get statefulset --all-namespaces -o=wide --show-labels
alias kgsvcallowidesl = kubectl get service --all-namespaces -o=wide --show-labels
alias kgingallowidesl = kubectl get ingress --all-namespaces -o=wide --show-labels
alias kgcmallowidesl = kubectl get configmap --all-namespaces -o=wide --show-labels
alias kgsecallowidesl = kubectl get secret --all-namespaces -o=wide --show-labels
alias kgnsallowidesl = kubectl get namespaces --all-namespaces -o=wide --show-labels
alias kgallslowide = kubectl get --all-namespaces --show-labels -o=wide
alias kgpoallslowide = kubectl get pods --all-namespaces --show-labels -o=wide
alias kgdepallslowide = kubectl get deployment --all-namespaces --show-labels -o=wide
alias kgstsallslowide = kubectl get statefulset --all-namespaces --show-labels -o=wide
alias kgsvcallslowide = kubectl get service --all-namespaces --show-labels -o=wide
alias kgingallslowide = kubectl get ingress --all-namespaces --show-labels -o=wide
alias kgcmallslowide = kubectl get configmap --all-namespaces --show-labels -o=wide
alias kgsecallslowide = kubectl get secret --all-namespaces --show-labels -o=wide
alias kgnsallslowide = kubectl get namespaces --all-namespaces --show-labels -o=wide
alias kgslowideall = kubectl get --show-labels -o=wide --all-namespaces
alias kgposlowideall = kubectl get pods --show-labels -o=wide --all-namespaces
alias kgdepslowideall = kubectl get deployment --show-labels -o=wide --all-namespaces
alias kgstsslowideall = kubectl get statefulset --show-labels -o=wide --all-namespaces
alias kgsvcslowideall = kubectl get service --show-labels -o=wide --all-namespaces
alias kgingslowideall = kubectl get ingress --show-labels -o=wide --all-namespaces
alias kgcmslowideall = kubectl get configmap --show-labels -o=wide --all-namespaces
alias kgsecslowideall = kubectl get secret --show-labels -o=wide --all-namespaces
alias kgnsslowideall = kubectl get namespaces --show-labels -o=wide --all-namespaces
alias kgslallowide = kubectl get --show-labels --all-namespaces -o=wide
alias kgposlallowide = kubectl get pods --show-labels --all-namespaces -o=wide
alias kgdepslallowide = kubectl get deployment --show-labels --all-namespaces -o=wide
alias kgstsslallowide = kubectl get statefulset --show-labels --all-namespaces -o=wide
alias kgsvcslallowide = kubectl get service --show-labels --all-namespaces -o=wide
alias kgingslallowide = kubectl get ingress --show-labels --all-namespaces -o=wide
alias kgcmslallowide = kubectl get configmap --show-labels --all-namespaces -o=wide
alias kgsecslallowide = kubectl get secret --show-labels --all-namespaces -o=wide
alias kgnsslallowide = kubectl get namespaces --show-labels --all-namespaces -o=wide
alias kgallwowide = kubectl get --all-namespaces --watch -o=wide
alias kgpoallwowide = kubectl get pods --all-namespaces --watch -o=wide
alias kgdepallwowide = kubectl get deployment --all-namespaces --watch -o=wide
alias kgstsallwowide = kubectl get statefulset --all-namespaces --watch -o=wide
alias kgsvcallwowide = kubectl get service --all-namespaces --watch -o=wide
alias kgingallwowide = kubectl get ingress --all-namespaces --watch -o=wide
alias kgcmallwowide = kubectl get configmap --all-namespaces --watch -o=wide
alias kgsecallwowide = kubectl get secret --all-namespaces --watch -o=wide
alias kgnsallwowide = kubectl get namespaces --all-namespaces --watch -o=wide
alias kgwowideall = kubectl get --watch -o=wide --all-namespaces
alias kgpowowideall = kubectl get pods --watch -o=wide --all-namespaces
alias kgdepwowideall = kubectl get deployment --watch -o=wide --all-namespaces
alias kgstswowideall = kubectl get statefulset --watch -o=wide --all-namespaces
alias kgsvcwowideall = kubectl get service --watch -o=wide --all-namespaces
alias kgingwowideall = kubectl get ingress --watch -o=wide --all-namespaces
alias kgcmwowideall = kubectl get configmap --watch -o=wide --all-namespaces
alias kgsecwowideall = kubectl get secret --watch -o=wide --all-namespaces
alias kgnswowideall = kubectl get namespaces --watch -o=wide --all-namespaces
alias kgwallowide = kubectl get --watch --all-namespaces -o=wide
alias kgpowallowide = kubectl get pods --watch --all-namespaces -o=wide
alias kgdepwallowide = kubectl get deployment --watch --all-namespaces -o=wide
alias kgstswallowide = kubectl get statefulset --watch --all-namespaces -o=wide
alias kgsvcwallowide = kubectl get service --watch --all-namespaces -o=wide
alias kgingwallowide = kubectl get ingress --watch --all-namespaces -o=wide
alias kgcmwallowide = kubectl get configmap --watch --all-namespaces -o=wide
alias kgsecwallowide = kubectl get secret --watch --all-namespaces -o=wide
alias kgnswallowide = kubectl get namespaces --watch --all-namespaces -o=wide
alias kgslwowide = kubectl get --show-labels --watch -o=wide
alias ksysgslwowide = kubectl --namespace=kube-system get --show-labels --watch -o=wide
alias kgposlwowide = kubectl get pods --show-labels --watch -o=wide
alias ksysgposlwowide = kubectl --namespace=kube-system get pods --show-labels --watch -o=wide
alias kgdepslwowide = kubectl get deployment --show-labels --watch -o=wide
alias ksysgdepslwowide = kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide
alias kgstsslwowide = kubectl get statefulset --show-labels --watch -o=wide
alias ksysgstsslwowide = kubectl --namespace=kube-system get statefulset --show-labels --watch -o=wide
alias kgsvcslwowide = kubectl get service --show-labels --watch -o=wide
alias ksysgsvcslwowide = kubectl --namespace=kube-system get service --show-labels --watch -o=wide
alias kgingslwowide = kubectl get ingress --show-labels --watch -o=wide
alias ksysgingslwowide = kubectl --namespace=kube-system get ingress --show-labels --watch -o=wide
alias kgcmslwowide = kubectl get configmap --show-labels --watch -o=wide
alias ksysgcmslwowide = kubectl --namespace=kube-system get configmap --show-labels --watch -o=wide
alias kgsecslwowide = kubectl get secret --show-labels --watch -o=wide
alias ksysgsecslwowide = kubectl --namespace=kube-system get secret --show-labels --watch -o=wide
alias kgnoslwowide = kubectl get nodes --show-labels --watch -o=wide
alias kgnsslwowide = kubectl get namespaces --show-labels --watch -o=wide
alias kgwowidesl = kubectl get --watch -o=wide --show-labels
alias ksysgwowidesl = kubectl --namespace=kube-system get --watch -o=wide --show-labels
alias kgpowowidesl = kubectl get pods --watch -o=wide --show-labels
alias ksysgpowowidesl = kubectl --namespace=kube-system get pods --watch -o=wide --show-labels
alias kgdepwowidesl = kubectl get deployment --watch -o=wide --show-labels
alias ksysgdepwowidesl = kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels
alias kgstswowidesl = kubectl get statefulset --watch -o=wide --show-labels
alias ksysgstswowidesl = kubectl --namespace=kube-system get statefulset --watch -o=wide --show-labels
alias kgsvcwowidesl = kubectl get service --watch -o=wide --show-labels
alias ksysgsvcwowidesl = kubectl --namespace=kube-system get service --watch -o=wide --show-labels
alias kgingwowidesl = kubectl get ingress --watch -o=wide --show-labels
alias ksysgingwowidesl = kubectl --namespace=kube-system get ingress --watch -o=wide --show-labels
alias kgcmwowidesl = kubectl get configmap --watch -o=wide --show-labels
alias ksysgcmwowidesl = kubectl --namespace=kube-system get configmap --watch -o=wide --show-labels
alias kgsecwowidesl = kubectl get secret --watch -o=wide --show-labels
alias ksysgsecwowidesl = kubectl --namespace=kube-system get secret --watch -o=wide --show-labels
alias kgnowowidesl = kubectl get nodes --watch -o=wide --show-labels
alias kgnswowidesl = kubectl get namespaces --watch -o=wide --show-labels
alias kgwslowide = kubectl get --watch --show-labels -o=wide
alias ksysgwslowide = kubectl --namespace=kube-system get --watch --show-labels -o=wide
alias kgpowslowide = kubectl get pods --watch --show-labels -o=wide
alias ksysgpowslowide = kubectl --namespace=kube-system get pods --watch --show-labels -o=wide
alias kgdepwslowide = kubectl get deployment --watch --show-labels -o=wide
alias ksysgdepwslowide = kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide
alias kgstswslowide = kubectl get statefulset --watch --show-labels -o=wide
alias ksysgstswslowide = kubectl --namespace=kube-system get statefulset --watch --show-labels -o=wide
alias kgsvcwslowide = kubectl get service --watch --show-labels -o=wide
alias ksysgsvcwslowide = kubectl --namespace=kube-system get service --watch --show-labels -o=wide
alias kgingwslowide = kubectl get ingress --watch --show-labels -o=wide
alias ksysgingwslowide = kubectl --namespace=kube-system get ingress --watch --show-labels -o=wide
alias kgcmwslowide = kubectl get configmap --watch --show-labels -o=wide
alias ksysgcmwslowide = kubectl --namespace=kube-system get configmap --watch --show-labels -o=wide
alias kgsecwslowide = kubectl get secret --watch --show-labels -o=wide
alias ksysgsecwslowide = kubectl --namespace=kube-system get secret --watch --show-labels -o=wide
alias kgnowslowide = kubectl get nodes --watch --show-labels -o=wide
alias kgnswslowide = kubectl get namespaces --watch --show-labels -o=wide
alias kgallwojson = kubectl get --all-namespaces --watch -o=json
alias kgpoallwojson = kubectl get pods --all-namespaces --watch -o=json
alias kgdepallwojson = kubectl get deployment --all-namespaces --watch -o=json
alias kgstsallwojson = kubectl get statefulset --all-namespaces --watch -o=json
alias kgsvcallwojson = kubectl get service --all-namespaces --watch -o=json
alias kgingallwojson = kubectl get ingress --all-namespaces --watch -o=json
alias kgcmallwojson = kubectl get configmap --all-namespaces --watch -o=json
alias kgsecallwojson = kubectl get secret --all-namespaces --watch -o=json
alias kgnsallwojson = kubectl get namespaces --all-namespaces --watch -o=json
alias kgwojsonall = kubectl get --watch -o=json --all-namespaces
alias kgpowojsonall = kubectl get pods --watch -o=json --all-namespaces
alias kgdepwojsonall = kubectl get deployment --watch -o=json --all-namespaces
alias kgstswojsonall = kubectl get statefulset --watch -o=json --all-namespaces
alias kgsvcwojsonall = kubectl get service --watch -o=json --all-namespaces
alias kgingwojsonall = kubectl get ingress --watch -o=json --all-namespaces
alias kgcmwojsonall = kubectl get configmap --watch -o=json --all-namespaces
alias kgsecwojsonall = kubectl get secret --watch -o=json --all-namespaces
alias kgnswojsonall = kubectl get namespaces --watch -o=json --all-namespaces
alias kgwallojson = kubectl get --watch --all-namespaces -o=json
alias kgpowallojson = kubectl get pods --watch --all-namespaces -o=json
alias kgdepwallojson = kubectl get deployment --watch --all-namespaces -o=json
alias kgstswallojson = kubectl get statefulset --watch --all-namespaces -o=json
alias kgsvcwallojson = kubectl get service --watch --all-namespaces -o=json
alias kgingwallojson = kubectl get ingress --watch --all-namespaces -o=json
alias kgcmwallojson = kubectl get configmap --watch --all-namespaces -o=json
alias kgsecwallojson = kubectl get secret --watch --all-namespaces -o=json
alias kgnswallojson = kubectl get namespaces --watch --all-namespaces -o=json
alias kgallslw = kubectl get --all-namespaces --show-labels --watch
alias kgpoallslw = kubectl get pods --all-namespaces --show-labels --watch
alias kgdepallslw = kubectl get deployment --all-namespaces --show-labels --watch
alias kgstsallslw = kubectl get statefulset --all-namespaces --show-labels --watch
alias kgsvcallslw = kubectl get service --all-namespaces --show-labels --watch
alias kgingallslw = kubectl get ingress --all-namespaces --show-labels --watch
alias kgcmallslw = kubectl get configmap --all-namespaces --show-labels --watch
alias kgsecallslw = kubectl get secret --all-namespaces --show-labels --watch
alias kgnsallslw = kubectl get namespaces --all-namespaces --show-labels --watch
alias kgallwsl = kubectl get --all-namespaces --watch --show-labels
alias kgpoallwsl = kubectl get pods --all-namespaces --watch --show-labels
alias kgdepallwsl = kubectl get deployment --all-namespaces --watch --show-labels
alias kgstsallwsl = kubectl get statefulset --all-namespaces --watch --show-labels
alias kgsvcallwsl = kubectl get service --all-namespaces --watch --show-labels
alias kgingallwsl = kubectl get ingress --all-namespaces --watch --show-labels
alias kgcmallwsl = kubectl get configmap --all-namespaces --watch --show-labels
alias kgsecallwsl = kubectl get secret --all-namespaces --watch --show-labels
alias kgnsallwsl = kubectl get namespaces --all-namespaces --watch --show-labels
alias kgslallw = kubectl get --show-labels --all-namespaces --watch
alias kgposlallw = kubectl get pods --show-labels --all-namespaces --watch
alias kgdepslallw = kubectl get deployment --show-labels --all-namespaces --watch
alias kgstsslallw = kubectl get statefulset --show-labels --all-namespaces --watch
alias kgsvcslallw = kubectl get service --show-labels --all-namespaces --watch
alias kgingslallw = kubectl get ingress --show-labels --all-namespaces --watch
alias kgcmslallw = kubectl get configmap --show-labels --all-namespaces --watch
alias kgsecslallw = kubectl get secret --show-labels --all-namespaces --watch
alias kgnsslallw = kubectl get namespaces --show-labels --all-namespaces --watch
alias kgslwall = kubectl get --show-labels --watch --all-namespaces
alias kgposlwall = kubectl get pods --show-labels --watch --all-namespaces
alias kgdepslwall = kubectl get deployment --show-labels --watch --all-namespaces
alias kgstsslwall = kubectl get statefulset --show-labels --watch --all-namespaces
alias kgsvcslwall = kubectl get service --show-labels --watch --all-namespaces
alias kgingslwall = kubectl get ingress --show-labels --watch --all-namespaces
alias kgcmslwall = kubectl get configmap --show-labels --watch --all-namespaces
alias kgsecslwall = kubectl get secret --show-labels --watch --all-namespaces
alias kgnsslwall = kubectl get namespaces --show-labels --watch --all-namespaces
alias kgwallsl = kubectl get --watch --all-namespaces --show-labels
alias kgpowallsl = kubectl get pods --watch --all-namespaces --show-labels
alias kgdepwallsl = kubectl get deployment --watch --all-namespaces --show-labels
alias kgstswallsl = kubectl get statefulset --watch --all-namespaces --show-labels
alias kgsvcwallsl = kubectl get service --watch --all-namespaces --show-labels
alias kgingwallsl = kubectl get ingress --watch --all-namespaces --show-labels
alias kgcmwallsl = kubectl get configmap --watch --all-namespaces --show-labels
alias kgsecwallsl = kubectl get secret --watch --all-namespaces --show-labels
alias kgnswallsl = kubectl get namespaces --watch --all-namespaces --show-labels
alias kgwslall = kubectl get --watch --show-labels --all-namespaces
alias kgpowslall = kubectl get pods --watch --show-labels --all-namespaces
alias kgdepwslall = kubectl get deployment --watch --show-labels --all-namespaces
alias kgstswslall = kubectl get statefulset --watch --show-labels --all-namespaces
alias kgsvcwslall = kubectl get service --watch --show-labels --all-namespaces
alias kgingwslall = kubectl get ingress --watch --show-labels --all-namespaces
alias kgcmwslall = kubectl get configmap --watch --show-labels --all-namespaces
alias kgsecwslall = kubectl get secret --watch --show-labels --all-namespaces
alias kgnswslall = kubectl get namespaces --watch --show-labels --all-namespaces
alias kgallslwowide = kubectl get --all-namespaces --show-labels --watch -o=wide
alias kgpoallslwowide = kubectl get pods --all-namespaces --show-labels --watch -o=wide
alias kgdepallslwowide = kubectl get deployment --all-namespaces --show-labels --watch -o=wide
alias kgstsallslwowide = kubectl get statefulset --all-namespaces --show-labels --watch -o=wide
alias kgsvcallslwowide = kubectl get service --all-namespaces --show-labels --watch -o=wide
alias kgingallslwowide = kubectl get ingress --all-namespaces --show-labels --watch -o=wide
alias kgcmallslwowide = kubectl get configmap --all-namespaces --show-labels --watch -o=wide
alias kgsecallslwowide = kubectl get secret --all-namespaces --show-labels --watch -o=wide
alias kgnsallslwowide = kubectl get namespaces --all-namespaces --show-labels --watch -o=wide
alias kgallwowidesl = kubectl get --all-namespaces --watch -o=wide --show-labels
alias kgpoallwowidesl = kubectl get pods --all-namespaces --watch -o=wide --show-labels
alias kgdepallwowidesl = kubectl get deployment --all-namespaces --watch -o=wide --show-labels
alias kgstsallwowidesl = kubectl get statefulset --all-namespaces --watch -o=wide --show-labels
alias kgsvcallwowidesl = kubectl get service --all-namespaces --watch -o=wide --show-labels
alias kgingallwowidesl = kubectl get ingress --all-namespaces --watch -o=wide --show-labels
alias kgcmallwowidesl = kubectl get configmap --all-namespaces --watch -o=wide --show-labels
alias kgsecallwowidesl = kubectl get secret --all-namespaces --watch -o=wide --show-labels
alias kgnsallwowidesl = kubectl get namespaces --all-namespaces --watch -o=wide --show-labels
alias kgallwslowide = kubectl get --all-namespaces --watch --show-labels -o=wide
alias kgpoallwslowide = kubectl get pods --all-namespaces --watch --show-labels -o=wide
alias kgdepallwslowide = kubectl get deployment --all-namespaces --watch --show-labels -o=wide
alias kgstsallwslowide = kubectl get statefulset --all-namespaces --watch --show-labels -o=wide
alias kgsvcallwslowide = kubectl get service --all-namespaces --watch --show-labels -o=wide
alias kgingallwslowide = kubectl get ingress --all-namespaces --watch --show-labels -o=wide
alias kgcmallwslowide = kubectl get configmap --all-namespaces --watch --show-labels -o=wide
alias kgsecallwslowide = kubectl get secret --all-namespaces --watch --show-labels -o=wide
alias kgnsallwslowide = kubectl get namespaces --all-namespaces --watch --show-labels -o=wide
alias kgslallwowide = kubectl get --show-labels --all-namespaces --watch -o=wide
alias kgposlallwowide = kubectl get pods --show-labels --all-namespaces --watch -o=wide
alias kgdepslallwowide = kubectl get deployment --show-labels --all-namespaces --watch -o=wide
alias kgstsslallwowide = kubectl get statefulset --show-labels --all-namespaces --watch -o=wide
alias kgsvcslallwowide = kubectl get service --show-labels --all-namespaces --watch -o=wide
alias kgingslallwowide = kubectl get ingress --show-labels --all-namespaces --watch -o=wide
alias kgcmslallwowide = kubectl get configmap --show-labels --all-namespaces --watch -o=wide
alias kgsecslallwowide = kubectl get secret --show-labels --all-namespaces --watch -o=wide
alias kgnsslallwowide = kubectl get namespaces --show-labels --all-namespaces --watch -o=wide
alias kgslwowideall = kubectl get --show-labels --watch -o=wide --all-namespaces
alias kgposlwowideall = kubectl get pods --show-labels --watch -o=wide --all-namespaces
alias kgdepslwowideall = kubectl get deployment --show-labels --watch -o=wide --all-namespaces
alias kgstsslwowideall = kubectl get statefulset --show-labels --watch -o=wide --all-namespaces
alias kgsvcslwowideall = kubectl get service --show-labels --watch -o=wide --all-namespaces
alias kgingslwowideall = kubectl get ingress --show-labels --watch -o=wide --all-namespaces
alias kgcmslwowideall = kubectl get configmap --show-labels --watch -o=wide --all-namespaces
alias kgsecslwowideall = kubectl get secret --show-labels --watch -o=wide --all-namespaces
alias kgnsslwowideall = kubectl get namespaces --show-labels --watch -o=wide --all-namespaces
alias kgslwallowide = kubectl get --show-labels --watch --all-namespaces -o=wide
alias kgposlwallowide = kubectl get pods --show-labels --watch --all-namespaces -o=wide
alias kgdepslwallowide = kubectl get deployment --show-labels --watch --all-namespaces -o=wide
alias kgstsslwallowide = kubectl get statefulset --show-labels --watch --all-namespaces -o=wide
alias kgsvcslwallowide = kubectl get service --show-labels --watch --all-namespaces -o=wide
alias kgingslwallowide = kubectl get ingress --show-labels --watch --all-namespaces -o=wide
alias kgcmslwallowide = kubectl get configmap --show-labels --watch --all-namespaces -o=wide
alias kgsecslwallowide = kubectl get secret --show-labels --watch --all-namespaces -o=wide
alias kgnsslwallowide = kubectl get namespaces --show-labels --watch --all-namespaces -o=wide
alias kgwowideallsl = kubectl get --watch -o=wide --all-namespaces --show-labels
alias kgpowowideallsl = kubectl get pods --watch -o=wide --all-namespaces --show-labels
alias kgdepwowideallsl = kubectl get deployment --watch -o=wide --all-namespaces --show-labels
alias kgstswowideallsl = kubectl get statefulset --watch -o=wide --all-namespaces --show-labels
alias kgsvcwowideallsl = kubectl get service --watch -o=wide --all-namespaces --show-labels
alias kgingwowideallsl = kubectl get ingress --watch -o=wide --all-namespaces --show-labels
alias kgcmwowideallsl = kubectl get configmap --watch -o=wide --all-namespaces --show-labels
alias kgsecwowideallsl = kubectl get secret --watch -o=wide --all-namespaces --show-labels
alias kgnswowideallsl = kubectl get namespaces --watch -o=wide --all-namespaces --show-labels
alias kgwowideslall = kubectl get --watch -o=wide --show-labels --all-namespaces
alias kgpowowideslall = kubectl get pods --watch -o=wide --show-labels --all-namespaces
alias kgdepwowideslall = kubectl get deployment --watch -o=wide --show-labels --all-namespaces
alias kgstswowideslall = kubectl get statefulset --watch -o=wide --show-labels --all-namespaces
alias kgsvcwowideslall = kubectl get service --watch -o=wide --show-labels --all-namespaces
alias kgingwowideslall = kubectl get ingress --watch -o=wide --show-labels --all-namespaces
alias kgcmwowideslall = kubectl get configmap --watch -o=wide --show-labels --all-namespaces
alias kgsecwowideslall = kubectl get secret --watch -o=wide --show-labels --all-namespaces
alias kgnswowideslall = kubectl get namespaces --watch -o=wide --show-labels --all-namespaces
alias kgwallowidesl = kubectl get --watch --all-namespaces -o=wide --show-labels
alias kgpowallowidesl = kubectl get pods --watch --all-namespaces -o=wide --show-labels
alias kgdepwallowidesl = kubectl get deployment --watch --all-namespaces -o=wide --show-labels
alias kgstswallowidesl = kubectl get statefulset --watch --all-namespaces -o=wide --show-labels
alias kgsvcwallowidesl = kubectl get service --watch --all-namespaces -o=wide --show-labels
alias kgingwallowidesl = kubectl get ingress --watch --all-namespaces -o=wide --show-labels
alias kgcmwallowidesl = kubectl get configmap --watch --all-namespaces -o=wide --show-labels
alias kgsecwallowidesl = kubectl get secret --watch --all-namespaces -o=wide --show-labels
alias kgnswallowidesl = kubectl get namespaces --watch --all-namespaces -o=wide --show-labels
alias kgwallslowide = kubectl get --watch --all-namespaces --show-labels -o=wide
alias kgpowallslowide = kubectl get pods --watch --all-namespaces --show-labels -o=wide
alias kgdepwallslowide = kubectl get deployment --watch --all-namespaces --show-labels -o=wide
alias kgstswallslowide = kubectl get statefulset --watch --all-namespaces --show-labels -o=wide
alias kgsvcwallslowide = kubectl get service --watch --all-namespaces --show-labels -o=wide
alias kgingwallslowide = kubectl get ingress --watch --all-namespaces --show-labels -o=wide
alias kgcmwallslowide = kubectl get configmap --watch --all-namespaces --show-labels -o=wide
alias kgsecwallslowide = kubectl get secret --watch --all-namespaces --show-labels -o=wide
alias kgnswallslowide = kubectl get namespaces --watch --all-namespaces --show-labels -o=wide
alias kgwslowideall = kubectl get --watch --show-labels -o=wide --all-namespaces
alias kgpowslowideall = kubectl get pods --watch --show-labels -o=wide --all-namespaces
alias kgdepwslowideall = kubectl get deployment --watch --show-labels -o=wide --all-namespaces
alias kgstswslowideall = kubectl get statefulset --watch --show-labels -o=wide --all-namespaces
alias kgsvcwslowideall = kubectl get service --watch --show-labels -o=wide --all-namespaces
alias kgingwslowideall = kubectl get ingress --watch --show-labels -o=wide --all-namespaces
alias kgcmwslowideall = kubectl get configmap --watch --show-labels -o=wide --all-namespaces
alias kgsecwslowideall = kubectl get secret --watch --show-labels -o=wide --all-namespaces
alias kgnswslowideall = kubectl get namespaces --watch --show-labels -o=wide --all-namespaces
alias kgwslallowide = kubectl get --watch --show-labels --all-namespaces -o=wide
alias kgpowslallowide = kubectl get pods --watch --show-labels --all-namespaces -o=wide
alias kgdepwslallowide = kubectl get deployment --watch --show-labels --all-namespaces -o=wide
alias kgstswslallowide = kubectl get statefulset --watch --show-labels --all-namespaces -o=wide
alias kgsvcwslallowide = kubectl get service --watch --show-labels --all-namespaces -o=wide
alias kgingwslallowide = kubectl get ingress --watch --show-labels --all-namespaces -o=wide
alias kgcmwslallowide = kubectl get configmap --watch --show-labels --all-namespaces -o=wide
alias kgsecwslallowide = kubectl get secret --watch --show-labels --all-namespaces -o=wide
alias kgnswslallowide = kubectl get namespaces --watch --show-labels --all-namespaces -o=wide
alias kgf = kubectl get --recursive -f
alias kdf = kubectl describe --recursive -f
alias krmf = kubectl delete --recursive -f
alias kgoyamlf = kubectl get -o=yaml --recursive -f
alias kgowidef = kubectl get -o=wide --recursive -f
alias kgojsonf = kubectl get -o=json --recursive -f
alias kgslf = kubectl get --show-labels --recursive -f
alias kgwf = kubectl get --watch --recursive -f
alias kgwoyamlf = kubectl get --watch -o=yaml --recursive -f
alias kgowideslf = kubectl get -o=wide --show-labels --recursive -f
alias kgslowidef = kubectl get --show-labels -o=wide --recursive -f
alias kgwowidef = kubectl get --watch -o=wide --recursive -f
alias kgwojsonf = kubectl get --watch -o=json --recursive -f
alias kgslwf = kubectl get --show-labels --watch --recursive -f
alias kgwslf = kubectl get --watch --show-labels --recursive -f
alias kgslwowidef = kubectl get --show-labels --watch -o=wide --recursive -f
alias kgwowideslf = kubectl get --watch -o=wide --show-labels --recursive -f
alias kgwslowidef = kubectl get --watch --show-labels -o=wide --recursive -f
alias kgl = kubectl get -l
alias ksysgl = kubectl --namespace=kube-system get -l
alias kdl = kubectl describe -l
alias ksysdl = kubectl --namespace=kube-system describe -l
alias krml = kubectl delete -l
alias ksysrml = kubectl --namespace=kube-system delete -l
alias kgpol = kubectl get pods -l
alias ksysgpol = kubectl --namespace=kube-system get pods -l
alias kdpol = kubectl describe pods -l
alias ksysdpol = kubectl --namespace=kube-system describe pods -l
alias krmpol = kubectl delete pods -l
alias ksysrmpol = kubectl --namespace=kube-system delete pods -l
alias kgdepl = kubectl get deployment -l
alias ksysgdepl = kubectl --namespace=kube-system get deployment -l
alias kddepl = kubectl describe deployment -l
alias ksysddepl = kubectl --namespace=kube-system describe deployment -l
alias krmdepl = kubectl delete deployment -l
alias ksysrmdepl = kubectl --namespace=kube-system delete deployment -l
alias kgstsl = kubectl get statefulset -l
alias ksysgstsl = kubectl --namespace=kube-system get statefulset -l
alias kdstsl = kubectl describe statefulset -l
alias ksysdstsl = kubectl --namespace=kube-system describe statefulset -l
alias krmstsl = kubectl delete statefulset -l
alias ksysrmstsl = kubectl --namespace=kube-system delete statefulset -l
alias kgsvcl = kubectl get service -l
alias ksysgsvcl = kubectl --namespace=kube-system get service -l
alias kdsvcl = kubectl describe service -l
alias ksysdsvcl = kubectl --namespace=kube-system describe service -l
alias krmsvcl = kubectl delete service -l
alias ksysrmsvcl = kubectl --namespace=kube-system delete service -l
alias kgingl = kubectl get ingress -l
alias ksysgingl = kubectl --namespace=kube-system get ingress -l
alias kdingl = kubectl describe ingress -l
alias ksysdingl = kubectl --namespace=kube-system describe ingress -l
alias krmingl = kubectl delete ingress -l
alias ksysrmingl = kubectl --namespace=kube-system delete ingress -l
alias kgcml = kubectl get configmap -l
alias ksysgcml = kubectl --namespace=kube-system get configmap -l
alias kdcml = kubectl describe configmap -l
alias ksysdcml = kubectl --namespace=kube-system describe configmap -l
alias krmcml = kubectl delete configmap -l
alias ksysrmcml = kubectl --namespace=kube-system delete configmap -l
alias kgsecl = kubectl get secret -l
alias ksysgsecl = kubectl --namespace=kube-system get secret -l
alias kdsecl = kubectl describe secret -l
alias ksysdsecl = kubectl --namespace=kube-system describe secret -l
alias krmsecl = kubectl delete secret -l
alias ksysrmsecl = kubectl --namespace=kube-system delete secret -l
alias kgnol = kubectl get nodes -l
alias kdnol = kubectl describe nodes -l
alias kgnsl = kubectl get namespaces -l
alias kdnsl = kubectl describe namespaces -l
alias krmnsl = kubectl delete namespaces -l
alias kgoyamll = kubectl get -o=yaml -l
alias ksysgoyamll = kubectl --namespace=kube-system get -o=yaml -l
alias kgpooyamll = kubectl get pods -o=yaml -l
alias ksysgpooyamll = kubectl --namespace=kube-system get pods -o=yaml -l
alias kgdepoyamll = kubectl get deployment -o=yaml -l
alias ksysgdepoyamll = kubectl --namespace=kube-system get deployment -o=yaml -l
alias kgstsoyamll = kubectl get statefulset -o=yaml -l
alias ksysgstsoyamll = kubectl --namespace=kube-system get statefulset -o=yaml -l
alias kgsvcoyamll = kubectl get service -o=yaml -l
alias ksysgsvcoyamll = kubectl --namespace=kube-system get service -o=yaml -l
alias kgingoyamll = kubectl get ingress -o=yaml -l
alias ksysgingoyamll = kubectl --namespace=kube-system get ingress -o=yaml -l
alias kgcmoyamll = kubectl get configmap -o=yaml -l
alias ksysgcmoyamll = kubectl --namespace=kube-system get configmap -o=yaml -l
alias kgsecoyamll = kubectl get secret -o=yaml -l
alias ksysgsecoyamll = kubectl --namespace=kube-system get secret -o=yaml -l
alias kgnooyamll = kubectl get nodes -o=yaml -l
alias kgnsoyamll = kubectl get namespaces -o=yaml -l
alias kgowidel = kubectl get -o=wide -l
alias ksysgowidel = kubectl --namespace=kube-system get -o=wide -l
alias kgpoowidel = kubectl get pods -o=wide -l
alias ksysgpoowidel = kubectl --namespace=kube-system get pods -o=wide -l
alias kgdepowidel = kubectl get deployment -o=wide -l
alias ksysgdepowidel = kubectl --namespace=kube-system get deployment -o=wide -l
alias kgstsowidel = kubectl get statefulset -o=wide -l
alias ksysgstsowidel = kubectl --namespace=kube-system get statefulset -o=wide -l
alias kgsvcowidel = kubectl get service -o=wide -l
alias ksysgsvcowidel = kubectl --namespace=kube-system get service -o=wide -l
alias kgingowidel = kubectl get ingress -o=wide -l
alias ksysgingowidel = kubectl --namespace=kube-system get ingress -o=wide -l
alias kgcmowidel = kubectl get configmap -o=wide -l
alias ksysgcmowidel = kubectl --namespace=kube-system get configmap -o=wide -l
alias kgsecowidel = kubectl get secret -o=wide -l
alias ksysgsecowidel = kubectl --namespace=kube-system get secret -o=wide -l
alias kgnoowidel = kubectl get nodes -o=wide -l
alias kgnsowidel = kubectl get namespaces -o=wide -l
alias kgojsonl = kubectl get -o=json -l
alias ksysgojsonl = kubectl --namespace=kube-system get -o=json -l
alias kgpoojsonl = kubectl get pods -o=json -l
alias ksysgpoojsonl = kubectl --namespace=kube-system get pods -o=json -l
alias kgdepojsonl = kubectl get deployment -o=json -l
alias ksysgdepojsonl = kubectl --namespace=kube-system get deployment -o=json -l
alias kgstsojsonl = kubectl get statefulset -o=json -l
alias ksysgstsojsonl = kubectl --namespace=kube-system get statefulset -o=json -l
alias kgsvcojsonl = kubectl get service -o=json -l
alias ksysgsvcojsonl = kubectl --namespace=kube-system get service -o=json -l
alias kgingojsonl = kubectl get ingress -o=json -l
alias ksysgingojsonl = kubectl --namespace=kube-system get ingress -o=json -l
alias kgcmojsonl = kubectl get configmap -o=json -l
alias ksysgcmojsonl = kubectl --namespace=kube-system get configmap -o=json -l
alias kgsecojsonl = kubectl get secret -o=json -l
alias ksysgsecojsonl = kubectl --namespace=kube-system get secret -o=json -l
alias kgnoojsonl = kubectl get nodes -o=json -l
alias kgnsojsonl = kubectl get namespaces -o=json -l
alias kgsll = kubectl get --show-labels -l
alias ksysgsll = kubectl --namespace=kube-system get --show-labels -l
alias kgposll = kubectl get pods --show-labels -l
alias ksysgposll = kubectl --namespace=kube-system get pods --show-labels -l
alias kgdepsll = kubectl get deployment --show-labels -l
alias ksysgdepsll = kubectl --namespace=kube-system get deployment --show-labels -l
alias kgstssll = kubectl get statefulset --show-labels -l
alias ksysgstssll = kubectl --namespace=kube-system get statefulset --show-labels -l
alias kgsvcsll = kubectl get service --show-labels -l
alias ksysgsvcsll = kubectl --namespace=kube-system get service --show-labels -l
alias kgingsll = kubectl get ingress --show-labels -l
alias ksysgingsll = kubectl --namespace=kube-system get ingress --show-labels -l
alias kgcmsll = kubectl get configmap --show-labels -l
alias ksysgcmsll = kubectl --namespace=kube-system get configmap --show-labels -l
alias kgsecsll = kubectl get secret --show-labels -l
alias ksysgsecsll = kubectl --namespace=kube-system get secret --show-labels -l
alias kgnosll = kubectl get nodes --show-labels -l
alias kgnssll = kubectl get namespaces --show-labels -l
alias kgwl = kubectl get --watch -l
alias ksysgwl = kubectl --namespace=kube-system get --watch -l
alias kgpowl = kubectl get pods --watch -l
alias ksysgpowl = kubectl --namespace=kube-system get pods --watch -l
alias kgdepwl = kubectl get deployment --watch -l
alias ksysgdepwl = kubectl --namespace=kube-system get deployment --watch -l
alias kgstswl = kubectl get statefulset --watch -l
alias ksysgstswl = kubectl --namespace=kube-system get statefulset --watch -l
alias kgsvcwl = kubectl get service --watch -l
alias ksysgsvcwl = kubectl --namespace=kube-system get service --watch -l
alias kgingwl = kubectl get ingress --watch -l
alias ksysgingwl = kubectl --namespace=kube-system get ingress --watch -l
alias kgcmwl = kubectl get configmap --watch -l
alias ksysgcmwl = kubectl --namespace=kube-system get configmap --watch -l
alias kgsecwl = kubectl get secret --watch -l
alias ksysgsecwl = kubectl --namespace=kube-system get secret --watch -l
alias kgnowl = kubectl get nodes --watch -l
alias kgnswl = kubectl get namespaces --watch -l
alias kgwoyamll = kubectl get --watch -o=yaml -l
alias ksysgwoyamll = kubectl --namespace=kube-system get --watch -o=yaml -l
alias kgpowoyamll = kubectl get pods --watch -o=yaml -l
alias ksysgpowoyamll = kubectl --namespace=kube-system get pods --watch -o=yaml -l
alias kgdepwoyamll = kubectl get deployment --watch -o=yaml -l
alias ksysgdepwoyamll = kubectl --namespace=kube-system get deployment --watch -o=yaml -l
alias kgstswoyamll = kubectl get statefulset --watch -o=yaml -l
alias ksysgstswoyamll = kubectl --namespace=kube-system get statefulset --watch -o=yaml -l
alias kgsvcwoyamll = kubectl get service --watch -o=yaml -l
alias ksysgsvcwoyamll = kubectl --namespace=kube-system get service --watch -o=yaml -l
alias kgingwoyamll = kubectl get ingress --watch -o=yaml -l
alias ksysgingwoyamll = kubectl --namespace=kube-system get ingress --watch -o=yaml -l
alias kgcmwoyamll = kubectl get configmap --watch -o=yaml -l
alias ksysgcmwoyamll = kubectl --namespace=kube-system get configmap --watch -o=yaml -l
alias kgsecwoyamll = kubectl get secret --watch -o=yaml -l
alias ksysgsecwoyamll = kubectl --namespace=kube-system get secret --watch -o=yaml -l
alias kgnowoyamll = kubectl get nodes --watch -o=yaml -l
alias kgnswoyamll = kubectl get namespaces --watch -o=yaml -l
alias kgowidesll = kubectl get -o=wide --show-labels -l
alias ksysgowidesll = kubectl --namespace=kube-system get -o=wide --show-labels -l
alias kgpoowidesll = kubectl get pods -o=wide --show-labels -l
alias ksysgpoowidesll = kubectl --namespace=kube-system get pods -o=wide --show-labels -l
alias kgdepowidesll = kubectl get deployment -o=wide --show-labels -l
alias ksysgdepowidesll = kubectl --namespace=kube-system get deployment -o=wide --show-labels -l
alias kgstsowidesll = kubectl get statefulset -o=wide --show-labels -l
alias ksysgstsowidesll = kubectl --namespace=kube-system get statefulset -o=wide --show-labels -l
alias kgsvcowidesll = kubectl get service -o=wide --show-labels -l
alias ksysgsvcowidesll = kubectl --namespace=kube-system get service -o=wide --show-labels -l
alias kgingowidesll = kubectl get ingress -o=wide --show-labels -l
alias ksysgingowidesll = kubectl --namespace=kube-system get ingress -o=wide --show-labels -l
alias kgcmowidesll = kubectl get configmap -o=wide --show-labels -l
alias ksysgcmowidesll = kubectl --namespace=kube-system get configmap -o=wide --show-labels -l
alias kgsecowidesll = kubectl get secret -o=wide --show-labels -l
alias ksysgsecowidesll = kubectl --namespace=kube-system get secret -o=wide --show-labels -l
alias kgnoowidesll = kubectl get nodes -o=wide --show-labels -l
alias kgnsowidesll = kubectl get namespaces -o=wide --show-labels -l
alias kgslowidel = kubectl get --show-labels -o=wide -l
alias ksysgslowidel = kubectl --namespace=kube-system get --show-labels -o=wide -l
alias kgposlowidel = kubectl get pods --show-labels -o=wide -l
alias ksysgposlowidel = kubectl --namespace=kube-system get pods --show-labels -o=wide -l
alias kgdepslowidel = kubectl get deployment --show-labels -o=wide -l
alias ksysgdepslowidel = kubectl --namespace=kube-system get deployment --show-labels -o=wide -l
alias kgstsslowidel = kubectl get statefulset --show-labels -o=wide -l
alias ksysgstsslowidel = kubectl --namespace=kube-system get statefulset --show-labels -o=wide -l
alias kgsvcslowidel = kubectl get service --show-labels -o=wide -l
alias ksysgsvcslowidel = kubectl --namespace=kube-system get service --show-labels -o=wide -l
alias kgingslowidel = kubectl get ingress --show-labels -o=wide -l
alias ksysgingslowidel = kubectl --namespace=kube-system get ingress --show-labels -o=wide -l
alias kgcmslowidel = kubectl get configmap --show-labels -o=wide -l
alias ksysgcmslowidel = kubectl --namespace=kube-system get configmap --show-labels -o=wide -l
alias kgsecslowidel = kubectl get secret --show-labels -o=wide -l
alias ksysgsecslowidel = kubectl --namespace=kube-system get secret --show-labels -o=wide -l
alias kgnoslowidel = kubectl get nodes --show-labels -o=wide -l
alias kgnsslowidel = kubectl get namespaces --show-labels -o=wide -l
alias kgwowidel = kubectl get --watch -o=wide -l
alias ksysgwowidel = kubectl --namespace=kube-system get --watch -o=wide -l
alias kgpowowidel = kubectl get pods --watch -o=wide -l
alias ksysgpowowidel = kubectl --namespace=kube-system get pods --watch -o=wide -l
alias kgdepwowidel = kubectl get deployment --watch -o=wide -l
alias ksysgdepwowidel = kubectl --namespace=kube-system get deployment --watch -o=wide -l
alias kgstswowidel = kubectl get statefulset --watch -o=wide -l
alias ksysgstswowidel = kubectl --namespace=kube-system get statefulset --watch -o=wide -l
alias kgsvcwowidel = kubectl get service --watch -o=wide -l
alias ksysgsvcwowidel = kubectl --namespace=kube-system get service --watch -o=wide -l
alias kgingwowidel = kubectl get ingress --watch -o=wide -l
alias ksysgingwowidel = kubectl --namespace=kube-system get ingress --watch -o=wide -l
alias kgcmwowidel = kubectl get configmap --watch -o=wide -l
alias ksysgcmwowidel = kubectl --namespace=kube-system get configmap --watch -o=wide -l
alias kgsecwowidel = kubectl get secret --watch -o=wide -l
alias ksysgsecwowidel = kubectl --namespace=kube-system get secret --watch -o=wide -l
alias kgnowowidel = kubectl get nodes --watch -o=wide -l
alias kgnswowidel = kubectl get namespaces --watch -o=wide -l
alias kgwojsonl = kubectl get --watch -o=json -l
alias ksysgwojsonl = kubectl --namespace=kube-system get --watch -o=json -l
alias kgpowojsonl = kubectl get pods --watch -o=json -l
alias ksysgpowojsonl = kubectl --namespace=kube-system get pods --watch -o=json -l
alias kgdepwojsonl = kubectl get deployment --watch -o=json -l
alias ksysgdepwojsonl = kubectl --namespace=kube-system get deployment --watch -o=json -l
alias kgstswojsonl = kubectl get statefulset --watch -o=json -l
alias ksysgstswojsonl = kubectl --namespace=kube-system get statefulset --watch -o=json -l
alias kgsvcwojsonl = kubectl get service --watch -o=json -l
alias ksysgsvcwojsonl = kubectl --namespace=kube-system get service --watch -o=json -l
alias kgingwojsonl = kubectl get ingress --watch -o=json -l
alias ksysgingwojsonl = kubectl --namespace=kube-system get ingress --watch -o=json -l
alias kgcmwojsonl = kubectl get configmap --watch -o=json -l
alias ksysgcmwojsonl = kubectl --namespace=kube-system get configmap --watch -o=json -l
alias kgsecwojsonl = kubectl get secret --watch -o=json -l
alias ksysgsecwojsonl = kubectl --namespace=kube-system get secret --watch -o=json -l
alias kgnowojsonl = kubectl get nodes --watch -o=json -l
alias kgnswojsonl = kubectl get namespaces --watch -o=json -l
alias kgslwl = kubectl get --show-labels --watch -l
alias ksysgslwl = kubectl --namespace=kube-system get --show-labels --watch -l
alias kgposlwl = kubectl get pods --show-labels --watch -l
alias ksysgposlwl = kubectl --namespace=kube-system get pods --show-labels --watch -l
alias kgdepslwl = kubectl get deployment --show-labels --watch -l
alias ksysgdepslwl = kubectl --namespace=kube-system get deployment --show-labels --watch -l
alias kgstsslwl = kubectl get statefulset --show-labels --watch -l
alias ksysgstsslwl = kubectl --namespace=kube-system get statefulset --show-labels --watch -l
alias kgsvcslwl = kubectl get service --show-labels --watch -l
alias ksysgsvcslwl = kubectl --namespace=kube-system get service --show-labels --watch -l
alias kgingslwl = kubectl get ingress --show-labels --watch -l
alias ksysgingslwl = kubectl --namespace=kube-system get ingress --show-labels --watch -l
alias kgcmslwl = kubectl get configmap --show-labels --watch -l
alias ksysgcmslwl = kubectl --namespace=kube-system get configmap --show-labels --watch -l
alias kgsecslwl = kubectl get secret --show-labels --watch -l
alias ksysgsecslwl = kubectl --namespace=kube-system get secret --show-labels --watch -l
alias kgnoslwl = kubectl get nodes --show-labels --watch -l
alias kgnsslwl = kubectl get namespaces --show-labels --watch -l
alias kgwsll = kubectl get --watch --show-labels -l
alias ksysgwsll = kubectl --namespace=kube-system get --watch --show-labels -l
alias kgpowsll = kubectl get pods --watch --show-labels -l
alias ksysgpowsll = kubectl --namespace=kube-system get pods --watch --show-labels -l
alias kgdepwsll = kubectl get deployment --watch --show-labels -l
alias ksysgdepwsll = kubectl --namespace=kube-system get deployment --watch --show-labels -l
alias kgstswsll = kubectl get statefulset --watch --show-labels -l
alias ksysgstswsll = kubectl --namespace=kube-system get statefulset --watch --show-labels -l
alias kgsvcwsll = kubectl get service --watch --show-labels -l
alias ksysgsvcwsll = kubectl --namespace=kube-system get service --watch --show-labels -l
alias kgingwsll = kubectl get ingress --watch --show-labels -l
alias ksysgingwsll = kubectl --namespace=kube-system get ingress --watch --show-labels -l
alias kgcmwsll = kubectl get configmap --watch --show-labels -l
alias ksysgcmwsll = kubectl --namespace=kube-system get configmap --watch --show-labels -l
alias kgsecwsll = kubectl get secret --watch --show-labels -l
alias ksysgsecwsll = kubectl --namespace=kube-system get secret --watch --show-labels -l
alias kgnowsll = kubectl get nodes --watch --show-labels -l
alias kgnswsll = kubectl get namespaces --watch --show-labels -l
alias kgslwowidel = kubectl get --show-labels --watch -o=wide -l
alias ksysgslwowidel = kubectl --namespace=kube-system get --show-labels --watch -o=wide -l
alias kgposlwowidel = kubectl get pods --show-labels --watch -o=wide -l
alias ksysgposlwowidel = kubectl --namespace=kube-system get pods --show-labels --watch -o=wide -l
alias kgdepslwowidel = kubectl get deployment --show-labels --watch -o=wide -l
alias ksysgdepslwowidel = kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide -l
alias kgstsslwowidel = kubectl get statefulset --show-labels --watch -o=wide -l
alias ksysgstsslwowidel = kubectl --namespace=kube-system get statefulset --show-labels --watch -o=wide -l
alias kgsvcslwowidel = kubectl get service --show-labels --watch -o=wide -l
alias ksysgsvcslwowidel = kubectl --namespace=kube-system get service --show-labels --watch -o=wide -l
alias kgingslwowidel = kubectl get ingress --show-labels --watch -o=wide -l
alias ksysgingslwowidel = kubectl --namespace=kube-system get ingress --show-labels --watch -o=wide -l
alias kgcmslwowidel = kubectl get configmap --show-labels --watch -o=wide -l
alias ksysgcmslwowidel = kubectl --namespace=kube-system get configmap --show-labels --watch -o=wide -l
alias kgsecslwowidel = kubectl get secret --show-labels --watch -o=wide -l
alias ksysgsecslwowidel = kubectl --namespace=kube-system get secret --show-labels --watch -o=wide -l
alias kgnoslwowidel = kubectl get nodes --show-labels --watch -o=wide -l
alias kgnsslwowidel = kubectl get namespaces --show-labels --watch -o=wide -l
alias kgwowidesll = kubectl get --watch -o=wide --show-labels -l
alias ksysgwowidesll = kubectl --namespace=kube-system get --watch -o=wide --show-labels -l
alias kgpowowidesll = kubectl get pods --watch -o=wide --show-labels -l
alias ksysgpowowidesll = kubectl --namespace=kube-system get pods --watch -o=wide --show-labels -l
alias kgdepwowidesll = kubectl get deployment --watch -o=wide --show-labels -l
alias ksysgdepwowidesll = kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels -l
alias kgstswowidesll = kubectl get statefulset --watch -o=wide --show-labels -l
alias ksysgstswowidesll = kubectl --namespace=kube-system get statefulset --watch -o=wide --show-labels -l
alias kgsvcwowidesll = kubectl get service --watch -o=wide --show-labels -l
alias ksysgsvcwowidesll = kubectl --namespace=kube-system get service --watch -o=wide --show-labels -l
alias kgingwowidesll = kubectl get ingress --watch -o=wide --show-labels -l
alias ksysgingwowidesll = kubectl --namespace=kube-system get ingress --watch -o=wide --show-labels -l
alias kgcmwowidesll = kubectl get configmap --watch -o=wide --show-labels -l
alias ksysgcmwowidesll = kubectl --namespace=kube-system get configmap --watch -o=wide --show-labels -l
alias kgsecwowidesll = kubectl get secret --watch -o=wide --show-labels -l
alias ksysgsecwowidesll = kubectl --namespace=kube-system get secret --watch -o=wide --show-labels -l
alias kgnowowidesll = kubectl get nodes --watch -o=wide --show-labels -l
alias kgnswowidesll = kubectl get namespaces --watch -o=wide --show-labels -l
alias kgwslowidel = kubectl get --watch --show-labels -o=wide -l
alias ksysgwslowidel = kubectl --namespace=kube-system get --watch --show-labels -o=wide -l
alias kgpowslowidel = kubectl get pods --watch --show-labels -o=wide -l
alias ksysgpowslowidel = kubectl --namespace=kube-system get pods --watch --show-labels -o=wide -l
alias kgdepwslowidel = kubectl get deployment --watch --show-labels -o=wide -l
alias ksysgdepwslowidel = kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide -l
alias kgstswslowidel = kubectl get statefulset --watch --show-labels -o=wide -l
alias ksysgstswslowidel = kubectl --namespace=kube-system get statefulset --watch --show-labels -o=wide -l
alias kgsvcwslowidel = kubectl get service --watch --show-labels -o=wide -l
alias ksysgsvcwslowidel = kubectl --namespace=kube-system get service --watch --show-labels -o=wide -l
alias kgingwslowidel = kubectl get ingress --watch --show-labels -o=wide -l
alias ksysgingwslowidel = kubectl --namespace=kube-system get ingress --watch --show-labels -o=wide -l
alias kgcmwslowidel = kubectl get configmap --watch --show-labels -o=wide -l
alias ksysgcmwslowidel = kubectl --namespace=kube-system get configmap --watch --show-labels -o=wide -l
alias kgsecwslowidel = kubectl get secret --watch --show-labels -o=wide -l
alias ksysgsecwslowidel = kubectl --namespace=kube-system get secret --watch --show-labels -o=wide -l
alias kgnowslowidel = kubectl get nodes --watch --show-labels -o=wide -l
alias kgnswslowidel = kubectl get namespaces --watch --show-labels -o=wide -l
alias kexn = kubectl exec -i -t --namespace
alias klon = kubectl logs -f --namespace
alias kpfn = kubectl port-forward --namespace
alias kgn = kubectl get --namespace
alias kdn = kubectl describe --namespace
alias krmn = kubectl delete --namespace
alias kgpon = kubectl get pods --namespace
alias kdpon = kubectl describe pods --namespace
alias krmpon = kubectl delete pods --namespace
alias kgdepn = kubectl get deployment --namespace
alias kddepn = kubectl describe deployment --namespace
alias krmdepn = kubectl delete deployment --namespace
alias kgstsn = kubectl get statefulset --namespace
alias kdstsn = kubectl describe statefulset --namespace
alias krmstsn = kubectl delete statefulset --namespace
alias kgsvcn = kubectl get service --namespace
alias kdsvcn = kubectl describe service --namespace
alias krmsvcn = kubectl delete service --namespace
alias kgingn = kubectl get ingress --namespace
alias kdingn = kubectl describe ingress --namespace
alias krmingn = kubectl delete ingress --namespace
alias kgcmn = kubectl get configmap --namespace
alias kdcmn = kubectl describe configmap --namespace
alias krmcmn = kubectl delete configmap --namespace
alias kgsecn = kubectl get secret --namespace
alias kdsecn = kubectl describe secret --namespace
alias krmsecn = kubectl delete secret --namespace
alias kgoyamln = kubectl get -o=yaml --namespace
alias kgpooyamln = kubectl get pods -o=yaml --namespace
alias kgdepoyamln = kubectl get deployment -o=yaml --namespace
alias kgstsoyamln = kubectl get statefulset -o=yaml --namespace
alias kgsvcoyamln = kubectl get service -o=yaml --namespace
alias kgingoyamln = kubectl get ingress -o=yaml --namespace
alias kgcmoyamln = kubectl get configmap -o=yaml --namespace
alias kgsecoyamln = kubectl get secret -o=yaml --namespace
alias kgowiden = kubectl get -o=wide --namespace
alias kgpoowiden = kubectl get pods -o=wide --namespace
alias kgdepowiden = kubectl get deployment -o=wide --namespace
alias kgstsowiden = kubectl get statefulset -o=wide --namespace
alias kgsvcowiden = kubectl get service -o=wide --namespace
alias kgingowiden = kubectl get ingress -o=wide --namespace
alias kgcmowiden = kubectl get configmap -o=wide --namespace
alias kgsecowiden = kubectl get secret -o=wide --namespace
alias kgojsonn = kubectl get -o=json --namespace
alias kgpoojsonn = kubectl get pods -o=json --namespace
alias kgdepojsonn = kubectl get deployment -o=json --namespace
alias kgstsojsonn = kubectl get statefulset -o=json --namespace
alias kgsvcojsonn = kubectl get service -o=json --namespace
alias kgingojsonn = kubectl get ingress -o=json --namespace
alias kgcmojsonn = kubectl get configmap -o=json --namespace
alias kgsecojsonn = kubectl get secret -o=json --namespace
alias kgsln = kubectl get --show-labels --namespace
alias kgposln = kubectl get pods --show-labels --namespace
alias kgdepsln = kubectl get deployment --show-labels --namespace
alias kgstssln = kubectl get statefulset --show-labels --namespace
alias kgsvcsln = kubectl get service --show-labels --namespace
alias kgingsln = kubectl get ingress --show-labels --namespace
alias kgcmsln = kubectl get configmap --show-labels --namespace
alias kgsecsln = kubectl get secret --show-labels --namespace
alias kgwn = kubectl get --watch --namespace
alias kgpown = kubectl get pods --watch --namespace
alias kgdepwn = kubectl get deployment --watch --namespace
alias kgstswn = kubectl get statefulset --watch --namespace
alias kgsvcwn = kubectl get service --watch --namespace
alias kgingwn = kubectl get ingress --watch --namespace
alias kgcmwn = kubectl get configmap --watch --namespace
alias kgsecwn = kubectl get secret --watch --namespace
alias kgwoyamln = kubectl get --watch -o=yaml --namespace
alias kgpowoyamln = kubectl get pods --watch -o=yaml --namespace
alias kgdepwoyamln = kubectl get deployment --watch -o=yaml --namespace
alias kgstswoyamln = kubectl get statefulset --watch -o=yaml --namespace
alias kgsvcwoyamln = kubectl get service --watch -o=yaml --namespace
alias kgingwoyamln = kubectl get ingress --watch -o=yaml --namespace
alias kgcmwoyamln = kubectl get configmap --watch -o=yaml --namespace
alias kgsecwoyamln = kubectl get secret --watch -o=yaml --namespace
alias kgowidesln = kubectl get -o=wide --show-labels --namespace
alias kgpoowidesln = kubectl get pods -o=wide --show-labels --namespace
alias kgdepowidesln = kubectl get deployment -o=wide --show-labels --namespace
alias kgstsowidesln = kubectl get statefulset -o=wide --show-labels --namespace
alias kgsvcowidesln = kubectl get service -o=wide --show-labels --namespace
alias kgingowidesln = kubectl get ingress -o=wide --show-labels --namespace
alias kgcmowidesln = kubectl get configmap -o=wide --show-labels --namespace
alias kgsecowidesln = kubectl get secret -o=wide --show-labels --namespace
alias kgslowiden = kubectl get --show-labels -o=wide --namespace
alias kgposlowiden = kubectl get pods --show-labels -o=wide --namespace
alias kgdepslowiden = kubectl get deployment --show-labels -o=wide --namespace
alias kgstsslowiden = kubectl get statefulset --show-labels -o=wide --namespace
alias kgsvcslowiden = kubectl get service --show-labels -o=wide --namespace
alias kgingslowiden = kubectl get ingress --show-labels -o=wide --namespace
alias kgcmslowiden = kubectl get configmap --show-labels -o=wide --namespace
alias kgsecslowiden = kubectl get secret --show-labels -o=wide --namespace
alias kgwowiden = kubectl get --watch -o=wide --namespace
alias kgpowowiden = kubectl get pods --watch -o=wide --namespace
alias kgdepwowiden = kubectl get deployment --watch -o=wide --namespace
alias kgstswowiden = kubectl get statefulset --watch -o=wide --namespace
alias kgsvcwowiden = kubectl get service --watch -o=wide --namespace
alias kgingwowiden = kubectl get ingress --watch -o=wide --namespace
alias kgcmwowiden = kubectl get configmap --watch -o=wide --namespace
alias kgsecwowiden = kubectl get secret --watch -o=wide --namespace
alias kgwojsonn = kubectl get --watch -o=json --namespace
alias kgpowojsonn = kubectl get pods --watch -o=json --namespace
alias kgdepwojsonn = kubectl get deployment --watch -o=json --namespace
alias kgstswojsonn = kubectl get statefulset --watch -o=json --namespace
alias kgsvcwojsonn = kubectl get service --watch -o=json --namespace
alias kgingwojsonn = kubectl get ingress --watch -o=json --namespace
alias kgcmwojsonn = kubectl get configmap --watch -o=json --namespace
alias kgsecwojsonn = kubectl get secret --watch -o=json --namespace
alias kgslwn = kubectl get --show-labels --watch --namespace
alias kgposlwn = kubectl get pods --show-labels --watch --namespace
alias kgdepslwn = kubectl get deployment --show-labels --watch --namespace
alias kgstsslwn = kubectl get statefulset --show-labels --watch --namespace
alias kgsvcslwn = kubectl get service --show-labels --watch --namespace
alias kgingslwn = kubectl get ingress --show-labels --watch --namespace
alias kgcmslwn = kubectl get configmap --show-labels --watch --namespace
alias kgsecslwn = kubectl get secret --show-labels --watch --namespace
alias kgwsln = kubectl get --watch --show-labels --namespace
alias kgpowsln = kubectl get pods --watch --show-labels --namespace
alias kgdepwsln = kubectl get deployment --watch --show-labels --namespace
alias kgstswsln = kubectl get statefulset --watch --show-labels --namespace
alias kgsvcwsln = kubectl get service --watch --show-labels --namespace
alias kgingwsln = kubectl get ingress --watch --show-labels --namespace
alias kgcmwsln = kubectl get configmap --watch --show-labels --namespace
alias kgsecwsln = kubectl get secret --watch --show-labels --namespace
alias kgslwowiden = kubectl get --show-labels --watch -o=wide --namespace
alias kgposlwowiden = kubectl get pods --show-labels --watch -o=wide --namespace
alias kgdepslwowiden = kubectl get deployment --show-labels --watch -o=wide --namespace
alias kgstsslwowiden = kubectl get statefulset --show-labels --watch -o=wide --namespace
alias kgsvcslwowiden = kubectl get service --show-labels --watch -o=wide --namespace
alias kgingslwowiden = kubectl get ingress --show-labels --watch -o=wide --namespace
alias kgcmslwowiden = kubectl get configmap --show-labels --watch -o=wide --namespace
alias kgsecslwowiden = kubectl get secret --show-labels --watch -o=wide --namespace
alias kgwowidesln = kubectl get --watch -o=wide --show-labels --namespace
alias kgpowowidesln = kubectl get pods --watch -o=wide --show-labels --namespace
alias kgdepwowidesln = kubectl get deployment --watch -o=wide --show-labels --namespace
alias kgstswowidesln = kubectl get statefulset --watch -o=wide --show-labels --namespace
alias kgsvcwowidesln = kubectl get service --watch -o=wide --show-labels --namespace
alias kgingwowidesln = kubectl get ingress --watch -o=wide --show-labels --namespace
alias kgcmwowidesln = kubectl get configmap --watch -o=wide --show-labels --namespace
alias kgsecwowidesln = kubectl get secret --watch -o=wide --show-labels --namespace
alias kgwslowiden = kubectl get --watch --show-labels -o=wide --namespace
alias kgpowslowiden = kubectl get pods --watch --show-labels -o=wide --namespace
alias kgdepwslowiden = kubectl get deployment --watch --show-labels -o=wide --namespace
alias kgstswslowiden = kubectl get statefulset --watch --show-labels -o=wide --namespace
alias kgsvcwslowiden = kubectl get service --watch --show-labels -o=wide --namespace
alias kgingwslowiden = kubectl get ingress --watch --show-labels -o=wide --namespace
alias kgcmwslowiden = kubectl get configmap --watch --show-labels -o=wide --namespace
alias kgsecwslowiden = kubectl get secret --watch --show-labels -o=wide --namespace
# modules/darwin/home/nu/core/kubectl.nu (end)

