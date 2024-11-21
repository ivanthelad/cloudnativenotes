 ## canary Deployments with FrontDoor

This example performs the following 
 - Deploys two Container instances. Blue + Green
 - App Exposes a API under the path `/api/env`
 - Evenly distributes traffic against them using and origin group consisting of blue and green
 - deploys a rule set that checks for the header `stage`
 -  If `green` is found then the origin is overwriten and routed to the green back end. 
 -  If `blue` is found then the origin is overwriten and routed to the blue back end.
 - Purpose is to allow clients within a cannary ring to test a new application version or infrastructure before release to the wider audience

```bash 
  O
 /|\
 / \
  |
  v
+-----------------+   +---------+
|  Default Route  |-->| Ruleset |
+-----------------+   +---------+
       |                |     |
       v                |     |
+---------------+       |     |
| Default 50/50 |       |     |
+---------------+       |     |
v       v              v       v
+------+ +------+   +------+ +------+
| Blue | | Green |  | Blue | | Green |
+------+ +------+   +------+ +------+
```
### Test Even Distribution 
```bash 
while true; do curl  -s http://frontdoor.b01.azurefd.net/api/env | jq | grep stage; sleep 1; done
```

### Test Blue
 ```bash 
while true; do curl -H "stage: blue"  -s http://frontdoor.b01.azurefd.net/api/env | jq | grep stage; sleep 1; done
```
### Test Green 
 ```bash 
while true; do curl -H "stage: green"  -s http://frontdoor.b01.azurefd.net/api/env | jq | grep stage; sleep 1; done
```

