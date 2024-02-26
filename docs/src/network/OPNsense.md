# OPNsense

## Static `10.0.8.0/24` Route

To successfully route traffic to the `10.0.8.0/24` subnet advertised by MetalLB
a static route needs to be added to the OPNsense router. There is no good way
to do so within the web interface, instead SSH to the box and add the following
to `/usr/local/etc/rc.syshook.d/start/96-k8s-static-route`. Plus, make sure it
has execute permissions (`chmod +x 96-k8s-static-route`).

```sh
#!/bin/sh

route add -net 10.0.8.0/24 -interface vlan09
```
