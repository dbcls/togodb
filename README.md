# TogoDB

## 必要なソフトウェア
### PostgreSQL
postgresql-serverが稼働しており、TogoDB（Railsアプリケーション）からpostgresql-serverにアクセスできる必要があります。
* Version 9.x, 10.x, 11.xで動作を確認しています。
* pg_trigmを利用しています。そのためpostgresql-contribをインストールするかPostgreSQLのcontribからpg_trgmをインストールする必要があります。

### Redis
redis-serverが稼働しており、TogoDB（Railsアプリケーション）からredis-serverにアクセスできる必要があります。

TogoDBでは、データベースの作成やデータリリース（CSV, JSON, RDF, FASTAファイルの生成）はバックグラウンド・ジョブ（非同期処理）
として実行します。このバックグラウンド・ジョブを実現するため[Resque](https://github.com/resque/resque)を利用しています。  
Resqueのジョブ・キューとしてRedis利用します。
  
### D2RQ
RDB-RDFのマッピング、RDFファイルの生成、SPARQL検索に使用します。  
[https://d2rq.org/](https://d2rq.org/)  

**D2RQのインストール方法**

githubからソースコードを取得しビルドします。  
D2RQはJavaで書かれており、ソースコードのビルドに[Apache Ant](https://ant.apache.org/)が必要です。
```
$ git clone https://github.com/d2rq/d2rq.git
$ cd d2rq
$ ant jar
```

### Raptor RDF Syntax Library
[http://librdf.org/raptor/](http://librdf.org/raptor/)  
RDFのフォーマット変換（N-triples => Turtle, RDF/XML）のため、Raptorに含まれているrapperコマンドを使用します。

### nkf
データベース作成の際にアップロードされたCSV, TSVファイルをUTF-8に変換するために使用します。

## 設定ファイル
PostgreSQLの接続情報等、環境に依存する情報の管理に[dotenv](https://github.com/bkeepers/dotenv/)を使用しています。

.env-sampleファイルをコピーして.envファイルを作成し、.envファイルを環境に合わせて編集します。
```
$ cp .env-sample .env
$ vi .env
```

設定する値は下表の通りです。

|変数名|設定する値|
|:--|:--|
|RAILS_MAX_THREADS|データベースのコネクションプール数|
|DATABASE_HOST|データベースのホスト名|
|DATABASE_PORT|データベースのポート番号|
|DATABASE_USER|データベースの接続ユーザ|
|DATABASE_PASSWORD|データベース接続のパスワード|
|DATABASE_NAME_DEVEROPMENT|データベース名（development環境）|
|DATABASE_NAME_TEST|データベース名（test環境）|
|DATABASE_NAME_PRODUCTION|データベース名（production環境）|
|REDIS_HOST|Redisが稼働しているホスト|
|REDIS_PORT|Redisのポート番号|
|SERVER_NAME|TogoDBが稼働するマシンのホスト名とポート番号|
|RAPPER_PATH|rapperコマンドのパス名|
|NKF_PATH|nkfコマンドのパス名|
|D2RQ_DIR|D2RQのディレクトリ（dump-rdfファイル、d2r-queryファイルがあるディレクトリ）|
|DATA_DIR|TogoDBで作成、利用されるファイル（アップロードされたファイル、リリース機能で生成されるファイル）を保存するディレクトリ|
|TMP_DIR|TogoDBで一時ファイルを作成するディレクトリ|
|BASE_URI_HOST|RDFのBaseURIに使用するホスト名|

## TogoDBのセットアップ
TogoDBアプリケーションのセットアップは以下の手順で行います。
1. ソースコードの取得
2. 必要なライブラリ（gem）のインストール
3. 設定ファイル（.envファイル）の編集
4. データベースのセットアップ
5. TogoDBのセットアップ
6. アセットファイルの作成（production環境の場合のみ、development環境では不要）

コマンドラインで以下のように実行します。
```
$ git clone https://github.com/dbcls/togodb.git
$ cd togodb
$ bundle install --path vendor/bundle
$ cp .env-sample .env
$ .envファイルの内容を環境に合わせて編集
$ bundle exec rails db:setup
$ bundle exec rails togodb:setup
$ bundle exec rails assets:precompile　（development環境では不要）
```

## ローカル・アカウントの作成
TogoDBにローカル・アカウントでログインするためには、ローカル・アカウントを作成する必要があります。 

ローカル・アカウントの作成は、以下のコマンドを実行します。
```
$ bundle exec rails c
irb(main):001:0> TogodbUser.regist('ユーザ名', 'パスワード')
```

## サーバの起動
TogoDBが動作するにはResque worker（バックグラウンド・ジョブを実行する）と、Railsサーバが起動している必要があります。  

以下のコマンドで起動します。

Resque workerの起動
```
$ bundle exec ruby .local/bin/resque-worker.rb start
```
 
Railsサーバの起動
```
$ bundle exec rails s -b 0.0.0.0
```
