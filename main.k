import manifests
import .schema

app = schema.App {
    name = "app"
    containers.nginx = {
        image = "nginx"
        ports = [{containerPort = 80}]

    }
    service.ports = [{ port = 80 }]
    imagePullSecrets = [ "docker-creds" ]
}

manifests.yaml_stream(sum([schema.kubernetesRender(a) for a in schema.App.instances()], []))
