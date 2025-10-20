# 練習環境の構築 その１

## 概要
１台のUbuntu環境上で、Dockerを使ってネットワークの練習環境を構築していきます。<br>
あらかじめDockerがインストールされている前提とします。<br>
最初はDockerコンテナで作成した２台のPC間でping確認を行い、徐々に練習環境を拡張していきます。

### 動作環境
PC: Appleシリコン搭載のMacbook上のVM
OS: Ubuntu22.04.5 LTS
Docker: version 27.5.1

## 資材のダウンロード
任意のディレクトリ上でgit cloneします。

```Shell
git clone https://github.com/koyamaru3/network-train.git
```

今回使用する資材へ移動します。
```Shell
cd network-train/simple01
```

## ネットワーク構成
下図の通り、Dockerコンテナで作成した2台のPCを同一仮想ネットワーク上で接続します。
<img src="images/topology.png">

## 動作確認
解説は後回しにして、先に動作確認を行います。<br>
<br>
以下を実行し、PCを一斉起動させます。
```Shell
docker compose up --build
```

別のターミナルを開き、pc1のコンテナに入ってpingを実行します。
```Shell
docker exec -it pc1 /bin/sh
```

pc2宛てにpingを実行すると応答が返ってきます。
```Shell
/ # ping 10.1.1.102
PING 10.1.1.102 (10.1.1.102): 56 data bytes
64 bytes from 10.1.1.102: seq=0 ttl=64 time=0.388 ms
64 bytes from 10.1.1.102: seq=1 ttl=64 time=0.170 ms
64 bytes from 10.1.1.102: seq=2 ttl=64 time=0.112 ms
```

終了する際は、コンテナを起動したターミナルをCtrl+Cし、以下を実行して後片付けします。
```
docker compose down
```

## 解説

```
services:
  pc1:
    build: ./pc1
    container_name: pc1
    hostname: pc1
    tty: true
    stdin_open: true
    privileged: true
    networks:
      vlan1:
        ipv4_address: 10.1.1.101
  pc2:
    build: ./pc2
    container_name: pc2
    hostname: pc2
    tty: true
    stdin_open: true
    privileged: true
    networks:
      vlan1:
        ipv4_address: 10.1.1.102

networks:
  vlan1:
    driver: macvlan
    driver_opts:
      parent: ${TRAIN_NIC}.1
    ipam:
      config:
        - subnet: 10.1.1.0/24
          gateway: 10.1.1.254
```