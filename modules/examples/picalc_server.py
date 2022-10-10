# https://github.com/krebsalad/PiCalcPy 
from bottle import route, run, template
from mpmath import mp
import socket
import time

---

# reference commands
sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' '/etc/ssh/sshd_config'
sed -i -e '$aAllowUsers local' '/etc/ssh/sshd_config'
sed -i '/Your are good/a You are the best' filename

# input
hostname = socket.gethostname()
ip_addr = socket.gethostbyname(hostname)

# processing
sed -i -e '/^hostname = socket.gethostname()/s/^.*$/s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)/' 'picalc_server_testsubject.py'
sed -i -e '/ip_addr = socket.gethostbyname(hostname)/a ip_addr = s.getsockname()[0]' 'picalc_server_testsubject.py'
sed -i -e '/^ip_addr = socket.gethostbyname(hostname)/s/^.*$/s.connect(("8.8.8.8", 80))/' 'picalc_server_testsubject.py'

# output
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(("8.8.8.8", 80))
ip_addr = s.getsockname()[0]

---

# https://stackoverflow.com/questions/72331707/socket-io-returns-127-0-0-1-as-host-address-and-not-192-168-0-on-my-device
# https://realpython.com/python-sockets/
# s = socket.socket(internet_address_family=IPV4, socket type=TCP)
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
# s.connect((host=GOOGLE_DNS, port=HTTP))
s.connect(("8.8.8.8", 80))
ip_addr = s.getsockname()[0]

# the following returns local host instead of ipv4 address
# hostname = socket.gethostname()
# ip_addr = socket.gethostbyname(hostname)

@route('/PiCalc/<p>')
def index(p):
    # set time
    start_time = time.time()
    
    # read
    precision = int(p)

    # handle non ints
    if(str(type(precision)) != "<type 'int'>"):
        print(str(type(precision)))
        return str("error, precision was not an int")

    # set precision val and calculate pi
    mp.dps = precision
    pi = mp.pi

    # end time
    processing_time = time.time() - start_time
    
    # return txt
    return str("Server ip: "+ip_addr+ "\nTime took: "+ str(processing_time) + " seconds\nPI = " + str(pi) + "\n")

# run picalc on port 8080
def run_server(port_num=8080):
    run(host=ip_addr, port=port_num)
