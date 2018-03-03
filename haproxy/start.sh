#!/bin/bash -x

[ $TRY_TOTAL ] || TRY_TOTAL=10
[ $BACKEND ] || BACKEND='nginx'

TRY=1
BACKEND_IPS=
sleep 10
echo -n "Tick"

while [ $TRY -le $TRY_TOTAL ]; do
	echo -n "."
	IPS=$(dig +short $BACKEND)
	if [ "$IPS" ]; then
		BACKEND_IPS="$IPS"
		break
	fi
	sleep 1
	let TRY++
done

if [ "$BACKEND_IPS" ]; then
	sleep 10
	echo " got $BACKEND_IPS"
	N=1
	for IP in $BACKEND_IPS; do
		CONTAINER=$(dig +short -x $IP)
		SERVER="  server ${CONTAINER} $IP:80 check"
		SERVER_MATCH="^.*server ${CONTAINER}.*$"

		if grep -q "$SERVER_MATCH" /etc/haproxy/haproxy.cfg; then
			sed -i -E "s/${SERVER_MATCH}/${SERVER}/1" /etc/haproxy/haproxy.cfg
		else
			echo "${SERVER}" >> /etc/haproxy/haproxy.cfg
		fi
		let N++
	done
	echo "Haproxy config /etc/haproxy/haproxy.cfg has been updated with IP addresses $BACKEND_IPS"
else
	echo " failed!"
	echo "Could not resolve IP address of backend $BACKEND"
fi

#/usr/sbin/service rsyslog start

/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid
