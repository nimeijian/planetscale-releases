## 使用PlanetScale操作符运行你自己的Kubernetes集群

### 准备工作:

* 获得PlanetScale存储库的访问权限。请在https://registry.planetscale.com注册一个账户,并将账户名发送给我们。我们会处理你的请求并进行授权,并通过邮件回复。
* 同时,你还应该在本地安装Vitess。这样你就可以使用Vitess命令行工具,特别是`vtctlclient`。你可以从 https://github.com/planetscale/vitess-releases 复制
GitHub 存储库,从而在本地安装 Vitess, 并运行关联shell脚本`(install_latest.sh)`

### 操作说明:

一旦安装完 Vitess 并获得存储库的访问权限之后,你就可以按下列步骤快速创建一个简的集群。

1. 为了提取所需要的图片,你需要使用新登录名创建一个 PlanetScale 注册表访问密钥:(注意电子邮箱字段为单引号)

```
kubectl create secret docker-registry psregistry --docker-
server=registry.planetscale.com --docker-username=your_new
_id -—docker-email='your_email' --docker-password=your_new
_password
```

输出结果应当为:

`secret/psregistry created`

2. 要载入各种操作符,包括 PlanetScale 操作符,你需要执行下列`kubectl`命令:

      2a. 首先,使用随附的 `rbac.yaml` 文件创建各种 rbac 许可。
   
	```
	kubectl create -f rbac.yaml
	```
	
	输出结果应当为:

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
      2b. 接下来,使用随附的 `operators.yaml` 文件。
	
	```
	kubectl create -f operators.yaml
	```

	`kubectl get pods` 应显示下列结果:

	```
	NAME                                  	       READY     STATUS 
	etcd-backup-operator-59cf44997f-cwm4m          1/1       Running
	etcd-operator-6cb76654cd-vkzqg                 1/1       Running
	etcd-restore-operator-5dddc644c9-kb64g         1/1       Running
	planetscale-operator-6fbfd98864-9vlx5          1/1       Running
	prometheus-operator-78f9dd5bfb-742cr           1/1       Running
	```

**注意:完整的 PlanetScale 操作符 CRD** 包含在这里,并显示为annotated-crd.yaml。它提供关于配置、资源和术语的丰富信息。

3. 使用 `cr_messagedb_keyspace.yaml` 及下列命令建立简单的 Vitess 集群:

	```
	kubectl create -f cr_messagedb_keyspace.yaml
	```

	这将创建下列 pod:

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

4. 创建实际的数据库 schema 和 Vschema。使用 `vtctlclient` 应用程序来连接和发送 Vitess 命令到 vtctld。要做到这一点,你需要使用 `kubectl`将端口转发到 vtctld pod,或者建立一个外部可见的 Service 与 vtctld 通信。

	```
	vtctlclient -server sever:port ApplySchema -sql "$(cat create_test_table.sql)" messagedb
	```

如要创建搭配的 vschema:

	vtctlclient -server server:port  ApplyVSchema -vschema  "$(cat create_vschema.json)" messagedb

如要使用 mysql 客户端对其管理(通过 vtgate)

mysql -h <server> -P <port> -u mysql_user -p

并按提示输入密码“**mysql_password**”



