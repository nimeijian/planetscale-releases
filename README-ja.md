## PlanetScale を利用して自身のKubernetesクラスターを作るには

### 準備

* Planetscale (プラネットスケール) レポジトリへのアクセス権を得ます。https://registry.planetscale.com にサインアップしてアカウントを作成し、当方にアカウントネームを送信してください。当方でリクエストを処理、承認し、その旨のメールを返信いたします。
* 並行してご自身のデバイスに vitess  (ヴィテス) をインストールして下さい。これにより vitess のコマンドラインのツール、特にvtctlclientを利用できるようになります。
https://github.com/planetscale/vitess-releases からギットハブ (GitHub) レポジトリをコピーしその中のシェルスクリプトを起動させると vitess をインストールすることができます (最新の_latest.sh をインストールして下さい )。

### 方法

Vitess をインストールし、レジストリにアクセスできるようになったら、次のようにしてシンプルなクラスターを簡単に作ることができます。

1. 必要な画像を取り込むため再度ログインして PlanetScale レジストリへのアクセスのためのシークレットキーを作る必要があります。(メールのフィールドはシングルクォートで囲うことに注意してください)

	```
	kubectl create secret docker-registry psregistry --docker-server=registry.planetscale.com --docker-username=your_new_id -—docker-email='your_email' --docker-password=your_new_password
	```

以上により次のアウトプットが得られます。

	```
	secret/psregistry created
	```

2. 次のkubectlコマンドによりPlanetScaleを含むさまざまな機能を読み込みます。

   2a. まず `rbac.yaml` ファイルを使ってさまざまなロールベースアクセス制御 (rbac) の許可を得ます。 

	```
	kubectl create -f rbac.yaml
	```
       
	`kubectl get pods`とコマンドすると次のように表示されるはずです。

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
   2b. 次に `operators.yaml` ファイルを利用し次のようにコマンド。

	```
	kubectl create -f operators.yaml
	```

        すると`kubectl`により次のようなポッドが得られます。

	```
	NAME                                  	       READY     STATUS 
	etcd-backup-operator-59cf44997f-cwm4m          1/1       Running
	etcd-operator-6cb76654cd-vkzqg                 1/1       Running
	etcd-restore-operator-5dddc644c9-kb64g         1/1       Running
	planetscale-operator-6fbfd98864-9vlx5          1/1       Running
	prometheus-operator-78f9dd5bfb-742cr           1/1       Running
	```

**注: 完全な PlanetScale operator CRDは** annotated (注釈付)-crd.yaml ファイルとして入っており、ここにはコンフィグレーション、リソース、用語などについての豊富な情報が提供されています。

3. `cr_messagedb_keyspace.yaml` によりシンプルなvitess クラスターを作成し、次のコマンドを実行します。

	```
	kubectl create -f cr_messagedb_keyspace.yaml
	```
	
	すると次のようなポッドが作成されます。
	
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

4. 実際のデータベーススキーマとVSchemaを作成します。アプリケーションvtctlclient を使いvtctldでvitessコマンドを実行します。これはkubectを使ってvtctldポッドにポートフォワードするか、外部に見えるサービスを作ってvtctldと通信することによってできます。そして次のコマンドで対応するVSchemaを作ります。

	```
	vtctlclient -server sever:port ApplySchema -sql "$(cat create_test_table.sql)" messagedb
	```

   mysqlクライアントを使って( vtgate経由で)これを管理するには、  

	```
	mysql -h <server> -P <port> -u mysql_user -p
	```

とし、プロンプトにパスワード **mysql_password**を入力します。
