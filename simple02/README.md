# 2. 擬似PCをネットワークに接続する

## 概要
2台の擬似PCを同じネットワークに接続し、擬似PC間でping確認を行ってみます。
 
<br>

## ネットワーク構成
下図の通り、Dockerコンテナで作成した2台の擬似PCを、他のネットワークから独立したコンテナネットワーク上（10.1.1.0/24）で接続します。
 
 
<img src="images/topology.png">
 
<br>

## 動作確認
今回も解説は後回しにして、先にpingの動作確認を行ってみます。
 
VM1上のsimple02ディレクトリ内へ移動し、「up1.sh」という名前のシェルスクリプトを実行します。以下の結果が出力されれば、VM1内に擬似PC2台とネットワークがデプロイされています。

```Shell
(VM1)$ cd network-train/simple02
(VM1)$ ./up1.sh
```

```
（実行結果）

[+] Running 3/3
 ✔ Network simple02_vlan1001  Created
 ✔ Container pc1-2            Created
 ✔ Container pc1-1            Created
Attaching to pc1-1, pc1-2
```

<br>

別のターミナルを開き、デプロイしたコンテナ情報を見てみます。
```Shell
(VM1)$ docker ps
```

```Shell
（実行結果）

CONTAINER ID   IMAGE           COMMAND     CREATED          STATUS          PORTS     NAMES
b0b812d31336   alpine:latest   "/bin/sh"   11 minutes ago   Up 11 minutes             pc1-1
3fb5670e1a16   alpine:latest   "/bin/sh"   11 minutes ago   Up 11 minutes             pc1-2
```

<br>

コンテナのネットワーク情報も見てみます。

```Shell
(VM1)$ docker network ls
```

```Shell
（実行結果）

NETWORK ID     NAME                DRIVER    SCOPE
51da0523259e   bridge              bridge    local
a432ba3760a0   host                host      local
0bcb0c5aedd1   none                null      local
23d9b00b79e4   simple02_vlan1001   macvlan   local
```
「simple02_vlan1001」という名前のネットワークが、2台の擬似PCを接続するために新たに作成したネットワークです。
 
このネットワークの詳細情報も見てみます。

```Shell
(VM1)$ docker inspect simple02_vlan1001
```

```
（実行結果）
[
    {
        "Name": "simple02_vlan1001",
        "Id": "8d54390d00d2f850d9142ec6d7aa45f2c08a7ec14d9ad66f49269370de781c76",
        "Created": "2025-11-03T17:37:58.293416957+09:00",
        "Scope": "local",
        "Driver": "macvlan",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.1.1.0/24",
                    "Gateway": "10.1.1.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "9c0259498676e54a8ae491f838233b93b84469df867fdcef46554626f4b30bff": {
                "Name": "pc1-1",
                "EndpointID": "4ce643da031892f8650ed3aff2f6bdcd53b878cd9a48d73ca66f3f0d93bf8c2c",
                "MacAddress": "02:42:ac:00:01:01",
                "IPv4Address": "10.1.1.101/24",
                "IPv6Address": ""
            },
            "a6b420d5616af17fd82f6a093c933509aeee2e7cdef03f5e6a45846c6b642c64": {
                "Name": "pc1-2",
                "EndpointID": "843f22a83e228c15b975156fbc4fa373795b8ec7aa59ad14c2c3dd9fb58eb121",
                "MacAddress": "02:42:ac:00:01:02",
                "IPv4Address": "10.1.1.102/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "parent": "enp0s5.1001"
        },
        "Labels": {
            "com.docker.compose.config-hash": "d08daf53532ee3aba8eda4ea095f20237dfc8263a3a96272a8c332fc7c0da0f5",
            "com.docker.compose.network": "vlan1001",
            "com.docker.compose.project": "simple02",
            "com.docker.compose.version": "2.40.3"
        }
    }
]
```

ネットワークに「pc1-1」と「pc1-2」のコンテナが接続されていることが確認できます。

<br>

それではping確認を行うために、以下のようにdocker execコマンドを実行して擬似PC「pc1-1」に接続します。
```Shell
(VM1)$ docker exec -it pc1-1 /bin/sh
```

