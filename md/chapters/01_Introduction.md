## イントロダクション

大規模なAndroidアプリではDI(Dependency Injection; 依存性の注入)ライブラリが組み込まれていることがあります。
多重に依存関係が存在するクラス群の初期化をDIライブラリに担わせることにより、開発者はより本質的なコード実装に時間を使うことが出来ます。

- [依存性の注入 \- Wikipedia](https://ja.wikipedia.org/wiki/%E4%BE%9D%E5%AD%98%E6%80%A7%E3%81%AE%E6%B3%A8%E5%85%A5)

### Daggerとは？

[Dagger](https://dagger.dev/)は、Androidアプリ開発におけるDIライブラリとしてよく採用されているライブラリです。
コードのコンパイル時にDIコンテナを自動生成するため、実行時において速いことが謳われています。
現在はGoogleによってメンテナンスされています。

Positive
: Daggerの初期バージョンはRetrofitなどのライブラリの開発元で有名なSquareにより作成されました。知ってた？

Daggerを導入することにより、以下の点においてメリットがあります。

- ボイラープレートの削除（記述量の削減）
- 環境の切替の容易さ
- テスタビリティ
- 依存関係の逆転

### このCodelabsで学ぶこと

このCodelabsでは、上記で述べたDaggerの恩恵について、実際にコードを書いて体感していく形式をとります。
具体的には以下の内容を収録しています。

- 既存プロジェクトへのDaggerの導入
- DaggerでDIを動かすファーストステップ
- DI環境でのテスト作成と実行
- 本番/検証環境で異なる注入クラスの切替え
- Subcomponent
- Dagger.Android
- Scope, Custom Scope
- Daggerで発生しがちなトラブルと修正方法

### 必要なもの

- Android Studio stable
  - 3.4系で動作確認をしています
- git コマンド もしくは gitフロントエンドGUIクライアント
  - トラブルシューティングのガイドでは *動かない*コードをcloneして修正する内容があります

### このCodelabsの想定読者層

このCodelabsは、Daggerをこれから知りたいと思っているAndroid開発者に向けて制作されたものです。
特に、なんとなくでDaggerを使っている（使うことを強いられている）開発者が自分の力でDaggerを導入できるようになるよう配慮を心がけました。

そのため、このCodelabsでは、Daggerがどういう根拠で動いているのか、どう便利なのか、どのようなときにDaggerを導入するべきなのか、といった文章は**一切ありません**。
まず動作するコードを自力で書いてから、理屈や理論は（他の資料を見て）あとで身につけてもらうというアプローチを採用しました。

本Codelabsは、まず「Daggerが導入されていないアプリをDaggerに対応させる」というロールプレイ方式で、Daggerの良さを手を動かしながら学びます。
後半ではDaggerで起こりがちなトラブルとその対応例を紹介します。

### イントロの終わりに

まず序盤から手を動かしてみることで、Daggerに対する「よく分からない感」を払拭できればいいなと思います。
そして、後半を進めていくことで、Daggerをより使いこなし、日常業務でも複雑な処理を苦もなく実現できるようになれば、制作者冥利に尽きます。

さぁ、始めましょう！

