1台のホストPC（Ubuntu環境）上で、Dockerを使ってネットワークの練習環境を構築します。
 
最初はシンプルな構成で構築し、演習を通じて複雑なネットワークにも挑戦していきます。

## 動作環境
- ホストPC: Appleシリコン搭載のMacbook上のVM
- OS: Ubuntu22.04.5 LTS
- Docker: v27.5.1
- Docker Compose: v2.32.4
<br>

## 資材のダウンロードと環境設定
任意のディレクトリ上でgit cloneします。

```Shell
git clone https://github.com/koyamaru3/network-train.git
```

環境設定ファイルを編集します。
```Shell
cd network-train
vi .env
```

TRANS_NICにホストPCの物理インタフェース名を設定します。インタフェース名は ip addrコマンドで確認できます。（通常はloインタフェースの次に表示されるインタフェースが該当。ここでは例としてenp0s5を設定します）
```INI
TRAIN_NIC=enp0s5
```
<br>

## 演習

  1. [擬似PCを構築する](./simple01/README.md)
  2. [仮想ルータを挟んでみる](./simple02/README.md)
  3. [仮想ルータから外部NWへ通信できるようにする](./simple03/README.md)
