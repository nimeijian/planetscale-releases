## Running your own kubernetes cluster with the PlanetScale operator

### Preliminaries:
* Obtain access to the planetscale repository.   Please sign up for an account at https://registry.planetscale.com and send us the account name. We will process your request and authorize it, with a further email response back.

* In the meantime, you should also install vitess locally.  This will allow you to use the vitess command line tools, especially `vtctlclient` .
You can install vitess locally by cloning the GitHub repository from  https://github.com/planetscale/vitess-releases , and running the associate shell script ( `install_latest.sh` )

### Instructions:
Once you have installed vitess and have access to the registry, you can quickly establish a simple cluster as follows. 

1. In order to fetch the required images, you will need to establish a PlanetScale registry access secret using your new login:
```
kubectl create secret docker-registry "psregistry" --docker-server="registry.planetscale.com" --docker-username="<your_new_id>" -—docker-email="<your_email>" --docker-password="<your_new_password>"
```
with expected output:
`secret/psregistry created`

2.  To load the various operators, including the PlanetScale operator, you will execute the following kubectl commands:

	 2a. First, establish various rbac permissions using the enclosed `rbac.yaml` file.

	```
	kubectl create -f rbac.yaml
	```

	and expect the following output:
	```
	role.rbac.authorization.k8s.io "planetscale-operator" created
	rolebinding.rbac.authorization.k8s.io "default-account-planetscale-operator" created
	clusterrole.rbac.authorization.k8s.io "planetscale-persistent-volume" created
	clusterrolebinding.rbac.authorization.k8s.io "default-account-planetscale-pv" created
	clusterrole.rbac.authorization.k8s.io "prometheus-operator" created
	clusterrolebinding.rbac.authorization.k8s.io "prometheus-operator" created
	clusterrole.rbac.authorization.k8s.io "prometheus" created
	clusterrolebinding.rbac.authorization.k8s.io "prometheus" created
	```
	 2b. Next, using the enclosed `operators.yaml` file.
	
	```
	kubectl create -f operators.yaml
	```

	`kubectl get pods`  should show the following:

	```
	NAME                                     READY     STATUS 
	etcd-backup-operator-59cf44997f-cwm4m    1/1       Running
	etcd-operator-6cb76654cd-vkzqg           1/1       Running
	etcd-restore-operator-5dddc644c9-kb64g   1/1       Running
	planetscale-operator-6fbfd98864-9vlx5    1/1       Running
	prometheus-operator-78f9dd5bfb-742cr     1/1       Running
	```
**Note: the complete PlanetScale operator CRD** is included here as the file `annotated-crd.yaml` .  It provides a wealth of information regarding configuration, resources and terminology.

3. Establish a simple vitess cluster with `cr_messagedb_keyspace.yaml` and the following command:

	```
	kubectl create -f cr_messagedb_keyspace.yaml
	```

	This will create the following pods:

```
NAME                                    READY     STATUS 
proxy-deployment-fresh                  1/1       Running
vtctld-fresh-example-000000000          1/1       Running
vtgate-fresh-example-000000000          1/1       Running
vtgate-fresh-example-000000001          1/1       Running
vttablet-fresh-example-000000001        2/2       Running
vttablet-fresh-example-000000002        2/2       Running
vttablet-fresh-example-000001001        2/2       Running
vttablet-fresh-example-000001002        2/2       Running
```

4. Create the actual database schema and vschema.  Use the `vtctlclient` application to connect and issue vitess commands to vtctld.  To enable this, you will need to either use kubectl to port-forward to the vtctld pod, or you can create an externally visible Service to communicate with vtctld.

	```
	vtctlclient -server sever:port ApplySchema -sql "$(cat create_test_table.sql)" messagedb
	```

And to create the accompanying vschema:

	vtctlclient -server server:port  ApplyVSchema -vschema  "$(cat create_vschema.json)" messagedb

And to administer it using mysql client (going through vtgate)

	mysql -h <server> -P <port> -u mysql_user -p
	
and enter the password “**mysql_password**” at the prompt


