IMAGE_BASE ?= gcr.io/mapr-252711/ezua/apps/test-app
IMAGE_TAG ?= bundle

IMG ?= $(IMAGE_BASE):$(IMAGE_TAG)

all: docker-build docker-push

docker-build:
	docker build -t ${IMG} .

docker-push:
	docker push ${IMG}

helm-package:
	helm package ./test-app -d ./tarballs/

clear:
	kubectl delete -f job.yaml

deploy:
	yq -i '.spec.template.spec.containers[0].image = "${IMG}"' job.yaml
	kubectl apply -f job.yaml