接続した擬似PC内でpc1-2宛てにpingを実行すると応答が返ってきます。
```Shell
(pc1-1)/ # ping 10.1.1.102
PING 10.1.1.102 (10.1.1.102): 56 data bytes
64 bytes from 10.1.1.102: seq=0 ttl=64 time=2.197 ms
64 bytes from 10.1.1.102: seq=1 ttl=64 time=0.442 ms
64 bytes from 10.1.1.102: seq=2 ttl=64 time=0.099 ms
```

終了する際は、コンテナを起動したターミナルをCtrl+Cで止め、「down1.sh」という名前のシェルスクリプトを実行して後片付けします。

```Shell
(VM1)$ ./down1.sh
```

```Shell
（実行結果）
[+] Running 3/3
 ✔ Container pc1-1            Removed
 ✔ Container pc1-2            Removed
 ✔ Network simple02_vlan1001  Removed
```

<br>

## 解説

今回はDockerのネットワークに関する解説になります。
 
Dockerのネットワークはタイプがいくつかあり、用途に応じて選択することになります。それらを全部説明すると長くなるため、今回の演習に適した「macvlan driver」についてのみ説明します。

macvlan driverを使用すると、VM上で独立したコンテナネットワークを作ることができます。またコンテナネットワークを複数作った際は、VLANのように別々の独立したネットワークになります。

コンテナネットワークは以下のようにVM1_compose.yamlに定義しています。

```YML
networks:
  vlan1001:
    driver: macvlan
    driver_opts:
      parent: ${VM1_IF}.1001
    ipam:
      config:
        - subnet: 10.1.1.0/24
          gateway: 10.1.1.1

services:
  pc1-1:
    image: alpine:latest
    container_name: pc1-1
    hostname: pc1-1
    tty: true
    stdin_open: true
    privileged: true
    networks:
      vlan1001:
        ipv4_address: 10.1.1.101
        mac_address: "02:42:ac:00:01:01"
  pc1-2:
    image: alpine:latest
    container_name: pc1-2
    hostname: pc1-2
    tty: true
    stdin_open: true
    privileged: true
    networks:
      vlan1001:
        ipv4_address: 10.1.1.102
        mac_address: "02:42:ac:00:01:02"
```

新しくnetworksセクションを設け、「vlan1001」という名前のコンテナネットワークを作成しています。「driver: mac_vlan」の設定によって、macvlan driverが使われています。
 
driver_optsの「parent: ${VM1_IF}.1001」は、このネットワークをVM1のどのインタフェースに関連づけるか？になります。
 
VMのインタフェース名はお使いの環境によって異なるため、[初期設定時](../)に「.env」ファイルに記述していただきました。下記の例では「enp0s5」がVM1のインタフェース名です（これにより、parent: enp0s5.1001 と変換されます）

```
VM1_IF=enp0s5
VM2_IF=enp0s5
VM3_IF=enp0s5
BRIDGE_NET=192.168.0.0/24
BRIDGE_GW=192.168.0.1
BRIDGE_ROUTER1_IF=192.168.0.251
BRIDGE_ROUTER2_IF=192.168.0.252
BRIDGE_ROUTER3_IF=192.168.0.253
```

「ipam」は、ネットワークのサブネットの定義です。
```YML
    ipam:
      config:
        - subnet: 10.1.1.0/24
          gateway: 10.1.1.1
```
ネットワーク構成図の通り、subnetに「10.1.1.0/24」を指定しています。gatewayは今回の演習では使いませんが、ネットワークが接続するルータのIPアドレスを指定します。

<br>

擬似PC側も、接続するネットワークに関する定義を追加しています。

```
services:
  pc1-1:
    :
    networks:
      vlan1001:
        ipv4_address: 10.1.1.101
        mac_address: "02:42:ac:00:01:01"
```
上記のコンテナ内のnetworksセクションがそれに該当します。擬似PCそれぞれに異なるIPv4アドレスとMACアドレスを設定しました。

<br>

