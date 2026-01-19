local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("yaml", {
  -- Kubernetes Deployment
  s(
    "kdep",
    fmt(
      [[
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {}
  namespace: {}
spec:
  replicas: {}
  selector:
    matchLabels:
      app: {}
  template:
    metadata:
      labels:
        app: {}
    spec:
      containers:
      - name: {}
        image: {}
        ports:
        - containerPort: {}
        {}
]],
      {
        i(1, "app-name"),
        i(2, "default"),
        i(3, "3"),
        i(4, "app-name"),
        i(5, "app-name"),
        i(6, "app"),
        i(7, "nginx:latest"),
        i(8, "80"),
        i(0),
      }
    )
  ),

  -- Kubernetes Service
  s(
    "ksvc",
    fmt(
      [[
apiVersion: v1
kind: Service
metadata:
  name: {}
  namespace: {}
spec:
  selector:
    app: {}
  ports:
  - protocol: TCP
    port: {}
    targetPort: {}
  type: {}
]],
      {
        i(1, "app-service"),
        i(2, "default"),
        i(3, "app-name"),
        i(4, "80"),
        i(5, "8080"),
        i(6, "ClusterIP"),
      }
    )
  ),

  -- Kubernetes ConfigMap
  s(
    "kcm",
    fmt(
      [[
apiVersion: v1
kind: ConfigMap
metadata:
  name: {}
  namespace: {}
data:
  {}: {}
]],
      {
        i(1, "config-name"),
        i(2, "default"),
        i(3, "key"),
        i(4, "value"),
      }
    )
  ),

  -- Kubernetes Secret
  s(
    "ksec",
    fmt(
      [[
apiVersion: v1
kind: Secret
metadata:
  name: {}
  namespace: {}
type: Opaque
data:
  {}: {}
]],
      {
        i(1, "secret-name"),
        i(2, "default"),
        i(3, "key"),
        i(4, "base64-encoded-value"),
      }
    )
  ),

  -- Kubernetes Ingress
  s(
    "king",
    fmt(
      [[
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {}
  namespace: {}
spec:
  rules:
  - host: {}
    http:
      paths:
      - path: {}
        pathType: Prefix
        backend:
          service:
            name: {}
            port:
              number: {}
]],
      {
        i(1, "ingress-name"),
        i(2, "default"),
        i(3, "example.com"),
        i(4, "/"),
        i(5, "service-name"),
        i(6, "80"),
      }
    )
  ),

  -- Kubernetes PersistentVolumeClaim
  s(
    "kpvc",
    fmt(
      [[
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {}
  namespace: {}
spec:
  accessModes:
  - {}
  resources:
    requests:
      storage: {}
]],
      {
        i(1, "pvc-name"),
        i(2, "default"),
        i(3, "ReadWriteOnce"),
        i(4, "1Gi"),
      }
    )
  ),
})
