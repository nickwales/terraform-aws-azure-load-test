.PHONY: all init deploy plan destroy fmt clean
.PHONY: consul-install consul-use1 consul-usw2 awslb dataplane fake-service

destroy: metrics-clean

install:
	@./deploy/deploy_helm.sh
	@./deploy/fortio-tests/deploy.sh

metrics-install:
	@./deploy/deploy_helm.sh

fortio-install:
	@./deploy/fortio-tests/deploy.sh

metrics-clean: fortio-clean
	@-./deploy/deploy_helm.sh destroy

fortio-clean:
	@-./deploy/fortio-tests/deploy.sh destroy


fortio-run-http:
	@-./deploy/reports/http_run_fortio_tests.sh

fortio-run-grpc:
	@-./deploy/reports/grpc_run_fortio_tests.sh

clean:
	-rm -rf /tmp/*.json
	-rm /tmp/fortio.results.csv