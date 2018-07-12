# CNAPPS / Python Flask

## Local

Execute in local:

    $ make run

check health:

    $ curl http://127.0.0.1:9191/health
    {"database":{"database_status":"ok","version":["('CockroachDB CCL v2.0.3 (x86_64-unknown-linux-gnu, built 2018/06/18 16:11:33, go1.10)',)"]},"global_status":"ok"}

## Local with Docker

Build the Docker image:

    $ make minikube-build

Run a container:

    $ make docker-run

## Minikube

Build the Docker image into minikube:

    $ make minikube-build

Deploy the application into minikube:

    $ make minikube-deploy

Add to your `/etc/hosts` the URI :

    $ echo $(KUBECONFIG=./deploy/minikube-kube-config minikube ip) flask.cnapps.minikube | sudo tee -a /etc/hosts

Then check the service on URL : http://flask.cnapps.minikube/

Undeploy the application from minikube:

    $ make minikube-undeploy