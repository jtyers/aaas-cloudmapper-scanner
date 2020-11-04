bucket="aaas-test-cloudmapper-results"

.PHONY: apply
apply: scanner-function scanner-invoker-function
	cd terraform \
		&& terraform init -upgrade \
		&& terraform apply \
		-var scanner_function_tgz=../scanner-function.tgz \
		-var scanner_invoker_function_zip=../scanner-invoker-function.zip
	
.PHONY: destroy
destroy: scanner-function scanner-invoker-function
	cd terraform \
		&& terraform init -upgrade \
		&& terraform destroy \
		-var scanner_function_tgz=../scanner-function.tgz \
		-var scanner_invoker_function_zip=../scanner-invoker-function.zip
	
.PHONY: scanner-function
scanner-function:
	docker build -t scanner-python-layer:latest scanner

	@# create the container without starting it, so we have something to copy from
	@# we run this in a subshell so $cid is evaluated lazily
	$(SHELL) -c 'cid=`docker create -it scanner-python-layer:latest` \
		&& docker cp $$cid:/function.tgz ./scanner-function.tgz \
		&& docker rm $$cid >/dev/null'

.PHONY: scanner-invoker-function
scanner-invoker-function:
	docker build -t scanner-invoker-python-layer:latest scanner-invoker

	@# create the container without starting it, so we have something to copy from
	@# we run this in a subshell so $cid is evaluated lazily
	$(SHELL) -c 'cid=`docker create -it scanner-invoker-python-layer:latest` \
		&& docker cp $$cid:/function.zip ./scanner-invoker-function.zip \
		&& docker rm $$cid >/dev/null'

# inspect: load an S3 bucket's account scans into a cloudmapper container
# for further analysis
.PHONY: cloudmapper-docker-build
cloudmapper-docker-build:
	if [ -d cloudmapper.git ]; then \
		cd cloudmapper.git && git pull; \
	else \
		git clone --depth 1 https://github.com/duo-labs/cloudmapper cloudmapper.git; \
	fi

	sed -i -e 's/^RUN bash//' cloudmapper.git/Dockerfile
	echo 'Dockerfile' >> cloudmapper.git/.dockerignore

	cd cloudmapper.git \
		&& docker build -t cloudmapper .


.PHONY: inspect
inspect: cloudmapper-docker-build
	docker build -t cloudmapper-scanner-inspector inspector
	./inspect-wrapper.sh
