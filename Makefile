.PHONY: all docker enclave kill run clean

docker_image = blindai-api-nitro
enclave_image = $(docker_image).eif
godeps = ../cmd/*.go ../*.go ../go.mod ../go.sum
binary = nitriding

all: $(binary) docker enclave kill run

$(binary): $(godeps)
	make -C ../cmd/
	cp ../cmd/nitriding .

docker: Dockerfile
	docker build --build-arg ssh_pub_key="$(shell cat ~/.ssh/id_ecdsa.pub)" -t $(docker_image):latest .

enclave:
	nitro-cli build-enclave --docker-uri $(docker_image):latest --output-file $(enclave_image)

kill:
	$(eval ENCLAVE_ID=$(shell nitro-cli describe-enclaves | jq -r '.[0].EnclaveID'))
	@if [ "$(ENCLAVE_ID)" != "null" ]; then nitro-cli terminate-enclave --enclave-id $(ENCLAVE_ID); fi

run:
	nitro-cli run-enclave --cpu-count 8 --memory 65536 --enclave-cid 4 --eif-path $(enclave_image) --debug-mode
	nitro-cli console --enclave-id $$(nitro-cli describe-enclaves | jq -r '.[0].EnclaveID')

clean:
	rm -f $(binary)
