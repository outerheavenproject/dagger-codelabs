# 序盤1: Dagger未導入のアプリにDaggerを導入する

> あなたは動物の写真を表示するアプリ「Petbook」を開発する会社に転職しました。
> この会社は新しい技術に積極的に取り組む風土があるのですが、Daggerだけは「よく分からない」という理由で導入が遅れていました。
> あなたは、そんなプロダクトにDaggerを導入するタスクにアサインされました。
> はたして、あなたは無事にDaggerを導入できるでしょうか・・・

## プロジェクトのclone

以下のコマンドを実行するか、それに準ずる操作を行い、GitHubリポジトリをcloneします

```
$ git clone https://github.com/outer-heaven2/dagger-codelabs-sample.git
```

cloneが完了したらAndroid Studioを実行し、cloneしたプロジェクトを開きます。

## プロジェクト構成

TODO: stsnさん書いて

## このプロジェクトの問題点 と、Daggerで解決できること

TODO: stsnさん書いて

・・・というわけで、このプロジェクトにはDaggerが入っていません。

## Daggerのインストール

まずDaggerの導入する最初の第一歩として、プロジェクトにDaggerを導入します。

```app/build.gradle
def dagger_version = '2.23.2'
implementation "com.google.dagger:dagger:$dagger_version"
kapt "com.google.dagger:dagger-compiler:$dagger_version"
```

書き換えたら `Sync Project with Gradle Files`を実行します。

## AppComponentをつくる

TODO:

- AppComponent つくる
- Application で AppComponent を呼び出す
- SubComponent つくる

## インスタンス化の実装を書き換える

## 動かしてみる

Android Studioの`Make Project` または `Command + F9` を実行します。

## まとめ

...
