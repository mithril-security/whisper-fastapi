import click

@click.command()
@click.option('--filename',
              help='A file containing the IP addresses to whitelist.')
def whitelist(filename):
    """Accept IPs that are then whitelisted for access from the container."""
    IPS=[]
    with open(filename) as file:
        for line in file:
            IPS.append(line.rstrip())
    
    with open("../init.sh","r+") as rewrite:
        lines = rewrite.readlines()
        rewrite.seek(0)
        for line in lines:
            print(line)
            if line.startswith("# iptable rules inserted from CLI"):
               for x in IPS:
                    line += "iptables -I DOCKER-USER -s 172.17.0.2 -d " + x + " -i docker0 -j ACCEPT" + "\n"
            rewrite.write(line)

if __name__ == '__main__':
    whitelist()