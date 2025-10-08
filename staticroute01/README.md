# スタティックルート練習

## 概要
・・・

## ネットワーク構成
<img src="images/topology.png">

- ・・・

### 各PCの設定

- PCを接続するルータをデフォルトGWとして設定
```
route add default gw 10.1.11.254
```

### 各ルータの設定

- ・・・
```
# 以下はabr11の設定内容
・・・
```

## 起動方法
```Shell
docker compose up --build
```

## 解説
・・・
```Shell
$ docker compose exec -it r11 /bin/sh
```
```
・・・
```


## 後片付け

コンテナを起動したターミナルをCtrl+Cで止め、以下を実行する。

```Shell
docker compose up --build
```

## （補足）ルータの設定内容

### r11
```
・・・
```
