.PHONY: all proxy guest

all: proxy guest

proxy:
	docker run -p 3128:3128 --name proxy --network proxynet squid-proxy

guest:
	docker run -i -t --network proxynet -e PROXY_SERVER=proxy -e PROXY_PORT=3128 guest
# Removed the privileged flag, this may break the iptables rules alteration but if so then this solution isn't feasible anyway.