.PHONY: all proxy guest

all: proxy guest

proxy:
	docker run squid-proxy

guest:
	docker run guest

