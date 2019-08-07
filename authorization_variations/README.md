## Authorization variations with Vitess and MySQL

### Overview:
* Vitess has two distinct auth regimes,  spanning vtgate-to-vttablet, and vttablet-to-mysql.  Following are descriptions of these two related-but-separate mechanisms.  
* There are also grpc auth and other protocol variations, but they are not covered here just now.  


### 1. Access to vtgate (and thence to vttablet)

This allows users to authenticate to vitess itself. It can be delivered multiple ways:

* On the vtgate command line as a static .json string, e.g.:
		-mysql_auth_server_static_string '{"mysql_user":[{"Password": "mysql_password"}]}'

* or via .json file, again delivered on the command line: 
		-mysql_auth_server_static_file string

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The file is often named `mysql_auth_server_static_creds.json`

* It can be also be delivered via an ldap server or other auth service.   Details on this facility are not provided here.

### Notes:
* Each of the above-mentioned mechanisms simply establish the login for submitting commands to vtgate.
* There is no special role for them.  That is, there is no special association of these values with vttablet or mysql whatsoever.
* There are ways to more securely store and transmit this info..., storing hashed passwords in the file itself I believe has been mentioned, TLS etc.  Those are not covered here.

### A bridging aside:
#### [vtgate]  →   grpc  →   [vttablet]  →   mysql-protocol   →   [mysqld]

When vtgate communicates to vttablet over grpc, it transmits requests on the user's behalf but with no information regarding user roles or specific permissions downstream.

vttablet parses that request and decides what to do.  If say, it is a simple SQL select statement that will be passed to mysqld, it will connect to mysqld using the existing mysql "account" appropriate to that action (role), an account which resides in the "native" mysql catalogs.  
**And therein lies the tale:**
* That account may have been created long ago, before vitess came along.  That mysql db instance was "introduced" into a vitess cluster as an external database, and has not since changed.
* That account may have been created by vitess through an earlier vttablet init process, where vitess created the entire deployment from scratch, using vitess defaults for each role.
* That account may have started life in one of these modes above, then been morphed further.
But irrespective of the origins and current state, vttablet must be armed with the current "real" roles and logins whenever it is initialized or restarted.

### 2. Auth for vttablet to talk to mysql
Allows vttablet to authenticate and submit commands to mysqld, using the account it decides is appropriate for the operation requested (role).
* At startup, the account info can be delivered on the vttablet command line, along with passwords. Here are the chief ones: 
```
-db_allprivs_user <string>      -db_allprivs_password <string>
-db_app_user <string>           -db_app_password <string> 
-db_appdebug_user <string>      -db_appdebug_password <string>
-db_dba_user <string>           -db_dba_password <string>
-db_filtered_user <string>      -db_filtered_password <string>
-db_repl_user <string>          -db_repl_password <string>
```

* The account info can be delivered as a static file: -db-credentials-file <filename>
SPECIAL NOTE: When using a static file, that file simply associates a name with a password.  The command line flags must still be used to associate which name goes with which account role (first column above).  In this case the companion password flags are NOT required on the command line.  Here is an example of such a file:
{"vt_app": ["p1"], "vt_repl": ["p2"], "vt_allprivs": ["p3"], "vt_filtered": ["p4"], "vt_dba": ["p5"]}

* The account info can be delivered via a server:  -db-credentials-server <string>
No ready details on how to use this facility.
It is not clear whether the command line flags are needed in this case.

**ALSO:** There are many additional flags, e.g.,  to determine whether ssl is used for any of these, charset etc.  Not covered here.

### 3. Vitess Conventions

**a)** When initializing a brand new vttablet with a companion new mysqld, Vitess conventions will initialize the mysqld instance with a particular file: init_db.sql, usually found at ../vitess.io/vitess/config/init_db.sql 
The user accounts created are as follows, with appropriate database permissions, and correspond to the command line flags above :
```
vt_allprivs
vt_app
vt_appdebug
vt_dba
vt_filtered
vt_repl
```

**IMPORTANT NOTE:** These accounts are created with NO PASSWORD.  In that event, and as a further convention, vttablet can be started with NO associated command line flags, and will simply use these same defaults.
If passwords are present for these accounts in the mysql database, then either the full command line flags or the -db-credentials-file are required.

**b)** On the other hand, when introducing Vitess to work with an existing database, you may already have say only two primary user accounts: a DBA-oriented user and an application-oriented one.  You might chose to map the DBA user to the db_allprivs_user, db_dba_user and db_repl_user, while mapping the application user to db_app_user, db_appdebug_user, db_filtered_user.  But in essence, there is no convention here, you simply chose to map how you wish, using whatever mechanism you prefer as long as the user chosen has the necessary privileges as documented in the standard init_db.sql