さて上記の設定でコンテナを起動すると、VM1上では以下のようにサブインタフェース1001（以下の例ではenp0s5.1@enp0s5）が作られているのがわかります。

```Shell
(VM1)$ ip a
```

```Shell
(実行結果)

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:1c:42:97:2b:40 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.111/24 brd 192.168.0.255 scope global dynamic noprefixroute enp0s5
       valid_lft 6043sec preferred_lft 6043sec
    inet6 fe80::21c:42ff:fe97:2b40/64 scope link 
       valid_lft forever preferred_lft forever
3: br-ebd648b5fa24: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 3e:93:75:b0:40:d0 brd ff:ff:ff:ff:ff:ff
    inet 172.119.0.1/16 brd 172.119.255.255 scope global br-ebd648b5fa24
       valid_lft forever preferred_lft forever
4: br-171dfefd0e3f: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 06:e4:f2:1c:ba:93 brd ff:ff:ff:ff:ff:ff
    inet 172.120.0.1/16 brd 172.120.255.255 scope global br-171dfefd0e3f
       valid_lft forever preferred_lft forever
5: br-5f195c875120: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 0e:4a:9b:9c:c1:57 brd ff:ff:ff:ff:ff:ff
    inet 172.118.0.1/16 brd 172.118.255.255 scope global br-5f195c875120
       valid_lft forever preferred_lft forever
6: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether c6:2b:60:c9:1e:42 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
19: enp0s5.1001@enp0s5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 00:1c:42:97:2b:40 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::21c:42ff:fe97:2b40/64 scope link 
       valid_lft forever preferred_lft forever
```

通信の経路を確認するために、2つのPC間でpingを実行してみます。
```Shell
(VM1)$ docker exec -it pc1 /bin/sh
```

```Shell
(pc1-1)/ # ping 10.1.1.102
PING 10.1.1.102 (10.1.1.102): 56 data bytes
64 bytes from 10.1.1.102: seq=0 ttl=64 time=2.594 ms
64 bytes from 10.1.1.102: seq=1 ttl=64 time=0.263 ms
64 bytes from 10.1.1.102: seq=2 ttl=64 time=0.218 ms
```

pingを実行している最中に、別のターミナルでVM1のサブインタフェース1001（以下の例ではenp0s5.1001）を指定してtcpdumpを行ってみます。

```Shell
$ sudo tcpdump -i enp0s5.1001 -nn
```

```
（実行結果）

tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s5.1001, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:18:16.766885 IP 10.1.1.101 > 10.1.1.102: ICMP echo request, id 13, seq 0, length 64
18:18:16.767443 IP 10.1.1.102 > 10.1.1.101: ICMP echo reply, id 13, seq 0, length 64
18:18:17.771111 IP 10.1.1.101 > 10.1.1.102: ICMP echo request, id 13, seq 1, length 64
18:18:17.771146 IP 10.1.1.102 > 10.1.1.101: ICMP echo reply, id 13, seq 1, length 64
18:18:18.773243 IP 10.1.1.101 > 10.1.1.102: ICMP echo request, id 13, seq 2, length 64
18:18:18.773278 IP 10.1.1.102 > 10.1.1.101: ICMP echo reply, id 13, seq 2, length 64
18:18:19.774288 IP 10.1.1.101 > 10.1.1.102: ICMP echo request, id 13, seq 3, length 64
18:18:19.774383 IP 10.1.1.102 > 10.1.1.101: ICMP echo reply, id 13, seq 3, length 64
```

コンテナ間のping通信がキャプチャできています。
 
なおこのサブインタフェース1001(enp0s5.1001)はVMのインタフェース(enp0s5)とは独立であるため、VMのインタフェース(enp0s5)を指定してtcpdumpしてもping通信は見えません。

```Shell
(VM1)$ sudo tcpdump -i enp0s5 -nn
```

```
（実行結果）

tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s5, link-type EN10MB (Ethernet), snapshot length 262144 bytes
```
※もしかしたらVM上を流れる関係ないパケットが表示されるかもしれません。

<br>

最もシンプルなネットワーク環境が構築できました。[次回の演習](../simple03/README.md)では2台のPC間にルータを挟んでみます。

