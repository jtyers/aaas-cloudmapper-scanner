.PHONY: apply
apply: scanner-function scanner-invoker-function
	cd terraform \
		&& terraform init -upgrade \
		&& terraform apply \
		-var scanner_function_zip=../scanner-function.zip \
		-var scanner_invoker_function_zip=../scanner-invoker-function.zip
	
.PHONY: destroy
destroy: scanner-function scanner-invoker-function
	cd terraform \
		&& terraform init -upgrade \
		&& terraform destroy \
		-var scanner_function_zip=../scanner-function.zip \
		-var scanner_invoker_function_zip=../scanner-invoker-function.zip
	
.PHONY: scanner-function
scanner-function:
	docker build -t scanner-python-layer:latest scanner

	@# create the container without starting it, so we have something to copy from
	@# we run this in a subshell so $cid is evaluated lazily
	$(SHELL) -c 'cid=`docker create -it scanner-python-layer:latest` \
		&& docker cp $$cid:/function.zip ./scanner-function.zip \
		&& docker rm $$cid >/dev/null'

.PHONY: scanner-invoker-function
scanner-invoker-function:
	docker build -t scanner-invoker-python-layer:latest scanner-invoker

	@# create the container without starting it, so we have something to copy from
	@# we run this in a subshell so $cid is evaluated lazily
	$(SHELL) -c 'cid=`docker create -it scanner-invoker-python-layer:latest` \
		&& docker cp $$cid:/function.zip ./scanner-invoker-function.zip \
		&& docker rm $$cid >/dev/null'

