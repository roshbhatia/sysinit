alias k = kubecolor
alias ksys = kubecolor --namespace=kube-system
alias ka = kubecolor apply --recursive -f
alias ksysa = kubecolor --namespace=kube-system apply --recursive -f
alias kak = kubecolor apply -k
alias kk = kubecolor kustomize
alias kex = kubecolor exec -i -t
alias ksysex = kubecolor --namespace=kube-system exec -i -t
alias klo = kubecolor logs -f
alias ksyslo = kubecolor --namespace=kube-system logs -f
alias klop = kubecolor logs -f -p
alias ksyslop = kubecolor --namespace=kube-system logs -f -p
alias kp = kubecolor proxy
alias kpf = kubecolor port-forward
alias kg = kubecolor get
alias ksysg = kubecolor --namespace=kube-system get
alias kd = kubecolor describe
alias ksysd = kubecolor --namespace=kube-system describe
alias krm = kubecolor delete
alias ksysrm = kubecolor --namespace=kube-system delete
alias krun = kubecolor run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t
alias ksysrun = kubecolor --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t
alias kgpo = kubecolor get pods
alias ksysgpo = kubecolor --namespace=kube-system get pods
alias kdpo = kubecolor describe pods
alias ksysdpo = kubecolor --namespace=kube-system describe pods
alias krmpo = kubecolor delete pods
alias ksysrmpo = kubecolor --namespace=kube-system delete pods
alias kgdep = kubecolor get deployment
alias ksysgdep = kubecolor --namespace=kube-system get deployment
alias kddep = kubecolor describe deployment
alias ksysddep = kubecolor --namespace=kube-system describe deployment
alias krmdep = kubecolor delete deployment
alias ksysrmdep = kubecolor --namespace=kube-system delete deployment
alias kgsts = kubecolor get statefulset
alias ksysgsts = kubecolor --namespace=kube-system get statefulset
alias kdsts = kubecolor describe statefulset
alias ksysdsts = kubecolor --namespace=kube-system describe statefulset
alias krmsts = kubecolor delete statefulset
alias ksysrmsts = kubecolor --namespace=kube-system delete statefulset
alias kgsvc = kubecolor get service
alias ksysgsvc = kubecolor --namespace=kube-system get service
alias kdsvc = kubecolor describe service
alias ksysdsvc = kubecolor --namespace=kube-system describe service
alias krmsvc = kubecolor delete service
alias ksysrmsvc = kubecolor --namespace=kube-system delete service
alias kging = kubecolor get ingress
alias ksysging = kubecolor --namespace=kube-system get ingress
alias kding = kubecolor describe ingress
alias ksysding = kubecolor --namespace=kube-system describe ingress
alias krming = kubecolor delete ingress
alias ksysrming = kubecolor --namespace=kube-system delete ingress
alias kgcm = kubecolor get configmap
alias ksysgcm = kubecolor --namespace=kube-system get configmap
alias kdcm = kubecolor describe configmap
alias ksysdcm = kubecolor --namespace=kube-system describe configmap
alias krmcm = kubecolor delete configmap
alias ksysrmcm = kubecolor --namespace=kube-system delete configmap
alias kgsec = kubecolor get secret
alias ksysgsec = kubecolor --namespace=kube-system get secret
alias kdsec = kubecolor describe secret
alias ksysdsec = kubecolor --namespace=kube-system describe secret
alias krmsec = kubecolor delete secret
alias ksysrmsec = kubecolor --namespace=kube-system delete secret
alias kgno = kubecolor get nodes
alias kdno = kubecolor describe nodes
alias kgns = kubecolor get namespaces
alias kdns = kubecolor describe namespaces
alias krmns = kubecolor delete namespaces
alias kgoyaml = kubecolor get -o=yaml
alias ksysgoyaml = kubecolor --namespace=kube-system get -o=yaml
alias kgpooyaml = kubecolor get pods -o=yaml
alias ksysgpooyaml = kubecolor --namespace=kube-system get pods -o=yaml
alias kgdepoyaml = kubecolor get deployment -o=yaml
alias ksysgdepoyaml = kubecolor --namespace=kube-system get deployment -o=yaml
alias kgstsoyaml = kubecolor get statefulset -o=yaml
alias ksysgstsoyaml = kubecolor --namespace=kube-system get statefulset -o=yaml
alias kgsvcoyaml = kubecolor get service -o=yaml
alias ksysgsvcoyaml = kubecolor --namespace=kube-system get service -o=yaml
alias kgingoyaml = kubecolor get ingress -o=yaml
alias ksysgingoyaml = kubecolor --namespace=kube-system get ingress -o=yaml
alias kgcmoyaml = kubecolor get configmap -o=yaml
alias ksysgcmoyaml = kubecolor --namespace=kube-system get configmap -o=yaml
alias kgsecoyaml = kubecolor get secret -o=yaml
alias ksysgsecoyaml = kubecolor --namespace=kube-system get secret -o=yaml
alias kgnooyaml = kubecolor get nodes -o=yaml
alias kgnsoyaml = kubecolor get namespaces -o=yaml
alias kgowide = kubecolor get -o=wide
alias ksysgowide = kubecolor --namespace=kube-system get -o=wide
alias kgpoowide = kubecolor get pods -o=wide
alias ksysgpoowide = kubecolor --namespace=kube-system get pods -o=wide
alias kgdepowide = kubecolor get deployment -o=wide
alias ksysgdepowide = kubecolor --namespace=kube-system get deployment -o=wide
alias kgstsowide = kubecolor get statefulset -o=wide
alias ksysgstsowide = kubecolor --namespace=kube-system get statefulset -o=wide
alias kgsvcowide = kubecolor get service -o=wide
alias ksysgsvcowide = kubecolor --namespace=kube-system get service -o=wide
alias kgingowide = kubecolor get ingress -o=wide
alias ksysgingowide = kubecolor --namespace=kube-system get ingress -o=wide
alias kgcmowide = kubecolor get configmap -o=wide
alias ksysgcmowide = kubecolor --namespace=kube-system get configmap -o=wide
alias kgsecowide = kubecolor get secret -o=wide
alias ksysgsecowide = kubecolor --namespace=kube-system get secret -o=wide
alias kgnoowide = kubecolor get nodes -o=wide
alias kgnsowide = kubecolor get namespaces -o=wide
alias kgojson = kubecolor get -o=json
alias ksysgojson = kubecolor --namespace=kube-system get -o=json
alias kgpoojson = kubecolor get pods -o=json
alias ksysgpoojson = kubecolor --namespace=kube-system get pods -o=json
alias kgdepojson = kubecolor get deployment -o=json
alias ksysgdepojson = kubecolor --namespace=kube-system get deployment -o=json
alias kgstsojson = kubecolor get statefulset -o=json
alias ksysgstsojson = kubecolor --namespace=kube-system get statefulset -o=json
alias kgsvcojson = kubecolor get service -o=json
alias ksysgsvcojson = kubecolor --namespace=kube-system get service -o=json
alias kgingojson = kubecolor get ingress -o=json
alias ksysgingojson = kubecolor --namespace=kube-system get ingress -o=json
alias kgcmojson = kubecolor get configmap -o=json
alias ksysgcmojson = kubecolor --namespace=kube-system get configmap -o=json
alias kgsecojson = kubecolor get secret -o=json
alias ksysgsecojson = kubecolor --namespace=kube-system get secret -o=json
alias kgnoojson = kubecolor get nodes -o=json
alias kgnsojson = kubecolor get namespaces -o=json
alias kgall = kubecolor get --all-namespaces
alias kdall = kubecolor describe --all-namespaces
alias kgpoall = kubecolor get pods --all-namespaces
alias kdpoall = kubecolor describe pods --all-namespaces
alias kgdepall = kubecolor get deployment --all-namespaces
alias kddepall = kubecolor describe deployment --all-namespaces
alias kgstsall = kubecolor get statefulset --all-namespaces
alias kdstsall = kubecolor describe statefulset --all-namespaces
alias kgsvcall = kubecolor get service --all-namespaces
alias kdsvcall = kubecolor describe service --all-namespaces
alias kgingall = kubecolor get ingress --all-namespaces
alias kdingall = kubecolor describe ingress --all-namespaces
alias kgcmall = kubecolor get configmap --all-namespaces
alias kdcmall = kubecolor describe configmap --all-namespaces
alias kgsecall = kubecolor get secret --all-namespaces
alias kdsecall = kubecolor describe secret --all-namespaces
alias kgnsall = kubecolor get namespaces --all-namespaces
alias kdnsall = kubecolor describe namespaces --all-namespaces
alias kgsl = kubecolor get --show-labels
alias ksysgsl = kubecolor --namespace=kube-system get --show-labels
alias kgposl = kubecolor get pods --show-labels
alias ksysgposl = kubecolor --namespace=kube-system get pods --show-labels
alias kgdepsl = kubecolor get deployment --show-labels
alias ksysgdepsl = kubecolor --namespace=kube-system get deployment --show-labels
alias kgstssl = kubecolor get statefulset --show-labels
alias ksysgstssl = kubecolor --namespace=kube-system get statefulset --show-labels
alias kgsvcsl = kubecolor get service --show-labels
alias ksysgsvcsl = kubecolor --namespace=kube-system get service --show-labels
alias kgingsl = kubecolor get ingress --show-labels
alias ksysgingsl = kubecolor --namespace=kube-system get ingress --show-labels
alias kgcmsl = kubecolor get configmap --show-labels
alias ksysgcmsl = kubecolor --namespace=kube-system get configmap --show-labels
alias kgsecsl = kubecolor get secret --show-labels
alias ksysgsecsl = kubecolor --namespace=kube-system get secret --show-labels
alias kgnosl = kubecolor get nodes --show-labels
alias kgnssl = kubecolor get namespaces --show-labels
alias krmall = kubecolor delete --all
alias ksysrmall = kubecolor --namespace=kube-system delete --all
alias krmpoall = kubecolor delete pods --all
alias ksysrmpoall = kubecolor --namespace=kube-system delete pods --all
alias krmdepall = kubecolor delete deployment --all
alias ksysrmdepall = kubecolor --namespace=kube-system delete deployment --all
alias krmstsall = kubecolor delete statefulset --all
alias ksysrmstsall = kubecolor --namespace=kube-system delete statefulset --all
alias krmsvcall = kubecolor delete service --all
alias ksysrmsvcall = kubecolor --namespace=kube-system delete service --all
alias krmingall = kubecolor delete ingress --all
alias ksysrmingall = kubecolor --namespace=kube-system delete ingress --all
alias krmcmall = kubecolor delete configmap --all
alias ksysrmcmall = kubecolor --namespace=kube-system delete configmap --all
alias krmsecall = kubecolor delete secret --all
alias ksysrmsecall = kubecolor --namespace=kube-system delete secret --all
alias krmnsall = kubecolor delete namespaces --all
alias kgw = kubecolor get --watch
alias ksysgw = kubecolor --namespace=kube-system get --watch
alias kgpow = kubecolor get pods --watch
alias ksysgpow = kubecolor --namespace=kube-system get pods --watch
alias kgdepw = kubecolor get deployment --watch
alias ksysgdepw = kubecolor --namespace=kube-system get deployment --watch
alias kgstsw = kubecolor get statefulset --watch
alias ksysgstsw = kubecolor --namespace=kube-system get statefulset --watch
alias kgsvcw = kubecolor get service --watch
alias ksysgsvcw = kubecolor --namespace=kube-system get service --watch
alias kgingw = kubecolor get ingress --watch
alias ksysgingw = kubecolor --namespace=kube-system get ingress --watch
alias kgcmw = kubecolor get configmap --watch
alias ksysgcmw = kubecolor --namespace=kube-system get configmap --watch
alias kgsecw = kubecolor get secret --watch
alias ksysgsecw = kubecolor --namespace=kube-system get secret --watch
alias kgnow = kubecolor get nodes --watch
alias kgnsw = kubecolor get namespaces --watch
alias kgoyamlall = kubecolor get -o=yaml --all-namespaces
alias kgpooyamlall = kubecolor get pods -o=yaml --all-namespaces
alias kgdepoyamlall = kubecolor get deployment -o=yaml --all-namespaces
alias kgstsoyamlall = kubecolor get statefulset -o=yaml --all-namespaces
alias kgsvcoyamlall = kubecolor get service -o=yaml --all-namespaces
alias kgingoyamlall = kubecolor get ingress -o=yaml --all-namespaces
alias kgcmoyamlall = kubecolor get configmap -o=yaml --all-namespaces
alias kgsecoyamlall = kubecolor get secret -o=yaml --all-namespaces
alias kgnsoyamlall = kubecolor get namespaces -o=yaml --all-namespaces
alias kgalloyaml = kubecolor get --all-namespaces -o=yaml
alias kgpoalloyaml = kubecolor get pods --all-namespaces -o=yaml
alias kgdepalloyaml = kubecolor get deployment --all-namespaces -o=yaml
alias kgstsalloyaml = kubecolor get statefulset --all-namespaces -o=yaml
alias kgsvcalloyaml = kubecolor get service --all-namespaces -o=yaml
alias kgingalloyaml = kubecolor get ingress --all-namespaces -o=yaml
alias kgcmalloyaml = kubecolor get configmap --all-namespaces -o=yaml
alias kgsecalloyaml = kubecolor get secret --all-namespaces -o=yaml
alias kgnsalloyaml = kubecolor get namespaces --all-namespaces -o=yaml
alias kgwoyaml = kubecolor get --watch -o=yaml
alias ksysgwoyaml = kubecolor --namespace=kube-system get --watch -o=yaml
alias kgpowoyaml = kubecolor get pods --watch -o=yaml
alias ksysgpowoyaml = kubecolor --namespace=kube-system get pods --watch -o=yaml
alias kgdepwoyaml = kubecolor get deployment --watch -o=yaml
alias ksysgdepwoyaml = kubecolor --namespace=kube-system get deployment --watch -o=yaml
alias kgstswoyaml = kubecolor get statefulset --watch -o=yaml
alias ksysgstswoyaml = kubecolor --namespace=kube-system get statefulset --watch -o=yaml
alias kgsvcwoyaml = kubecolor get service --watch -o=yaml
alias ksysgsvcwoyaml = kubecolor --namespace=kube-system get service --watch -o=yaml
alias kgingwoyaml = kubecolor get ingress --watch -o=yaml
alias ksysgingwoyaml = kubecolor --namespace=kube-system get ingress --watch -o=yaml
alias kgcmwoyaml = kubecolor get configmap --watch -o=yaml
alias ksysgcmwoyaml = kubecolor --namespace=kube-system get configmap --watch -o=yaml
alias kgsecwoyaml = kubecolor get secret --watch -o=yaml
alias ksysgsecwoyaml = kubecolor --namespace=kube-system get secret --watch -o=yaml
alias kgnowoyaml = kubecolor get nodes --watch -o=yaml
alias kgnswoyaml = kubecolor get namespaces --watch -o=yaml
alias kgowideall = kubecolor get -o=wide --all-namespaces
alias kgpoowideall = kubecolor get pods -o=wide --all-namespaces
alias kgdepowideall = kubecolor get deployment -o=wide --all-namespaces
alias kgstsowideall = kubecolor get statefulset -o=wide --all-namespaces
alias kgsvcowideall = kubecolor get service -o=wide --all-namespaces
alias kgingowideall = kubecolor get ingress -o=wide --all-namespaces
alias kgcmowideall = kubecolor get configmap -o=wide --all-namespaces
alias kgsecowideall = kubecolor get secret -o=wide --all-namespaces
alias kgnsowideall = kubecolor get namespaces -o=wide --all-namespaces
alias kgallowide = kubecolor get --all-namespaces -o=wide
alias kgpoallowide = kubecolor get pods --all-namespaces -o=wide
alias kgdepallowide = kubecolor get deployment --all-namespaces -o=wide
alias kgstsallowide = kubecolor get statefulset --all-namespaces -o=wide
alias kgsvcallowide = kubecolor get service --all-namespaces -o=wide
alias kgingallowide = kubecolor get ingress --all-namespaces -o=wide
alias kgcmallowide = kubecolor get configmap --all-namespaces -o=wide
alias kgsecallowide = kubecolor get secret --all-namespaces -o=wide
alias kgnsallowide = kubecolor get namespaces --all-namespaces -o=wide
alias kgowidesl = kubecolor get -o=wide --show-labels
alias ksysgowidesl = kubecolor --namespace=kube-system get -o=wide --show-labels
alias kgpoowidesl = kubecolor get pods -o=wide --show-labels
alias ksysgpoowidesl = kubecolor --namespace=kube-system get pods -o=wide --show-labels
alias kgdepowidesl = kubecolor get deployment -o=wide --show-labels
alias ksysgdepowidesl = kubecolor --namespace=kube-system get deployment -o=wide --show-labels
alias kgstsowidesl = kubecolor get statefulset -o=wide --show-labels
alias ksysgstsowidesl = kubecolor --namespace=kube-system get statefulset -o=wide --show-labels
alias kgsvcowidesl = kubecolor get service -o=wide --show-labels
alias ksysgsvcowidesl = kubecolor --namespace=kube-system get service -o=wide --show-labels
alias kgingowidesl = kubecolor get ingress -o=wide --show-labels
alias ksysgingowidesl = kubecolor --namespace=kube-system get ingress -o=wide --show-labels
alias kgcmowidesl = kubecolor get configmap -o=wide --show-labels
alias ksysgcmowidesl = kubecolor --namespace=kube-system get configmap -o=wide --show-labels
alias kgsecowidesl = kubecolor get secret -o=wide --show-labels
alias ksysgsecowidesl = kubecolor --namespace=kube-system get secret -o=wide --show-labels
alias kgnoowidesl = kubecolor get nodes -o=wide --show-labels
alias kgnsowidesl = kubecolor get namespaces -o=wide --show-labels
alias kgslowide = kubecolor get --show-labels -o=wide
alias ksysgslowide = kubecolor --namespace=kube-system get --show-labels -o=wide
alias kgposlowide = kubecolor get pods --show-labels -o=wide
alias ksysgposlowide = kubecolor --namespace=kube-system get pods --show-labels -o=wide
alias kgdepslowide = kubecolor get deployment --show-labels -o=wide
alias ksysgdepslowide = kubecolor --namespace=kube-system get deployment --show-labels -o=wide
alias kgstsslowide = kubecolor get statefulset --show-labels -o=wide
alias ksysgstsslowide = kubecolor --namespace=kube-system get statefulset --show-labels -o=wide
alias kgsvcslowide = kubecolor get service --show-labels -o=wide
alias ksysgsvcslowide = kubecolor --namespace=kube-system get service --show-labels -o=wide
alias kgingslowide = kubecolor get ingress --show-labels -o=wide
alias ksysgingslowide = kubecolor --namespace=kube-system get ingress --show-labels -o=wide
alias kgcmslowide = kubecolor get configmap --show-labels -o=wide
alias ksysgcmslowide = kubecolor --namespace=kube-system get configmap --show-labels -o=wide
alias kgsecslowide = kubecolor get secret --show-labels -o=wide
alias ksysgsecslowide = kubecolor --namespace=kube-system get secret --show-labels -o=wide
alias kgnoslowide = kubecolor get nodes --show-labels -o=wide
alias kgnsslowide = kubecolor get namespaces --show-labels -o=wide
alias kgwowide = kubecolor get --watch -o=wide
alias ksysgwowide = kubecolor --namespace=kube-system get --watch -o=wide
alias kgpowowide = kubecolor get pods --watch -o=wide
alias ksysgpowowide = kubecolor --namespace=kube-system get pods --watch -o=wide
alias kgdepwowide = kubecolor get deployment --watch -o=wide
alias ksysgdepwowide = kubecolor --namespace=kube-system get deployment --watch -o=wide
alias kgstswowide = kubecolor get statefulset --watch -o=wide
alias ksysgstswowide = kubecolor --namespace=kube-system get statefulset --watch -o=wide
alias kgsvcwowide = kubecolor get service --watch -o=wide
alias ksysgsvcwowide = kubecolor --namespace=kube-system get service --watch -o=wide
alias kgingwowide = kubecolor get ingress --watch -o=wide
alias ksysgingwowide = kubecolor --namespace=kube-system get ingress --watch -o=wide
alias kgcmwowide = kubecolor get configmap --watch -o=wide
alias ksysgcmwowide = kubecolor --namespace=kube-system get configmap --watch -o=wide
alias kgsecwowide = kubecolor get secret --watch -o=wide
alias ksysgsecwowide = kubecolor --namespace=kube-system get secret --watch -o=wide
alias kgnowowide = kubecolor get nodes --watch -o=wide
alias kgnswowide = kubecolor get namespaces --watch -o=wide
alias kgojsonall = kubecolor get -o=json --all-namespaces
alias kgpoojsonall = kubecolor get pods -o=json --all-namespaces
alias kgdepojsonall = kubecolor get deployment -o=json --all-namespaces
alias kgstsojsonall = kubecolor get statefulset -o=json --all-namespaces
alias kgsvcojsonall = kubecolor get service -o=json --all-namespaces
alias kgingojsonall = kubecolor get ingress -o=json --all-namespaces
alias kgcmojsonall = kubecolor get configmap -o=json --all-namespaces
alias kgsecojsonall = kubecolor get secret -o=json --all-namespaces
alias kgnsojsonall = kubecolor get namespaces -o=json --all-namespaces
alias kgallojson = kubecolor get --all-namespaces -o=json
alias kgpoallojson = kubecolor get pods --all-namespaces -o=json
alias kgdepallojson = kubecolor get deployment --all-namespaces -o=json
alias kgstsallojson = kubecolor get statefulset --all-namespaces -o=json
alias kgsvcallojson = kubecolor get service --all-namespaces -o=json
alias kgingallojson = kubecolor get ingress --all-namespaces -o=json
alias kgcmallojson = kubecolor get configmap --all-namespaces -o=json
alias kgsecallojson = kubecolor get secret --all-namespaces -o=json
alias kgnsallojson = kubecolor get namespaces --all-namespaces -o=json
alias kgwojson = kubecolor get --watch -o=json
alias ksysgwojson = kubecolor --namespace=kube-system get --watch -o=json
alias kgpowojson = kubecolor get pods --watch -o=json
alias ksysgpowojson = kubecolor --namespace=kube-system get pods --watch -o=json
alias kgdepwojson = kubecolor get deployment --watch -o=json
alias ksysgdepwojson = kubecolor --namespace=kube-system get deployment --watch -o=json
alias kgstswojson = kubecolor get statefulset --watch -o=json
alias ksysgstswojson = kubecolor --namespace=kube-system get statefulset --watch -o=json
alias kgsvcwojson = kubecolor get service --watch -o=json
alias ksysgsvcwojson = kubecolor --namespace=kube-system get service --watch -o=json
alias kgingwojson = kubecolor get ingress --watch -o=json
alias ksysgingwojson = kubecolor --namespace=kube-system get ingress --watch -o=json
alias kgcmwojson = kubecolor get configmap --watch -o=json
alias ksysgcmwojson = kubecolor --namespace=kube-system get configmap --watch -o=json
alias kgsecwojson = kubecolor get secret --watch -o=json
alias ksysgsecwojson = kubecolor --namespace=kube-system get secret --watch -o=json
alias kgnowojson = kubecolor get nodes --watch -o=json
alias kgnswojson = kubecolor get namespaces --watch -o=json
alias kgallsl = kubecolor get --all-namespaces --show-labels
alias kgpoallsl = kubecolor get pods --all-namespaces --show-labels
alias kgdepallsl = kubecolor get deployment --all-namespaces --show-labels
alias kgstsallsl = kubecolor get statefulset --all-namespaces --show-labels
alias kgsvcallsl = kubecolor get service --all-namespaces --show-labels
alias kgingallsl = kubecolor get ingress --all-namespaces --show-labels
alias kgcmallsl = kubecolor get configmap --all-namespaces --show-labels
alias kgsecallsl = kubecolor get secret --all-namespaces --show-labels
alias kgnsallsl = kubecolor get namespaces --all-namespaces --show-labels
alias kgslall = kubecolor get --show-labels --all-namespaces
alias kgposlall = kubecolor get pods --show-labels --all-namespaces
alias kgdepslall = kubecolor get deployment --show-labels --all-namespaces
alias kgstsslall = kubecolor get statefulset --show-labels --all-namespaces
alias kgsvcslall = kubecolor get service --show-labels --all-namespaces
alias kgingslall = kubecolor get ingress --show-labels --all-namespaces
alias kgcmslall = kubecolor get configmap --show-labels --all-namespaces
alias kgsecslall = kubecolor get secret --show-labels --all-namespaces
alias kgnsslall = kubecolor get namespaces --show-labels --all-namespaces
alias kgallw = kubecolor get --all-namespaces --watch
alias kgpoallw = kubecolor get pods --all-namespaces --watch
alias kgdepallw = kubecolor get deployment --all-namespaces --watch
alias kgstsallw = kubecolor get statefulset --all-namespaces --watch
alias kgsvcallw = kubecolor get service --all-namespaces --watch
alias kgingallw = kubecolor get ingress --all-namespaces --watch
alias kgcmallw = kubecolor get configmap --all-namespaces --watch
alias kgsecallw = kubecolor get secret --all-namespaces --watch
alias kgnsallw = kubecolor get namespaces --all-namespaces --watch
alias kgwall = kubecolor get --watch --all-namespaces
alias kgpowall = kubecolor get pods --watch --all-namespaces
alias kgdepwall = kubecolor get deployment --watch --all-namespaces
alias kgstswall = kubecolor get statefulset --watch --all-namespaces
alias kgsvcwall = kubecolor get service --watch --all-namespaces
alias kgingwall = kubecolor get ingress --watch --all-namespaces
alias kgcmwall = kubecolor get configmap --watch --all-namespaces
alias kgsecwall = kubecolor get secret --watch --all-namespaces
alias kgnswall = kubecolor get namespaces --watch --all-namespaces
alias kgslw = kubecolor get --show-labels --watch
alias ksysgslw = kubecolor --namespace=kube-system get --show-labels --watch
alias kgposlw = kubecolor get pods --show-labels --watch
alias ksysgposlw = kubecolor --namespace=kube-system get pods --show-labels --watch
alias kgdepslw = kubecolor get deployment --show-labels --watch
alias ksysgdepslw = kubecolor --namespace=kube-system get deployment --show-labels --watch
alias kgstsslw = kubecolor get statefulset --show-labels --watch
alias ksysgstsslw = kubecolor --namespace=kube-system get statefulset --show-labels --watch
alias kgsvcslw = kubecolor get service --show-labels --watch
alias ksysgsvcslw = kubecolor --namespace=kube-system get service --show-labels --watch
alias kgingslw = kubecolor get ingress --show-labels --watch
alias ksysgingslw = kubecolor --namespace=kube-system get ingress --show-labels --watch
alias kgcmslw = kubecolor get configmap --show-labels --watch
alias ksysgcmslw = kubecolor --namespace=kube-system get configmap --show-labels --watch
alias kgsecslw = kubecolor get secret --show-labels --watch
alias ksysgsecslw = kubecolor --namespace=kube-system get secret --show-labels --watch
alias kgnoslw = kubecolor get nodes --show-labels --watch
alias kgnsslw = kubecolor get namespaces --show-labels --watch
alias kgwsl = kubecolor get --watch --show-labels
alias ksysgwsl = kubecolor --namespace=kube-system get --watch --show-labels
alias kgpowsl = kubecolor get pods --watch --show-labels
alias ksysgpowsl = kubecolor --namespace=kube-system get pods --watch --show-labels
alias kgdepwsl = kubecolor get deployment --watch --show-labels
alias ksysgdepwsl = kubecolor --namespace=kube-system get deployment --watch --show-labels
alias kgstswsl = kubecolor get statefulset --watch --show-labels
alias ksysgstswsl = kubecolor --namespace=kube-system get statefulset --watch --show-labels
alias kgsvcwsl = kubecolor get service --watch --show-labels
alias ksysgsvcwsl = kubecolor --namespace=kube-system get service --watch --show-labels
alias kgingwsl = kubecolor get ingress --watch --show-labels
alias ksysgingwsl = kubecolor --namespace=kube-system get ingress --watch --show-labels
alias kgcmwsl = kubecolor get configmap --watch --show-labels
alias ksysgcmwsl = kubecolor --namespace=kube-system get configmap --watch --show-labels
alias kgsecwsl = kubecolor get secret --watch --show-labels
alias ksysgsecwsl = kubecolor --namespace=kube-system get secret --watch --show-labels
alias kgnowsl = kubecolor get nodes --watch --show-labels
alias kgnswsl = kubecolor get namespaces --watch --show-labels
alias kgallwoyaml = kubecolor get --all-namespaces --watch -o=yaml
alias kgpoallwoyaml = kubecolor get pods --all-namespaces --watch -o=yaml
alias kgdepallwoyaml = kubecolor get deployment --all-namespaces --watch -o=yaml
alias kgstsallwoyaml = kubecolor get statefulset --all-namespaces --watch -o=yaml
alias kgsvcallwoyaml = kubecolor get service --all-namespaces --watch -o=yaml
alias kgingallwoyaml = kubecolor get ingress --all-namespaces --watch -o=yaml
alias kgcmallwoyaml = kubecolor get configmap --all-namespaces --watch -o=yaml
alias kgsecallwoyaml = kubecolor get secret --all-namespaces --watch -o=yaml
alias kgnsallwoyaml = kubecolor get namespaces --all-namespaces --watch -o=yaml
alias kgwoyamlall = kubecolor get --watch -o=yaml --all-namespaces
alias kgpowoyamlall = kubecolor get pods --watch -o=yaml --all-namespaces
alias kgdepwoyamlall = kubecolor get deployment --watch -o=yaml --all-namespaces
alias kgstswoyamlall = kubecolor get statefulset --watch -o=yaml --all-namespaces
alias kgsvcwoyamlall = kubecolor get service --watch -o=yaml --all-namespaces
alias kgingwoyamlall = kubecolor get ingress --watch -o=yaml --all-namespaces
alias kgcmwoyamlall = kubecolor get configmap --watch -o=yaml --all-namespaces
alias kgsecwoyamlall = kubecolor get secret --watch -o=yaml --all-namespaces
alias kgnswoyamlall = kubecolor get namespaces --watch -o=yaml --all-namespaces
alias kgwalloyaml = kubecolor get --watch --all-namespaces -o=yaml
alias kgpowalloyaml = kubecolor get pods --watch --all-namespaces -o=yaml
alias kgdepwalloyaml = kubecolor get deployment --watch --all-namespaces -o=yaml
alias kgstswalloyaml = kubecolor get statefulset --watch --all-namespaces -o=yaml
alias kgsvcwalloyaml = kubecolor get service --watch --all-namespaces -o=yaml
alias kgingwalloyaml = kubecolor get ingress --watch --all-namespaces -o=yaml
alias kgcmwalloyaml = kubecolor get configmap --watch --all-namespaces -o=yaml
alias kgsecwalloyaml = kubecolor get secret --watch --all-namespaces -o=yaml
alias kgnswalloyaml = kubecolor get namespaces --watch --all-namespaces -o=yaml
alias kgowideallsl = kubecolor get -o=wide --all-namespaces --show-labels
alias kgpoowideallsl = kubecolor get pods -o=wide --all-namespaces --show-labels
alias kgdepowideallsl = kubecolor get deployment -o=wide --all-namespaces --show-labels
alias kgstsowideallsl = kubecolor get statefulset -o=wide --all-namespaces --show-labels
alias kgsvcowideallsl = kubecolor get service -o=wide --all-namespaces --show-labels
alias kgingowideallsl = kubecolor get ingress -o=wide --all-namespaces --show-labels
alias kgcmowideallsl = kubecolor get configmap -o=wide --all-namespaces --show-labels
alias kgsecowideallsl = kubecolor get secret -o=wide --all-namespaces --show-labels
alias kgnsowideallsl = kubecolor get namespaces -o=wide --all-namespaces --show-labels
alias kgowideslall = kubecolor get -o=wide --show-labels --all-namespaces
alias kgpoowideslall = kubecolor get pods -o=wide --show-labels --all-namespaces
alias kgdepowideslall = kubecolor get deployment -o=wide --show-labels --all-namespaces
alias kgstsowideslall = kubecolor get statefulset -o=wide --show-labels --all-namespaces
alias kgsvcowideslall = kubecolor get service -o=wide --show-labels --all-namespaces
alias kgingowideslall = kubecolor get ingress -o=wide --show-labels --all-namespaces
alias kgcmowideslall = kubecolor get configmap -o=wide --show-labels --all-namespaces
alias kgsecowideslall = kubecolor get secret -o=wide --show-labels --all-namespaces
alias kgnsowideslall = kubecolor get namespaces -o=wide --show-labels --all-namespaces
alias kgallowidesl = kubecolor get --all-namespaces -o=wide --show-labels
alias kgpoallowidesl = kubecolor get pods --all-namespaces -o=wide --show-labels
alias kgdepallowidesl = kubecolor get deployment --all-namespaces -o=wide --show-labels
alias kgstsallowidesl = kubecolor get statefulset --all-namespaces -o=wide --show-labels
alias kgsvcallowidesl = kubecolor get service --all-namespaces -o=wide --show-labels
alias kgingallowidesl = kubecolor get ingress --all-namespaces -o=wide --show-labels
alias kgcmallowidesl = kubecolor get configmap --all-namespaces -o=wide --show-labels
alias kgsecallowidesl = kubecolor get secret --all-namespaces -o=wide --show-labels
alias kgnsallowidesl = kubecolor get namespaces --all-namespaces -o=wide --show-labels
alias kgallslowide = kubecolor get --all-namespaces --show-labels -o=wide
alias kgpoallslowide = kubecolor get pods --all-namespaces --show-labels -o=wide
alias kgdepallslowide = kubecolor get deployment --all-namespaces --show-labels -o=wide
alias kgstsallslowide = kubecolor get statefulset --all-namespaces --show-labels -o=wide
alias kgsvcallslowide = kubecolor get service --all-namespaces --show-labels -o=wide
alias kgingallslowide = kubecolor get ingress --all-namespaces --show-labels -o=wide
alias kgcmallslowide = kubecolor get configmap --all-namespaces --show-labels -o=wide
alias kgsecallslowide = kubecolor get secret --all-namespaces --show-labels -o=wide
alias kgnsallslowide = kubecolor get namespaces --all-namespaces --show-labels -o=wide
alias kgslowideall = kubecolor get --show-labels -o=wide --all-namespaces
alias kgposlowideall = kubecolor get pods --show-labels -o=wide --all-namespaces
alias kgdepslowideall = kubecolor get deployment --show-labels -o=wide --all-namespaces
alias kgstsslowideall = kubecolor get statefulset --show-labels -o=wide --all-namespaces
alias kgsvcslowideall = kubecolor get service --show-labels -o=wide --all-namespaces
alias kgingslowideall = kubecolor get ingress --show-labels -o=wide --all-namespaces
alias kgcmslowideall = kubecolor get configmap --show-labels -o=wide --all-namespaces
alias kgsecslowideall = kubecolor get secret --show-labels -o=wide --all-namespaces
alias kgnsslowideall = kubecolor get namespaces --show-labels -o=wide --all-namespaces
alias kgslallowide = kubecolor get --show-labels --all-namespaces -o=wide
alias kgposlallowide = kubecolor get pods --show-labels --all-namespaces -o=wide
alias kgdepslallowide = kubecolor get deployment --show-labels --all-namespaces -o=wide
alias kgstsslallowide = kubecolor get statefulset --show-labels --all-namespaces -o=wide
alias kgsvcslallowide = kubecolor get service --show-labels --all-namespaces -o=wide
alias kgingslallowide = kubecolor get ingress --show-labels --all-namespaces -o=wide
alias kgcmslallowide = kubecolor get configmap --show-labels --all-namespaces -o=wide
alias kgsecslallowide = kubecolor get secret --show-labels --all-namespaces -o=wide
alias kgnsslallowide = kubecolor get namespaces --show-labels --all-namespaces -o=wide
alias kgallwowide = kubecolor get --all-namespaces --watch -o=wide
alias kgpoallwowide = kubecolor get pods --all-namespaces --watch -o=wide
alias kgdepallwowide = kubecolor get deployment --all-namespaces --watch -o=wide
alias kgstsallwowide = kubecolor get statefulset --all-namespaces --watch -o=wide
alias kgsvcallwowide = kubecolor get service --all-namespaces --watch -o=wide
alias kgingallwowide = kubecolor get ingress --all-namespaces --watch -o=wide
alias kgcmallwowide = kubecolor get configmap --all-namespaces --watch -o=wide
alias kgsecallwowide = kubecolor get secret --all-namespaces --watch -o=wide
alias kgnsallwowide = kubecolor get namespaces --all-namespaces --watch -o=wide
alias kgwowideall = kubecolor get --watch -o=wide --all-namespaces
alias kgpowowideall = kubecolor get pods --watch -o=wide --all-namespaces
alias kgdepwowideall = kubecolor get deployment --watch -o=wide --all-namespaces
alias kgstswowideall = kubecolor get statefulset --watch -o=wide --all-namespaces
alias kgsvcwowideall = kubecolor get service --watch -o=wide --all-namespaces
alias kgingwowideall = kubecolor get ingress --watch -o=wide --all-namespaces
alias kgcmwowideall = kubecolor get configmap --watch -o=wide --all-namespaces
alias kgsecwowideall = kubecolor get secret --watch -o=wide --all-namespaces
alias kgnswowideall = kubecolor get namespaces --watch -o=wide --all-namespaces
alias kgwallowide = kubecolor get --watch --all-namespaces -o=wide
alias kgpowallowide = kubecolor get pods --watch --all-namespaces -o=wide
alias kgdepwallowide = kubecolor get deployment --watch --all-namespaces -o=wide
alias kgstswallowide = kubecolor get statefulset --watch --all-namespaces -o=wide
alias kgsvcwallowide = kubecolor get service --watch --all-namespaces -o=wide
alias kgingwallowide = kubecolor get ingress --watch --all-namespaces -o=wide
alias kgcmwallowide = kubecolor get configmap --watch --all-namespaces -o=wide
alias kgsecwallowide = kubecolor get secret --watch --all-namespaces -o=wide
alias kgnswallowide = kubecolor get namespaces --watch --all-namespaces -o=wide
alias kgslwowide = kubecolor get --show-labels --watch -o=wide
alias ksysgslwowide = kubecolor --namespace=kube-system get --show-labels --watch -o=wide
alias kgposlwowide = kubecolor get pods --show-labels --watch -o=wide
alias ksysgposlwowide = kubecolor --namespace=kube-system get pods --show-labels --watch -o=wide
alias kgdepslwowide = kubecolor get deployment --show-labels --watch -o=wide
alias ksysgdepslwowide = kubecolor --namespace=kube-system get deployment --show-labels --watch -o=wide
alias kgstsslwowide = kubecolor get statefulset --show-labels --watch -o=wide
alias ksysgstsslwowide = kubecolor --namespace=kube-system get statefulset --show-labels --watch -o=wide
alias kgsvcslwowide = kubecolor get service --show-labels --watch -o=wide
alias ksysgsvcslwowide = kubecolor --namespace=kube-system get service --show-labels --watch -o=wide
alias kgingslwowide = kubecolor get ingress --show-labels --watch -o=wide
alias ksysgingslwowide = kubecolor --namespace=kube-system get ingress --show-labels --watch -o=wide
alias kgcmslwowide = kubecolor get configmap --show-labels --watch -o=wide
alias ksysgcmslwowide = kubecolor --namespace=kube-system get configmap --show-labels --watch -o=wide
alias kgsecslwowide = kubecolor get secret --show-labels --watch -o=wide
alias ksysgsecslwowide = kubecolor --namespace=kube-system get secret --show-labels --watch -o=wide
alias kgnoslwowide = kubecolor get nodes --show-labels --watch -o=wide
alias kgnsslwowide = kubecolor get namespaces --show-labels --watch -o=wide
alias kgwowidesl = kubecolor get --watch -o=wide --show-labels
alias ksysgwowidesl = kubecolor --namespace=kube-system get --watch -o=wide --show-labels
alias kgpowowidesl = kubecolor get pods --watch -o=wide --show-labels
alias ksysgpowowidesl = kubecolor --namespace=kube-system get pods --watch -o=wide --show-labels
alias kgdepwowidesl = kubecolor get deployment --watch -o=wide --show-labels
alias ksysgdepwowidesl = kubecolor --namespace=kube-system get deployment --watch -o=wide --show-labels
alias kgstswowidesl = kubecolor get statefulset --watch -o=wide --show-labels
alias ksysgstswowidesl = kubecolor --namespace=kube-system get statefulset --watch -o=wide --show-labels
alias kgsvcwowidesl = kubecolor get service --watch -o=wide --show-labels
alias ksysgsvcwowidesl = kubecolor --namespace=kube-system get service --watch -o=wide --show-labels
alias kgingwowidesl = kubecolor get ingress --watch -o=wide --show-labels
alias ksysgingwowidesl = kubecolor --namespace=kube-system get ingress --watch -o=wide --show-labels
alias kgcmwowidesl = kubecolor get configmap --watch -o=wide --show-labels
alias ksysgcmwowidesl = kubecolor --namespace=kube-system get configmap --watch -o=wide --show-labels
alias kgsecwowidesl = kubecolor get secret --watch -o=wide --show-labels
alias ksysgsecwowidesl = kubecolor --namespace=kube-system get secret --watch -o=wide --show-labels
alias kgnowowidesl = kubecolor get nodes --watch -o=wide --show-labels
alias kgnswowidesl = kubecolor get namespaces --watch -o=wide --show-labels
alias kgwslowide = kubecolor get --watch --show-labels -o=wide
alias ksysgwslowide = kubecolor --namespace=kube-system get --watch --show-labels -o=wide
alias kgpowslowide = kubecolor get pods --watch --show-labels -o=wide
alias ksysgpowslowide = kubecolor --namespace=kube-system get pods --watch --show-labels -o=wide
alias kgdepwslowide = kubecolor get deployment --watch --show-labels -o=wide
alias ksysgdepwslowide = kubecolor --namespace=kube-system get deployment --watch --show-labels -o=wide
alias kgstswslowide = kubecolor get statefulset --watch --show-labels -o=wide
alias ksysgstswslowide = kubecolor --namespace=kube-system get statefulset --watch --show-labels -o=wide
alias kgsvcwslowide = kubecolor get service --watch --show-labels -o=wide
alias ksysgsvcwslowide = kubecolor --namespace=kube-system get service --watch --show-labels -o=wide
alias kgingwslowide = kubecolor get ingress --watch --show-labels -o=wide
alias ksysgingwslowide = kubecolor --namespace=kube-system get ingress --watch --show-labels -o=wide
alias kgcmwslowide = kubecolor get configmap --watch --show-labels -o=wide
alias ksysgcmwslowide = kubecolor --namespace=kube-system get configmap --watch --show-labels -o=wide
alias kgsecwslowide = kubecolor get secret --watch --show-labels -o=wide
alias ksysgsecwslowide = kubecolor --namespace=kube-system get secret --watch --show-labels -o=wide
alias kgnowslowide = kubecolor get nodes --watch --show-labels -o=wide
alias kgnswslowide = kubecolor get namespaces --watch --show-labels -o=wide
alias kgallwojson = kubecolor get --all-namespaces --watch -o=json
alias kgpoallwojson = kubecolor get pods --all-namespaces --watch -o=json
alias kgdepallwojson = kubecolor get deployment --all-namespaces --watch -o=json
alias kgstsallwojson = kubecolor get statefulset --all-namespaces --watch -o=json
alias kgsvcallwojson = kubecolor get service --all-namespaces --watch -o=json
alias kgingallwojson = kubecolor get ingress --all-namespaces --watch -o=json
alias kgcmallwojson = kubecolor get configmap --all-namespaces --watch -o=json
alias kgsecallwojson = kubecolor get secret --all-namespaces --watch -o=json
alias kgnsallwojson = kubecolor get namespaces --all-namespaces --watch -o=json
alias kgwojsonall = kubecolor get --watch -o=json --all-namespaces
alias kgpowojsonall = kubecolor get pods --watch -o=json --all-namespaces
alias kgdepwojsonall = kubecolor get deployment --watch -o=json --all-namespaces
alias kgstswojsonall = kubecolor get statefulset --watch -o=json --all-namespaces
alias kgsvcwojsonall = kubecolor get service --watch -o=json --all-namespaces
alias kgingwojsonall = kubecolor get ingress --watch -o=json --all-namespaces
alias kgcmwojsonall = kubecolor get configmap --watch -o=json --all-namespaces
alias kgsecwojsonall = kubecolor get secret --watch -o=json --all-namespaces
alias kgnswojsonall = kubecolor get namespaces --watch -o=json --all-namespaces
alias kgwallojson = kubecolor get --watch --all-namespaces -o=json
alias kgpowallojson = kubecolor get pods --watch --all-namespaces -o=json
alias kgdepwallojson = kubecolor get deployment --watch --all-namespaces -o=json
alias kgstswallojson = kubecolor get statefulset --watch --all-namespaces -o=json
alias kgsvcwallojson = kubecolor get service --watch --all-namespaces -o=json
alias kgingwallojson = kubecolor get ingress --watch --all-namespaces -o=json
alias kgcmwallojson = kubecolor get configmap --watch --all-namespaces -o=json
alias kgsecwallojson = kubecolor get secret --watch --all-namespaces -o=json
alias kgnswallojson = kubecolor get namespaces --watch --all-namespaces -o=json
alias kgallslw = kubecolor get --all-namespaces --show-labels --watch
alias kgpoallslw = kubecolor get pods --all-namespaces --show-labels --watch
alias kgdepallslw = kubecolor get deployment --all-namespaces --show-labels --watch
alias kgstsallslw = kubecolor get statefulset --all-namespaces --show-labels --watch
alias kgsvcallslw = kubecolor get service --all-namespaces --show-labels --watch
alias kgingallslw = kubecolor get ingress --all-namespaces --show-labels --watch
alias kgcmallslw = kubecolor get configmap --all-namespaces --show-labels --watch
alias kgsecallslw = kubecolor get secret --all-namespaces --show-labels --watch
alias kgnsallslw = kubecolor get namespaces --all-namespaces --show-labels --watch
alias kgallwsl = kubecolor get --all-namespaces --watch --show-labels
alias kgpoallwsl = kubecolor get pods --all-namespaces --watch --show-labels
alias kgdepallwsl = kubecolor get deployment --all-namespaces --watch --show-labels
alias kgstsallwsl = kubecolor get statefulset --all-namespaces --watch --show-labels
alias kgsvcallwsl = kubecolor get service --all-namespaces --watch --show-labels
alias kgingallwsl = kubecolor get ingress --all-namespaces --watch --show-labels
alias kgcmallwsl = kubecolor get configmap --all-namespaces --watch --show-labels
alias kgsecallwsl = kubecolor get secret --all-namespaces --watch --show-labels
alias kgnsallwsl = kubecolor get namespaces --all-namespaces --watch --show-labels
alias kgslallw = kubecolor get --show-labels --all-namespaces --watch
alias kgposlallw = kubecolor get pods --show-labels --all-namespaces --watch
alias kgdepslallw = kubecolor get deployment --show-labels --all-namespaces --watch
alias kgstsslallw = kubecolor get statefulset --show-labels --all-namespaces --watch
alias kgsvcslallw = kubecolor get service --show-labels --all-namespaces --watch
alias kgingslallw = kubecolor get ingress --show-labels --all-namespaces --watch
alias kgcmslallw = kubecolor get configmap --show-labels --all-namespaces --watch
alias kgsecslallw = kubecolor get secret --show-labels --all-namespaces --watch
alias kgnsslallw = kubecolor get namespaces --show-labels --all-namespaces --watch
alias kgslwall = kubecolor get --show-labels --watch --all-namespaces
alias kgposlwall = kubecolor get pods --show-labels --watch --all-namespaces
alias kgdepslwall = kubecolor get deployment --show-labels --watch --all-namespaces
alias kgstsslwall = kubecolor get statefulset --show-labels --watch --all-namespaces
alias kgsvcslwall = kubecolor get service --show-labels --watch --all-namespaces
alias kgingslwall = kubecolor get ingress --show-labels --watch --all-namespaces
alias kgcmslwall = kubecolor get configmap --show-labels --watch --all-namespaces
alias kgsecslwall = kubecolor get secret --show-labels --watch --all-namespaces
alias kgnsslwall = kubecolor get namespaces --show-labels --watch --all-namespaces
alias kgwallsl = kubecolor get --watch --all-namespaces --show-labels
alias kgpowallsl = kubecolor get pods --watch --all-namespaces --show-labels
alias kgdepwallsl = kubecolor get deployment --watch --all-namespaces --show-labels
alias kgstswallsl = kubecolor get statefulset --watch --all-namespaces --show-labels
alias kgsvcwallsl = kubecolor get service --watch --all-namespaces --show-labels
alias kgingwallsl = kubecolor get ingress --watch --all-namespaces --show-labels
alias kgcmwallsl = kubecolor get configmap --watch --all-namespaces --show-labels
alias kgsecwallsl = kubecolor get secret --watch --all-namespaces --show-labels
alias kgnswallsl = kubecolor get namespaces --watch --all-namespaces --show-labels
alias kgwslall = kubecolor get --watch --show-labels --all-namespaces
alias kgpowslall = kubecolor get pods --watch --show-labels --all-namespaces
alias kgdepwslall = kubecolor get deployment --watch --show-labels --all-namespaces
alias kgstswslall = kubecolor get statefulset --watch --show-labels --all-namespaces
alias kgsvcwslall = kubecolor get service --watch --show-labels --all-namespaces
alias kgingwslall = kubecolor get ingress --watch --show-labels --all-namespaces
alias kgcmwslall = kubecolor get configmap --watch --show-labels --all-namespaces
alias kgsecwslall = kubecolor get secret --watch --show-labels --all-namespaces
alias kgnswslall = kubecolor get namespaces --watch --show-labels --all-namespaces
alias kgallslwowide = kubecolor get --all-namespaces --show-labels --watch -o=wide
alias kgpoallslwowide = kubecolor get pods --all-namespaces --show-labels --watch -o=wide
alias kgdepallslwowide = kubecolor get deployment --all-namespaces --show-labels --watch -o=wide
alias kgstsallslwowide = kubecolor get statefulset --all-namespaces --show-labels --watch -o=wide
alias kgsvcallslwowide = kubecolor get service --all-namespaces --show-labels --watch -o=wide
alias kgingallslwowide = kubecolor get ingress --all-namespaces --show-labels --watch -o=wide
alias kgcmallslwowide = kubecolor get configmap --all-namespaces --show-labels --watch -o=wide
alias kgsecallslwowide = kubecolor get secret --all-namespaces --show-labels --watch -o=wide
alias kgnsallslwowide = kubecolor get namespaces --all-namespaces --show-labels --watch -o=wide
alias kgallwowidesl = kubecolor get --all-namespaces --watch -o=wide --show-labels
alias kgpoallwowidesl = kubecolor get pods --all-namespaces --watch -o=wide --show-labels
alias kgdepallwowidesl = kubecolor get deployment --all-namespaces --watch -o=wide --show-labels
alias kgstsallwowidesl = kubecolor get statefulset --all-namespaces --watch -o=wide --show-labels
alias kgsvcallwowidesl = kubecolor get service --all-namespaces --watch -o=wide --show-labels
alias kgingallwowidesl = kubecolor get ingress --all-namespaces --watch -o=wide --show-labels
alias kgcmallwowidesl = kubecolor get configmap --all-namespaces --watch -o=wide --show-labels
alias kgsecallwowidesl = kubecolor get secret --all-namespaces --watch -o=wide --show-labels
alias kgnsallwowidesl = kubecolor get namespaces --all-namespaces --watch -o=wide --show-labels
alias kgallwslowide = kubecolor get --all-namespaces --watch --show-labels -o=wide
alias kgpoallwslowide = kubecolor get pods --all-namespaces --watch --show-labels -o=wide
alias kgdepallwslowide = kubecolor get deployment --all-namespaces --watch --show-labels -o=wide
alias kgstsallwslowide = kubecolor get statefulset --all-namespaces --watch --show-labels -o=wide
alias kgsvcallwslowide = kubecolor get service --all-namespaces --watch --show-labels -o=wide
alias kgingallwslowide = kubecolor get ingress --all-namespaces --watch --show-labels -o=wide
alias kgcmallwslowide = kubecolor get configmap --all-namespaces --watch --show-labels -o=wide
alias kgsecallwslowide = kubecolor get secret --all-namespaces --watch --show-labels -o=wide
alias kgnsallwslowide = kubecolor get namespaces --all-namespaces --watch --show-labels -o=wide
alias kgslallwowide = kubecolor get --show-labels --all-namespaces --watch -o=wide
alias kgposlallwowide = kubecolor get pods --show-labels --all-namespaces --watch -o=wide
alias kgdepslallwowide = kubecolor get deployment --show-labels --all-namespaces --watch -o=wide
alias kgstsslallwowide = kubecolor get statefulset --show-labels --all-namespaces --watch -o=wide
alias kgsvcslallwowide = kubecolor get service --show-labels --all-namespaces --watch -o=wide
alias kgingslallwowide = kubecolor get ingress --show-labels --all-namespaces --watch -o=wide
alias kgcmslallwowide = kubecolor get configmap --show-labels --all-namespaces --watch -o=wide
alias kgsecslallwowide = kubecolor get secret --show-labels --all-namespaces --watch -o=wide
alias kgnsslallwowide = kubecolor get namespaces --show-labels --all-namespaces --watch -o=wide
alias kgslwowideall = kubecolor get --show-labels --watch -o=wide --all-namespaces
alias kgposlwowideall = kubecolor get pods --show-labels --watch -o=wide --all-namespaces
alias kgdepslwowideall = kubecolor get deployment --show-labels --watch -o=wide --all-namespaces
alias kgstsslwowideall = kubecolor get statefulset --show-labels --watch -o=wide --all-namespaces
alias kgsvcslwowideall = kubecolor get service --show-labels --watch -o=wide --all-namespaces
alias kgingslwowideall = kubecolor get ingress --show-labels --watch -o=wide --all-namespaces
alias kgcmslwowideall = kubecolor get configmap --show-labels --watch -o=wide --all-namespaces
alias kgsecslwowideall = kubecolor get secret --show-labels --watch -o=wide --all-namespaces
alias kgnsslwowideall = kubecolor get namespaces --show-labels --watch -o=wide --all-namespaces
alias kgslwallowide = kubecolor get --show-labels --watch --all-namespaces -o=wide
alias kgposlwallowide = kubecolor get pods --show-labels --watch --all-namespaces -o=wide
alias kgdepslwallowide = kubecolor get deployment --show-labels --watch --all-namespaces -o=wide
alias kgstsslwallowide = kubecolor get statefulset --show-labels --watch --all-namespaces -o=wide
alias kgsvcslwallowide = kubecolor get service --show-labels --watch --all-namespaces -o=wide
alias kgingslwallowide = kubecolor get ingress --show-labels --watch --all-namespaces -o=wide
alias kgcmslwallowide = kubecolor get configmap --show-labels --watch --all-namespaces -o=wide
alias kgsecslwallowide = kubecolor get secret --show-labels --watch --all-namespaces -o=wide
alias kgnsslwallowide = kubecolor get namespaces --show-labels --watch --all-namespaces -o=wide
alias kgwowideallsl = kubecolor get --watch -o=wide --all-namespaces --show-labels
alias kgpowowideallsl = kubecolor get pods --watch -o=wide --all-namespaces --show-labels
alias kgdepwowideallsl = kubecolor get deployment --watch -o=wide --all-namespaces --show-labels
alias kgstswowideallsl = kubecolor get statefulset --watch -o=wide --all-namespaces --show-labels
alias kgsvcwowideallsl = kubecolor get service --watch -o=wide --all-namespaces --show-labels
alias kgingwowideallsl = kubecolor get ingress --watch -o=wide --all-namespaces --show-labels
alias kgcmwowideallsl = kubecolor get configmap --watch -o=wide --all-namespaces --show-labels
alias kgsecwowideallsl = kubecolor get secret --watch -o=wide --all-namespaces --show-labels
alias kgnswowideallsl = kubecolor get namespaces --watch -o=wide --all-namespaces --show-labels
alias kgwowideslall = kubecolor get --watch -o=wide --show-labels --all-namespaces
alias kgpowowideslall = kubecolor get pods --watch -o=wide --show-labels --all-namespaces
alias kgdepwowideslall = kubecolor get deployment --watch -o=wide --show-labels --all-namespaces
alias kgstswowideslall = kubecolor get statefulset --watch -o=wide --show-labels --all-namespaces
alias kgsvcwowideslall = kubecolor get service --watch -o=wide --show-labels --all-namespaces
alias kgingwowideslall = kubecolor get ingress --watch -o=wide --show-labels --all-namespaces
alias kgcmwowideslall = kubecolor get configmap --watch -o=wide --show-labels --all-namespaces
alias kgsecwowideslall = kubecolor get secret --watch -o=wide --show-labels --all-namespaces
alias kgnswowideslall = kubecolor get namespaces --watch -o=wide --show-labels --all-namespaces
alias kgwallowidesl = kubecolor get --watch --all-namespaces -o=wide --show-labels
alias kgpowallowidesl = kubecolor get pods --watch --all-namespaces -o=wide --show-labels
alias kgdepwallowidesl = kubecolor get deployment --watch --all-namespaces -o=wide --show-labels
alias kgstswallowidesl = kubecolor get statefulset --watch --all-namespaces -o=wide --show-labels
alias kgsvcwallowidesl = kubecolor get service --watch --all-namespaces -o=wide --show-labels
alias kgingwallowidesl = kubecolor get ingress --watch --all-namespaces -o=wide --show-labels
alias kgcmwallowidesl = kubecolor get configmap --watch --all-namespaces -o=wide --show-labels
alias kgsecwallowidesl = kubecolor get secret --watch --all-namespaces -o=wide --show-labels
alias kgnswallowidesl = kubecolor get namespaces --watch --all-namespaces -o=wide --show-labels
alias kgwallslowide = kubecolor get --watch --all-namespaces --show-labels -o=wide
alias kgpowallslowide = kubecolor get pods --watch --all-namespaces --show-labels -o=wide
alias kgdepwallslowide = kubecolor get deployment --watch --all-namespaces --show-labels -o=wide
alias kgstswallslowide = kubecolor get statefulset --watch --all-namespaces --show-labels -o=wide
alias kgsvcwallslowide = kubecolor get service --watch --all-namespaces --show-labels -o=wide
alias kgingwallslowide = kubecolor get ingress --watch --all-namespaces --show-labels -o=wide
alias kgcmwallslowide = kubecolor get configmap --watch --all-namespaces --show-labels -o=wide
alias kgsecwallslowide = kubecolor get secret --watch --all-namespaces --show-labels -o=wide
alias kgnswallslowide = kubecolor get namespaces --watch --all-namespaces --show-labels -o=wide
alias kgwslowideall = kubecolor get --watch --show-labels -o=wide --all-namespaces
alias kgpowslowideall = kubecolor get pods --watch --show-labels -o=wide --all-namespaces
alias kgdepwslowideall = kubecolor get deployment --watch --show-labels -o=wide --all-namespaces
alias kgstswslowideall = kubecolor get statefulset --watch --show-labels -o=wide --all-namespaces
alias kgsvcwslowideall = kubecolor get service --watch --show-labels -o=wide --all-namespaces
alias kgingwslowideall = kubecolor get ingress --watch --show-labels -o=wide --all-namespaces
alias kgcmwslowideall = kubecolor get configmap --watch --show-labels -o=wide --all-namespaces
alias kgsecwslowideall = kubecolor get secret --watch --show-labels -o=wide --all-namespaces
alias kgnswslowideall = kubecolor get namespaces --watch --show-labels -o=wide --all-namespaces
alias kgwslallowide = kubecolor get --watch --show-labels --all-namespaces -o=wide
alias kgpowslallowide = kubecolor get pods --watch --show-labels --all-namespaces -o=wide
alias kgdepwslallowide = kubecolor get deployment --watch --show-labels --all-namespaces -o=wide
alias kgstswslallowide = kubecolor get statefulset --watch --show-labels --all-namespaces -o=wide
alias kgsvcwslallowide = kubecolor get service --watch --show-labels --all-namespaces -o=wide
alias kgingwslallowide = kubecolor get ingress --watch --show-labels --all-namespaces -o=wide
alias kgcmwslallowide = kubecolor get configmap --watch --show-labels --all-namespaces -o=wide
alias kgsecwslallowide = kubecolor get secret --watch --show-labels --all-namespaces -o=wide
alias kgnswslallowide = kubecolor get namespaces --watch --show-labels --all-namespaces -o=wide
alias kgf = kubecolor get --recursive -f
alias kdf = kubecolor describe --recursive -f
alias krmf = kubecolor delete --recursive -f
alias kgoyamlf = kubecolor get -o=yaml --recursive -f
alias kgowidef = kubecolor get -o=wide --recursive -f
alias kgojsonf = kubecolor get -o=json --recursive -f
alias kgslf = kubecolor get --show-labels --recursive -f
alias kgwf = kubecolor get --watch --recursive -f
alias kgwoyamlf = kubecolor get --watch -o=yaml --recursive -f
alias kgowideslf = kubecolor get -o=wide --show-labels --recursive -f
alias kgslowidef = kubecolor get --show-labels -o=wide --recursive -f
alias kgwowidef = kubecolor get --watch -o=wide --recursive -f
alias kgwojsonf = kubecolor get --watch -o=json --recursive -f
alias kgslwf = kubecolor get --show-labels --watch --recursive -f
alias kgwslf = kubecolor get --watch --show-labels --recursive -f
alias kgslwowidef = kubecolor get --show-labels --watch -o=wide --recursive -f
alias kgwowideslf = kubecolor get --watch -o=wide --show-labels --recursive -f
alias kgwslowidef = kubecolor get --watch --show-labels -o=wide --recursive -f
alias kgl = kubecolor get -l
alias ksysgl = kubecolor --namespace=kube-system get -l
alias kdl = kubecolor describe -l
alias ksysdl = kubecolor --namespace=kube-system describe -l
alias krml = kubecolor delete -l
alias ksysrml = kubecolor --namespace=kube-system delete -l
alias kgpol = kubecolor get pods -l
alias ksysgpol = kubecolor --namespace=kube-system get pods -l
alias kdpol = kubecolor describe pods -l
alias ksysdpol = kubecolor --namespace=kube-system describe pods -l
alias krmpol = kubecolor delete pods -l
alias ksysrmpol = kubecolor --namespace=kube-system delete pods -l
alias kgdepl = kubecolor get deployment -l
alias ksysgdepl = kubecolor --namespace=kube-system get deployment -l
alias kddepl = kubecolor describe deployment -l
alias ksysddepl = kubecolor --namespace=kube-system describe deployment -l
alias krmdepl = kubecolor delete deployment -l
alias ksysrmdepl = kubecolor --namespace=kube-system delete deployment -l
alias kgstsl = kubecolor get statefulset -l
alias ksysgstsl = kubecolor --namespace=kube-system get statefulset -l
alias kdstsl = kubecolor describe statefulset -l
alias ksysdstsl = kubecolor --namespace=kube-system describe statefulset -l
alias krmstsl = kubecolor delete statefulset -l
alias ksysrmstsl = kubecolor --namespace=kube-system delete statefulset -l
alias kgsvcl = kubecolor get service -l
alias ksysgsvcl = kubecolor --namespace=kube-system get service -l
alias kdsvcl = kubecolor describe service -l
alias ksysdsvcl = kubecolor --namespace=kube-system describe service -l
alias krmsvcl = kubecolor delete service -l
alias ksysrmsvcl = kubecolor --namespace=kube-system delete service -l
alias kgingl = kubecolor get ingress -l
alias ksysgingl = kubecolor --namespace=kube-system get ingress -l
alias kdingl = kubecolor describe ingress -l
alias ksysdingl = kubecolor --namespace=kube-system describe ingress -l
alias krmingl = kubecolor delete ingress -l
alias ksysrmingl = kubecolor --namespace=kube-system delete ingress -l
alias kgcml = kubecolor get configmap -l
alias ksysgcml = kubecolor --namespace=kube-system get configmap -l
alias kdcml = kubecolor describe configmap -l
alias ksysdcml = kubecolor --namespace=kube-system describe configmap -l
alias krmcml = kubecolor delete configmap -l
alias ksysrmcml = kubecolor --namespace=kube-system delete configmap -l
alias kgsecl = kubecolor get secret -l
alias ksysgsecl = kubecolor --namespace=kube-system get secret -l
alias kdsecl = kubecolor describe secret -l
alias ksysdsecl = kubecolor --namespace=kube-system describe secret -l
alias krmsecl = kubecolor delete secret -l
alias ksysrmsecl = kubecolor --namespace=kube-system delete secret -l
alias kgnol = kubecolor get nodes -l
alias kdnol = kubecolor describe nodes -l
alias kgnsl = kubecolor get namespaces -l
alias kdnsl = kubecolor describe namespaces -l
alias krmnsl = kubecolor delete namespaces -l
alias kgoyamll = kubecolor get -o=yaml -l
alias ksysgoyamll = kubecolor --namespace=kube-system get -o=yaml -l
alias kgpooyamll = kubecolor get pods -o=yaml -l
alias ksysgpooyamll = kubecolor --namespace=kube-system get pods -o=yaml -l
alias kgdepoyamll = kubecolor get deployment -o=yaml -l
alias ksysgdepoyamll = kubecolor --namespace=kube-system get deployment -o=yaml -l
alias kgstsoyamll = kubecolor get statefulset -o=yaml -l
alias ksysgstsoyamll = kubecolor --namespace=kube-system get statefulset -o=yaml -l
alias kgsvcoyamll = kubecolor get service -o=yaml -l
alias ksysgsvcoyamll = kubecolor --namespace=kube-system get service -o=yaml -l
alias kgingoyamll = kubecolor get ingress -o=yaml -l
alias ksysgingoyamll = kubecolor --namespace=kube-system get ingress -o=yaml -l
alias kgcmoyamll = kubecolor get configmap -o=yaml -l
alias ksysgcmoyamll = kubecolor --namespace=kube-system get configmap -o=yaml -l
alias kgsecoyamll = kubecolor get secret -o=yaml -l
alias ksysgsecoyamll = kubecolor --namespace=kube-system get secret -o=yaml -l
alias kgnooyamll = kubecolor get nodes -o=yaml -l
alias kgnsoyamll = kubecolor get namespaces -o=yaml -l
alias kgowidel = kubecolor get -o=wide -l
alias ksysgowidel = kubecolor --namespace=kube-system get -o=wide -l
alias kgpoowidel = kubecolor get pods -o=wide -l
alias ksysgpoowidel = kubecolor --namespace=kube-system get pods -o=wide -l
alias kgdepowidel = kubecolor get deployment -o=wide -l
alias ksysgdepowidel = kubecolor --namespace=kube-system get deployment -o=wide -l
alias kgstsowidel = kubecolor get statefulset -o=wide -l
alias ksysgstsowidel = kubecolor --namespace=kube-system get statefulset -o=wide -l
alias kgsvcowidel = kubecolor get service -o=wide -l
alias ksysgsvcowidel = kubecolor --namespace=kube-system get service -o=wide -l
alias kgingowidel = kubecolor get ingress -o=wide -l
alias ksysgingowidel = kubecolor --namespace=kube-system get ingress -o=wide -l
alias kgcmowidel = kubecolor get configmap -o=wide -l
alias ksysgcmowidel = kubecolor --namespace=kube-system get configmap -o=wide -l
alias kgsecowidel = kubecolor get secret -o=wide -l
alias ksysgsecowidel = kubecolor --namespace=kube-system get secret -o=wide -l
alias kgnoowidel = kubecolor get nodes -o=wide -l
alias kgnsowidel = kubecolor get namespaces -o=wide -l
alias kgojsonl = kubecolor get -o=json -l
alias ksysgojsonl = kubecolor --namespace=kube-system get -o=json -l
alias kgpoojsonl = kubecolor get pods -o=json -l
alias ksysgpoojsonl = kubecolor --namespace=kube-system get pods -o=json -l
alias kgdepojsonl = kubecolor get deployment -o=json -l
alias ksysgdepojsonl = kubecolor --namespace=kube-system get deployment -o=json -l
alias kgstsojsonl = kubecolor get statefulset -o=json -l
alias ksysgstsojsonl = kubecolor --namespace=kube-system get statefulset -o=json -l
alias kgsvcojsonl = kubecolor get service -o=json -l
alias ksysgsvcojsonl = kubecolor --namespace=kube-system get service -o=json -l
alias kgingojsonl = kubecolor get ingress -o=json -l
alias ksysgingojsonl = kubecolor --namespace=kube-system get ingress -o=json -l
alias kgcmojsonl = kubecolor get configmap -o=json -l
alias ksysgcmojsonl = kubecolor --namespace=kube-system get configmap -o=json -l
alias kgsecojsonl = kubecolor get secret -o=json -l
alias ksysgsecojsonl = kubecolor --namespace=kube-system get secret -o=json -l
alias kgnoojsonl = kubecolor get nodes -o=json -l
alias kgnsojsonl = kubecolor get namespaces -o=json -l
alias kgsll = kubecolor get --show-labels -l
alias ksysgsll = kubecolor --namespace=kube-system get --show-labels -l
alias kgposll = kubecolor get pods --show-labels -l
alias ksysgposll = kubecolor --namespace=kube-system get pods --show-labels -l
alias kgdepsll = kubecolor get deployment --show-labels -l
alias ksysgdepsll = kubecolor --namespace=kube-system get deployment --show-labels -l
alias kgstssll = kubecolor get statefulset --show-labels -l
alias ksysgstssll = kubecolor --namespace=kube-system get statefulset --show-labels -l
alias kgsvcsll = kubecolor get service --show-labels -l
alias ksysgsvcsll = kubecolor --namespace=kube-system get service --show-labels -l
alias kgingsll = kubecolor get ingress --show-labels -l
alias ksysgingsll = kubecolor --namespace=kube-system get ingress --show-labels -l
alias kgcmsll = kubecolor get configmap --show-labels -l
alias ksysgcmsll = kubecolor --namespace=kube-system get configmap --show-labels -l
alias kgsecsll = kubecolor get secret --show-labels -l
alias ksysgsecsll = kubecolor --namespace=kube-system get secret --show-labels -l
alias kgnosll = kubecolor get nodes --show-labels -l
alias kgnssll = kubecolor get namespaces --show-labels -l
alias kgwl = kubecolor get --watch -l
alias ksysgwl = kubecolor --namespace=kube-system get --watch -l
alias kgpowl = kubecolor get pods --watch -l
alias ksysgpowl = kubecolor --namespace=kube-system get pods --watch -l
alias kgdepwl = kubecolor get deployment --watch -l
alias ksysgdepwl = kubecolor --namespace=kube-system get deployment --watch -l
alias kgstswl = kubecolor get statefulset --watch -l
alias ksysgstswl = kubecolor --namespace=kube-system get statefulset --watch -l
alias kgsvcwl = kubecolor get service --watch -l
alias ksysgsvcwl = kubecolor --namespace=kube-system get service --watch -l
alias kgingwl = kubecolor get ingress --watch -l
alias ksysgingwl = kubecolor --namespace=kube-system get ingress --watch -l
alias kgcmwl = kubecolor get configmap --watch -l
alias ksysgcmwl = kubecolor --namespace=kube-system get configmap --watch -l
alias kgsecwl = kubecolor get secret --watch -l
alias ksysgsecwl = kubecolor --namespace=kube-system get secret --watch -l
alias kgnowl = kubecolor get nodes --watch -l
alias kgnswl = kubecolor get namespaces --watch -l
alias kgwoyamll = kubecolor get --watch -o=yaml -l
alias ksysgwoyamll = kubecolor --namespace=kube-system get --watch -o=yaml -l
alias kgpowoyamll = kubecolor get pods --watch -o=yaml -l
alias ksysgpowoyamll = kubecolor --namespace=kube-system get pods --watch -o=yaml -l
alias kgdepwoyamll = kubecolor get deployment --watch -o=yaml -l
alias ksysgdepwoyamll = kubecolor --namespace=kube-system get deployment --watch -o=yaml -l
alias kgstswoyamll = kubecolor get statefulset --watch -o=yaml -l
alias ksysgstswoyamll = kubecolor --namespace=kube-system get statefulset --watch -o=yaml -l
alias kgsvcwoyamll = kubecolor get service --watch -o=yaml -l
alias ksysgsvcwoyamll = kubecolor --namespace=kube-system get service --watch -o=yaml -l
alias kgingwoyamll = kubecolor get ingress --watch -o=yaml -l
alias ksysgingwoyamll = kubecolor --namespace=kube-system get ingress --watch -o=yaml -l
alias kgcmwoyamll = kubecolor get configmap --watch -o=yaml -l
alias ksysgcmwoyamll = kubecolor --namespace=kube-system get configmap --watch -o=yaml -l
alias kgsecwoyamll = kubecolor get secret --watch -o=yaml -l
alias ksysgsecwoyamll = kubecolor --namespace=kube-system get secret --watch -o=yaml -l
alias kgnowoyamll = kubecolor get nodes --watch -o=yaml -l
alias kgnswoyamll = kubecolor get namespaces --watch -o=yaml -l
alias kgowidesll = kubecolor get -o=wide --show-labels -l
alias ksysgowidesll = kubecolor --namespace=kube-system get -o=wide --show-labels -l
alias kgpoowidesll = kubecolor get pods -o=wide --show-labels -l
alias ksysgpoowidesll = kubecolor --namespace=kube-system get pods -o=wide --show-labels -l
alias kgdepowidesll = kubecolor get deployment -o=wide --show-labels -l
alias ksysgdepowidesll = kubecolor --namespace=kube-system get deployment -o=wide --show-labels -l
alias kgstsowidesll = kubecolor get statefulset -o=wide --show-labels -l
alias ksysgstsowidesll = kubecolor --namespace=kube-system get statefulset -o=wide --show-labels -l
alias kgsvcowidesll = kubecolor get service -o=wide --show-labels -l
alias ksysgsvcowidesll = kubecolor --namespace=kube-system get service -o=wide --show-labels -l
alias kgingowidesll = kubecolor get ingress -o=wide --show-labels -l
alias ksysgingowidesll = kubecolor --namespace=kube-system get ingress -o=wide --show-labels -l
alias kgcmowidesll = kubecolor get configmap -o=wide --show-labels -l
alias ksysgcmowidesll = kubecolor --namespace=kube-system get configmap -o=wide --show-labels -l
alias kgsecowidesll = kubecolor get secret -o=wide --show-labels -l
alias ksysgsecowidesll = kubecolor --namespace=kube-system get secret -o=wide --show-labels -l
alias kgnoowidesll = kubecolor get nodes -o=wide --show-labels -l
alias kgnsowidesll = kubecolor get namespaces -o=wide --show-labels -l
alias kgslowidel = kubecolor get --show-labels -o=wide -l
alias ksysgslowidel = kubecolor --namespace=kube-system get --show-labels -o=wide -l
alias kgposlowidel = kubecolor get pods --show-labels -o=wide -l
alias ksysgposlowidel = kubecolor --namespace=kube-system get pods --show-labels -o=wide -l
alias kgdepslowidel = kubecolor get deployment --show-labels -o=wide -l
alias ksysgdepslowidel = kubecolor --namespace=kube-system get deployment --show-labels -o=wide -l
alias kgstsslowidel = kubecolor get statefulset --show-labels -o=wide -l
alias ksysgstsslowidel = kubecolor --namespace=kube-system get statefulset --show-labels -o=wide -l
alias kgsvcslowidel = kubecolor get service --show-labels -o=wide -l
alias ksysgsvcslowidel = kubecolor --namespace=kube-system get service --show-labels -o=wide -l
alias kgingslowidel = kubecolor get ingress --show-labels -o=wide -l
alias ksysgingslowidel = kubecolor --namespace=kube-system get ingress --show-labels -o=wide -l
alias kgcmslowidel = kubecolor get configmap --show-labels -o=wide -l
alias ksysgcmslowidel = kubecolor --namespace=kube-system get configmap --show-labels -o=wide -l
alias kgsecslowidel = kubecolor get secret --show-labels -o=wide -l
alias ksysgsecslowidel = kubecolor --namespace=kube-system get secret --show-labels -o=wide -l
alias kgnoslowidel = kubecolor get nodes --show-labels -o=wide -l
alias kgnsslowidel = kubecolor get namespaces --show-labels -o=wide -l
alias kgwowidel = kubecolor get --watch -o=wide -l
alias ksysgwowidel = kubecolor --namespace=kube-system get --watch -o=wide -l
alias kgpowowidel = kubecolor get pods --watch -o=wide -l
alias ksysgpowowidel = kubecolor --namespace=kube-system get pods --watch -o=wide -l
alias kgdepwowidel = kubecolor get deployment --watch -o=wide -l
alias ksysgdepwowidel = kubecolor --namespace=kube-system get deployment --watch -o=wide -l
alias kgstswowidel = kubecolor get statefulset --watch -o=wide -l
alias ksysgstswowidel = kubecolor --namespace=kube-system get statefulset --watch -o=wide -l
alias kgsvcwowidel = kubecolor get service --watch -o=wide -l
alias ksysgsvcwowidel = kubecolor --namespace=kube-system get service --watch -o=wide -l
alias kgingwowidel = kubecolor get ingress --watch -o=wide -l
alias ksysgingwowidel = kubecolor --namespace=kube-system get ingress --watch -o=wide -l
alias kgcmwowidel = kubecolor get configmap --watch -o=wide -l
alias ksysgcmwowidel = kubecolor --namespace=kube-system get configmap --watch -o=wide -l
alias kgsecwowidel = kubecolor get secret --watch -o=wide -l
alias ksysgsecwowidel = kubecolor --namespace=kube-system get secret --watch -o=wide -l
alias kgnowowidel = kubecolor get nodes --watch -o=wide -l
alias kgnswowidel = kubecolor get namespaces --watch -o=wide -l
alias kgwojsonl = kubecolor get --watch -o=json -l
alias ksysgwojsonl = kubecolor --namespace=kube-system get --watch -o=json -l
alias kgpowojsonl = kubecolor get pods --watch -o=json -l
alias ksysgpowojsonl = kubecolor --namespace=kube-system get pods --watch -o=json -l
alias kgdepwojsonl = kubecolor get deployment --watch -o=json -l
alias ksysgdepwojsonl = kubecolor --namespace=kube-system get deployment --watch -o=json -l
alias kgstswojsonl = kubecolor get statefulset --watch -o=json -l
alias ksysgstswojsonl = kubecolor --namespace=kube-system get statefulset --watch -o=json -l
alias kgsvcwojsonl = kubecolor get service --watch -o=json -l
alias ksysgsvcwojsonl = kubecolor --namespace=kube-system get service --watch -o=json -l
alias kgingwojsonl = kubecolor get ingress --watch -o=json -l
alias ksysgingwojsonl = kubecolor --namespace=kube-system get ingress --watch -o=json -l
alias kgcmwojsonl = kubecolor get configmap --watch -o=json -l
alias ksysgcmwojsonl = kubecolor --namespace=kube-system get configmap --watch -o=json -l
alias kgsecwojsonl = kubecolor get secret --watch -o=json -l
alias ksysgsecwojsonl = kubecolor --namespace=kube-system get secret --watch -o=json -l
alias kgnowojsonl = kubecolor get nodes --watch -o=json -l
alias kgnswojsonl = kubecolor get namespaces --watch -o=json -l
alias kgslwl = kubecolor get --show-labels --watch -l
alias ksysgslwl = kubecolor --namespace=kube-system get --show-labels --watch -l
alias kgposlwl = kubecolor get pods --show-labels --watch -l
alias ksysgposlwl = kubecolor --namespace=kube-system get pods --show-labels --watch -l
alias kgdepslwl = kubecolor get deployment --show-labels --watch -l
alias ksysgdepslwl = kubecolor --namespace=kube-system get deployment --show-labels --watch -l
alias kgstsslwl = kubecolor get statefulset --show-labels --watch -l
alias ksysgstsslwl = kubecolor --namespace=kube-system get statefulset --show-labels --watch -l
alias kgsvcslwl = kubecolor get service --show-labels --watch -l
alias ksysgsvcslwl = kubecolor --namespace=kube-system get service --show-labels --watch -l
alias kgingslwl = kubecolor get ingress --show-labels --watch -l
alias ksysgingslwl = kubecolor --namespace=kube-system get ingress --show-labels --watch -l
alias kgcmslwl = kubecolor get configmap --show-labels --watch -l
alias ksysgcmslwl = kubecolor --namespace=kube-system get configmap --show-labels --watch -l
alias kgsecslwl = kubecolor get secret --show-labels --watch -l
alias ksysgsecslwl = kubecolor --namespace=kube-system get secret --show-labels --watch -l
alias kgnoslwl = kubecolor get nodes --show-labels --watch -l
alias kgnsslwl = kubecolor get namespaces --show-labels --watch -l
alias kgwsll = kubecolor get --watch --show-labels -l
alias ksysgwsll = kubecolor --namespace=kube-system get --watch --show-labels -l
alias kgpowsll = kubecolor get pods --watch --show-labels -l
alias ksysgpowsll = kubecolor --namespace=kube-system get pods --watch --show-labels -l
alias kgdepwsll = kubecolor get deployment --watch --show-labels -l
alias ksysgdepwsll = kubecolor --namespace=kube-system get deployment --watch --show-labels -l
alias kgstswsll = kubecolor get statefulset --watch --show-labels -l
alias ksysgstswsll = kubecolor --namespace=kube-system get statefulset --watch --show-labels -l
alias kgsvcwsll = kubecolor get service --watch --show-labels -l
alias ksysgsvcwsll = kubecolor --namespace=kube-system get service --watch --show-labels -l
alias kgingwsll = kubecolor get ingress --watch --show-labels -l
alias ksysgingwsll = kubecolor --namespace=kube-system get ingress --watch --show-labels -l
alias kgcmwsll = kubecolor get configmap --watch --show-labels -l
alias ksysgcmwsll = kubecolor --namespace=kube-system get configmap --watch --show-labels -l
alias kgsecwsll = kubecolor get secret --watch --show-labels -l
alias ksysgsecwsll = kubecolor --namespace=kube-system get secret --watch --show-labels -l
alias kgnowsll = kubecolor get nodes --watch --show-labels -l
alias kgnswsll = kubecolor get namespaces --watch --show-labels -l
alias kgslwowidel = kubecolor get --show-labels --watch -o=wide -l
alias ksysgslwowidel = kubecolor --namespace=kube-system get --show-labels --watch -o=wide -l
alias kgposlwowidel = kubecolor get pods --show-labels --watch -o=wide -l
alias ksysgposlwowidel = kubecolor --namespace=kube-system get pods --show-labels --watch -o=wide -l
alias kgdepslwowidel = kubecolor get deployment --show-labels --watch -o=wide -l
alias ksysgdepslwowidel = kubecolor --namespace=kube-system get deployment --show-labels --watch -o=wide -l
alias kgstsslwowidel = kubecolor get statefulset --show-labels --watch -o=wide -l
alias ksysgstsslwowidel = kubecolor --namespace=kube-system get statefulset --show-labels --watch -o=wide -l
alias kgsvcslwowidel = kubecolor get service --show-labels --watch -o=wide -l
alias ksysgsvcslwowidel = kubecolor --namespace=kube-system get service --show-labels --watch -o=wide -l
alias kgingslwowidel = kubecolor get ingress --show-labels --watch -o=wide -l
alias ksysgingslwowidel = kubecolor --namespace=kube-system get ingress --show-labels --watch -o=wide -l
alias kgcmslwowidel = kubecolor get configmap --show-labels --watch -o=wide -l
alias ksysgcmslwowidel = kubecolor --namespace=kube-system get configmap --show-labels --watch -o=wide -l
alias kgsecslwowidel = kubecolor get secret --show-labels --watch -o=wide -l
alias ksysgsecslwowidel = kubecolor --namespace=kube-system get secret --show-labels --watch -o=wide -l
alias kgnoslwowidel = kubecolor get nodes --show-labels --watch -o=wide -l
alias kgnsslwowidel = kubecolor get namespaces --show-labels --watch -o=wide -l
alias kgwowidesll = kubecolor get --watch -o=wide --show-labels -l
alias ksysgwowidesll = kubecolor --namespace=kube-system get --watch -o=wide --show-labels -l
alias kgpowowidesll = kubecolor get pods --watch -o=wide --show-labels -l
alias ksysgpowowidesll = kubecolor --namespace=kube-system get pods --watch -o=wide --show-labels -l
alias kgdepwowidesll = kubecolor get deployment --watch -o=wide --show-labels -l
alias ksysgdepwowidesll = kubecolor --namespace=kube-system get deployment --watch -o=wide --show-labels -l
alias kgstswowidesll = kubecolor get statefulset --watch -o=wide --show-labels -l
alias ksysgstswowidesll = kubecolor --namespace=kube-system get statefulset --watch -o=wide --show-labels -l
alias kgsvcwowidesll = kubecolor get service --watch -o=wide --show-labels -l
alias ksysgsvcwowidesll = kubecolor --namespace=kube-system get service --watch -o=wide --show-labels -l
alias kgingwowidesll = kubecolor get ingress --watch -o=wide --show-labels -l
alias ksysgingwowidesll = kubecolor --namespace=kube-system get ingress --watch -o=wide --show-labels -l
alias kgcmwowidesll = kubecolor get configmap --watch -o=wide --show-labels -l
alias ksysgcmwowidesll = kubecolor --namespace=kube-system get configmap --watch -o=wide --show-labels -l
alias kgsecwowidesll = kubecolor get secret --watch -o=wide --show-labels -l
alias ksysgsecwowidesll = kubecolor --namespace=kube-system get secret --watch -o=wide --show-labels -l
alias kgnowowidesll = kubecolor get nodes --watch -o=wide --show-labels -l
alias kgnswowidesll = kubecolor get namespaces --watch -o=wide --show-labels -l
alias kgwslowidel = kubecolor get --watch --show-labels -o=wide -l
alias ksysgwslowidel = kubecolor --namespace=kube-system get --watch --show-labels -o=wide -l
alias kgpowslowidel = kubecolor get pods --watch --show-labels -o=wide -l
alias ksysgpowslowidel = kubecolor --namespace=kube-system get pods --watch --show-labels -o=wide -l
alias kgdepwslowidel = kubecolor get deployment --watch --show-labels -o=wide -l
alias ksysgdepwslowidel = kubecolor --namespace=kube-system get deployment --watch --show-labels -o=wide -l
alias kgstswslowidel = kubecolor get statefulset --watch --show-labels -o=wide -l
alias ksysgstswslowidel = kubecolor --namespace=kube-system get statefulset --watch --show-labels -o=wide -l
alias kgsvcwslowidel = kubecolor get service --watch --show-labels -o=wide -l
alias ksysgsvcwslowidel = kubecolor --namespace=kube-system get service --watch --show-labels -o=wide -l
alias kgingwslowidel = kubecolor get ingress --watch --show-labels -o=wide -l
alias ksysgingwslowidel = kubecolor --namespace=kube-system get ingress --watch --show-labels -o=wide -l
alias kgcmwslowidel = kubecolor get configmap --watch --show-labels -o=wide -l
alias ksysgcmwslowidel = kubecolor --namespace=kube-system get configmap --watch --show-labels -o=wide -l
alias kgsecwslowidel = kubecolor get secret --watch --show-labels -o=wide -l
alias ksysgsecwslowidel = kubecolor --namespace=kube-system get secret --watch --show-labels -o=wide -l
alias kgnowslowidel = kubecolor get nodes --watch --show-labels -o=wide -l
alias kgnswslowidel = kubecolor get namespaces --watch --show-labels -o=wide -l
alias kexn = kubecolor exec -i -t --namespace
alias klon = kubecolor logs -f --namespace
alias kpfn = kubecolor port-forward --namespace
alias kgn = kubecolor get --namespace
alias kdn = kubecolor describe --namespace
alias krmn = kubecolor delete --namespace
alias kgpon = kubecolor get pods --namespace
alias kdpon = kubecolor describe pods --namespace
alias krmpon = kubecolor delete pods --namespace
alias kgdepn = kubecolor get deployment --namespace
alias kddepn = kubecolor describe deployment --namespace
alias krmdepn = kubecolor delete deployment --namespace
alias kgstsn = kubecolor get statefulset --namespace
alias kdstsn = kubecolor describe statefulset --namespace
alias krmstsn = kubecolor delete statefulset --namespace
alias kgsvcn = kubecolor get service --namespace
alias kdsvcn = kubecolor describe service --namespace
alias krmsvcn = kubecolor delete service --namespace
alias kgingn = kubecolor get ingress --namespace
alias kdingn = kubecolor describe ingress --namespace
alias krmingn = kubecolor delete ingress --namespace
alias kgcmn = kubecolor get configmap --namespace
alias kdcmn = kubecolor describe configmap --namespace
alias krmcmn = kubecolor delete configmap --namespace
alias kgsecn = kubecolor get secret --namespace
alias kdsecn = kubecolor describe secret --namespace
alias krmsecn = kubecolor delete secret --namespace
alias kgoyamln = kubecolor get -o=yaml --namespace
alias kgpooyamln = kubecolor get pods -o=yaml --namespace
alias kgdepoyamln = kubecolor get deployment -o=yaml --namespace
alias kgstsoyamln = kubecolor get statefulset -o=yaml --namespace
alias kgsvcoyamln = kubecolor get service -o=yaml --namespace
alias kgingoyamln = kubecolor get ingress -o=yaml --namespace
alias kgcmoyamln = kubecolor get configmap -o=yaml --namespace
alias kgsecoyamln = kubecolor get secret -o=yaml --namespace
alias kgowiden = kubecolor get -o=wide --namespace
alias kgpoowiden = kubecolor get pods -o=wide --namespace
alias kgdepowiden = kubecolor get deployment -o=wide --namespace
alias kgstsowiden = kubecolor get statefulset -o=wide --namespace
alias kgsvcowiden = kubecolor get service -o=wide --namespace
alias kgingowiden = kubecolor get ingress -o=wide --namespace
alias kgcmowiden = kubecolor get configmap -o=wide --namespace
alias kgsecowiden = kubecolor get secret -o=wide --namespace
alias kgojsonn = kubecolor get -o=json --namespace
alias kgpoojsonn = kubecolor get pods -o=json --namespace
alias kgdepojsonn = kubecolor get deployment -o=json --namespace
alias kgstsojsonn = kubecolor get statefulset -o=json --namespace
alias kgsvcojsonn = kubecolor get service -o=json --namespace
alias kgingojsonn = kubecolor get ingress -o=json --namespace
alias kgcmojsonn = kubecolor get configmap -o=json --namespace
alias kgsecojsonn = kubecolor get secret -o=json --namespace
alias kgsln = kubecolor get --show-labels --namespace
alias kgposln = kubecolor get pods --show-labels --namespace
alias kgdepsln = kubecolor get deployment --show-labels --namespace
alias kgstssln = kubecolor get statefulset --show-labels --namespace
alias kgsvcsln = kubecolor get service --show-labels --namespace
alias kgingsln = kubecolor get ingress --show-labels --namespace
alias kgcmsln = kubecolor get configmap --show-labels --namespace
alias kgsecsln = kubecolor get secret --show-labels --namespace
alias kgwn = kubecolor get --watch --namespace
alias kgpown = kubecolor get pods --watch --namespace
alias kgdepwn = kubecolor get deployment --watch --namespace
alias kgstswn = kubecolor get statefulset --watch --namespace
alias kgsvcwn = kubecolor get service --watch --namespace
alias kgingwn = kubecolor get ingress --watch --namespace
alias kgcmwn = kubecolor get configmap --watch --namespace
alias kgsecwn = kubecolor get secret --watch --namespace
alias kgwoyamln = kubecolor get --watch -o=yaml --namespace
alias kgpowoyamln = kubecolor get pods --watch -o=yaml --namespace
alias kgdepwoyamln = kubecolor get deployment --watch -o=yaml --namespace
alias kgstswoyamln = kubecolor get statefulset --watch -o=yaml --namespace
alias kgsvcwoyamln = kubecolor get service --watch -o=yaml --namespace
alias kgingwoyamln = kubecolor get ingress --watch -o=yaml --namespace
alias kgcmwoyamln = kubecolor get configmap --watch -o=yaml --namespace
alias kgsecwoyamln = kubecolor get secret --watch -o=yaml --namespace
alias kgowidesln = kubecolor get -o=wide --show-labels --namespace
alias kgpoowidesln = kubecolor get pods -o=wide --show-labels --namespace
alias kgdepowidesln = kubecolor get deployment -o=wide --show-labels --namespace
alias kgstsowidesln = kubecolor get statefulset -o=wide --show-labels --namespace
alias kgsvcowidesln = kubecolor get service -o=wide --show-labels --namespace
alias kgingowidesln = kubecolor get ingress -o=wide --show-labels --namespace
alias kgcmowidesln = kubecolor get configmap -o=wide --show-labels --namespace
alias kgsecowidesln = kubecolor get secret -o=wide --show-labels --namespace
alias kgslowiden = kubecolor get --show-labels -o=wide --namespace
alias kgposlowiden = kubecolor get pods --show-labels -o=wide --namespace
alias kgdepslowiden = kubecolor get deployment --show-labels -o=wide --namespace
alias kgstsslowiden = kubecolor get statefulset --show-labels -o=wide --namespace
alias kgsvcslowiden = kubecolor get service --show-labels -o=wide --namespace
alias kgingslowiden = kubecolor get ingress --show-labels -o=wide --namespace
alias kgcmslowiden = kubecolor get configmap --show-labels -o=wide --namespace
alias kgsecslowiden = kubecolor get secret --show-labels -o=wide --namespace
alias kgwowiden = kubecolor get --watch -o=wide --namespace
alias kgpowowiden = kubecolor get pods --watch -o=wide --namespace
alias kgdepwowiden = kubecolor get deployment --watch -o=wide --namespace
alias kgstswowiden = kubecolor get statefulset --watch -o=wide --namespace
alias kgsvcwowiden = kubecolor get service --watch -o=wide --namespace
alias kgingwowiden = kubecolor get ingress --watch -o=wide --namespace
alias kgcmwowiden = kubecolor get configmap --watch -o=wide --namespace
alias kgsecwowiden = kubecolor get secret --watch -o=wide --namespace
alias kgwojsonn = kubecolor get --watch -o=json --namespace
alias kgpowojsonn = kubecolor get pods --watch -o=json --namespace
alias kgdepwojsonn = kubecolor get deployment --watch -o=json --namespace
alias kgstswojsonn = kubecolor get statefulset --watch -o=json --namespace
alias kgsvcwojsonn = kubecolor get service --watch -o=json --namespace
alias kgingwojsonn = kubecolor get ingress --watch -o=json --namespace
alias kgcmwojsonn = kubecolor get configmap --watch -o=json --namespace
alias kgsecwojsonn = kubecolor get secret --watch -o=json --namespace
alias kgslwn = kubecolor get --show-labels --watch --namespace
alias kgposlwn = kubecolor get pods --show-labels --watch --namespace
alias kgdepslwn = kubecolor get deployment --show-labels --watch --namespace
alias kgstsslwn = kubecolor get statefulset --show-labels --watch --namespace
alias kgsvcslwn = kubecolor get service --show-labels --watch --namespace
alias kgingslwn = kubecolor get ingress --show-labels --watch --namespace
alias kgcmslwn = kubecolor get configmap --show-labels --watch --namespace
alias kgsecslwn = kubecolor get secret --show-labels --watch --namespace
alias kgwsln = kubecolor get --watch --show-labels --namespace
alias kgpowsln = kubecolor get pods --watch --show-labels --namespace
alias kgdepwsln = kubecolor get deployment --watch --show-labels --namespace
alias kgstswsln = kubecolor get statefulset --watch --show-labels --namespace
alias kgsvcwsln = kubecolor get service --watch --show-labels --namespace
alias kgingwsln = kubecolor get ingress --watch --show-labels --namespace
alias kgcmwsln = kubecolor get configmap --watch --show-labels --namespace
alias kgsecwsln = kubecolor get secret --watch --show-labels --namespace
alias kgslwowiden = kubecolor get --show-labels --watch -o=wide --namespace
alias kgposlwowiden = kubecolor get pods --show-labels --watch -o=wide --namespace
alias kgdepslwowiden = kubecolor get deployment --show-labels --watch -o=wide --namespace
alias kgstsslwowiden = kubecolor get statefulset --show-labels --watch -o=wide --namespace
alias kgsvcslwowiden = kubecolor get service --show-labels --watch -o=wide --namespace
alias kgingslwowiden = kubecolor get ingress --show-labels --watch -o=wide --namespace
alias kgcmslwowiden = kubecolor get configmap --show-labels --watch -o=wide --namespace
alias kgsecslwowiden = kubecolor get secret --show-labels --watch -o=wide --namespace
alias kgwowidesln = kubecolor get --watch -o=wide --show-labels --namespace
alias kgpowowidesln = kubecolor get pods --watch -o=wide --show-labels --namespace
alias kgdepwowidesln = kubecolor get deployment --watch -o=wide --show-labels --namespace
alias kgstswowidesln = kubecolor get statefulset --watch -o=wide --show-labels --namespace
alias kgsvcwowidesln = kubecolor get service --watch -o=wide --show-labels --namespace
alias kgingwowidesln = kubecolor get ingress --watch -o=wide --show-labels --namespace
alias kgcmwowidesln = kubecolor get configmap --watch -o=wide --show-labels --namespace
alias kgsecwowidesln = kubecolor get secret --watch -o=wide --show-labels --namespace
alias kgwslowiden = kubecolor get --watch --show-labels -o=wide --namespace
alias kgpowslowiden = kubecolor get pods --watch --show-labels -o=wide --namespace
alias kgdepwslowiden = kubecolor get deployment --watch --show-labels -o=wide --namespace
alias kgstswslowiden = kubecolor get statefulset --watch --show-labels -o=wide --namespace
alias kgsvcwslowiden = kubecolor get service --watch --show-labels -o=wide --namespace
alias kgingwslowiden = kubecolor get ingress --watch --show-labels -o=wide --namespace
alias kgcmwslowiden = kubecolor get configmap --watch --show-labels -o=wide --namespace
alias kgsecwslowiden = kubecolor get secret --watch --show-labels -o=wide --namespace

