.PHONY: all proxy guest

all: proxy guest

proxy:
	docker run -p 3128:3128 --name proxy --network proxynet squid-proxy

guest:
	iptables -t nat -A OUTPUT  -p tcp --dport 80 -j REDIRECT --to-port 12345
	iptables -t nat -A OUTPUT  -p tcp --dport 443 -j REDIRECT --to-port 12345
	docker run -i -t --network proxynet -e PROXY_SERVER=proxy -e PROXY_PORT=3128 guest
# Removed the privileged flag, this may break the iptables rules alteration but if so then this solution isn't feasible anyway.