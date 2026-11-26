def main [checkout: path, --context: string, --apply] {
    let manifests = $checkout | path join manifests

    let cilium = open ($manifests | path join apps app-cilium.yaml)

    let source = $cilium.spec.source

    let argo_values = $manifests | path join bootstrap argocd-values.yaml

    let root = $manifests | path join app-of-apps.yaml

    let argo_repository = 'https://argoproj.github.io/argo-helm'

    let argo_version = '10.18.3'

    let cilium_yaml = (
        $source.helm.valuesObject
        | to yaml
        | ^helm template $source.helm.releaseName $source.chart --repo $source.repoURL --version $source.targetRevision --namespace kube-system --include-crds --values -
    )

    let argo_yaml = (
        ^helm template argocd argo-cd --repo $argo_repository --version $argo_version --namespace argocd --include-crds --values $argo_values
    )

    if not $apply {
        print $"($cilium_yaml)\n---\n($argo_yaml)\n---\n(open --raw $root)"

        return
    }

    if ($context | is-empty) {
        error make {msg: '--apply requires an explicit --context'}
    }

    let nodes = (^kubectl --context $context get nodes --output json | from json | get items.metadata.name)

    if $nodes != [vorgossos] {
        error make {msg: 'The selected context must contain exactly the vorgossos node'}
    }

    ^kubectl --context $context --namespace 1password get secret op-credentials onepassword-token --output name

    ^kubectl --context $context --namespace argocd get secret github-repo-creds --output name

    $cilium_yaml | ^kubectl --context $context apply --filename -

    ^kubectl --context $context --namespace kube-system rollout status daemonset/cilium --timeout=300s

    ^helm --kube-context $context upgrade --install argocd argo-cd --repo $argo_repository --version $argo_version --namespace argocd --values $argo_values --wait --timeout 5m

    ^kubectl --context $context apply --filename $root
}
