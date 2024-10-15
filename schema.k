import manifests

schema App:
    """The application model."""
    name: str
    namespace?: str
    replicas: int = 1
    labels?: {str:str} = {app = name}
    service?: Service
    containers?: {str:Container}
    configMaps?: {str:ConfigMap}
    imagePullSecrets?: [str]
    proxy?: bool = false
    proxyCredentials?: ProxyCredentials

schema ProxyCredentials:
    username: str
    password: str

schema ConfigMap:
    name: str
    data: str
    mountPath?: str

schema Service:
    """The service model."""
    $type?: str
    ports: [Port]

schema Port:
    """The port model."""
    port: int
    protocol: "TCP" | "UDP" | "SCTP" = "TCP"
    targetPort?: int | str

schema Container:
    """The container model."""
    image: str
    command?: [str]
    args?: [str]
    env?: [Env]
    volumes?: [Volume]
    resources?: Resource
    ports: [ContainerPort]
    imagePullPolicy: "Always" | "IfNotPresent" | "Never" = "Always"

schema ContainerPort:
    """The container port model."""
    name?: str
    protocol: "TCP" | "UDP" | "SCTP" = "TCP"
    containerPort: int

    check:
        1 <= containerPort <= 65535, "containerPort must be between 1 and 65535, inclusive"

schema Env:
    name: str
    value: str

schema Volume:
    name: str
    mountPath: str

schema Resource:
    limits?: {str:}
    requests?: {str:}

kubernetesRender = lambda a: App {
    if a.proxy:
      a.containers.proxy = {
        image = "nginx"
        name = "proxy"
        ports = { containerPort = 80 }
        volumes = [
          {
            name = "proxy-config"
            mountPath = "/etc/nginx/conf.d/"
          }
        ]
      }

    # Construct the deployment manifest.
    deployment = {
        apiVersion = "apps/v1"
        kind = "Deployment"
        metadata.name = a.name
        metadata.labels = a.labels
        spec = {
            replicas = a.replicas
            selector.matchLabels = a.labels
            template.metadata.labels = a.labels
            template.spec.imagePullSecrets = [{
                name = n
            } for n in a.imagePullSecrets]
            template.spec.containers = [{
                name = n
                image = c.image
                imagePullPolicy = c.imagePullPolicy
                command = c.command
                args = c.args
                env = c.env
                volumeMounts = c.volumes
                resources: c.resources
                ports = c.ports
            } for n, c in a.containers]
        }
    }
    # Construct the service manifest.
    service = {
        apiVersion = "v1"
        kind = "Service"
        metadata.name = a.name
        metadata.labels = a.labels
        spec = {
            type = a.service?.$type
            selector = a.labels
            ports = a.service?.ports
        }
    }
    # Returns Kubernetes manifests
    [
        deployment
        if a.service:
            service

    ]
}
