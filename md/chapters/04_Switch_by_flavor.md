## 序盤3: Dagger導入環境に置ける、本番環境と検証環境で使用するクラスの切り替え

> あなたはDagger環境でテストを書くことが出来ました！
> 次はDaggerを使ってデバッグログ出力を切り替えたり、本番/検証環境を切り替えるといった、
> 通常アプリを作っていてありがちなケースをDaggerで解決します。

Daggerを導入しつつ、本番環境と検証環境を差し替える方法を考えます。

Androidアプリ開発において、本番環境と検証環境を差し替える方法として一般的なのは、
ビルドバリアント(ビルドタイプ(`debug`,`release`)やプロダクトフレーバー(例として`staging`, `production`))ごとにフォルダを切り替える機能があります。
Daggerにおいてもこれらの機能を活用するのですが、**差し替えたいクラスをvariantごとに提供して直接差し替える**のではなく、**SubComponentをvariantごとに提供することで間接的に差し替えを行う**ことが求められます。

というわけで、デバッグ環境ではRetrofitのログ出力を行うが、本番環境ではログ出力をさせない実装を行いたいと思います。

### ログ出力用ライブラリの追加

```./app/build.gradle
// ...
dependencies {
    // ...
    implementation 'com.squareup.okhttp3:okhttp:4.0.1'
    debugImplementation 'com.squareup.okhttp3:logging-interceptor:4.0.1' // 👈
    // ...
}
```

### Retrofitの生成のために OkHttpClient を受け取るよう書き換え

```diff
     @Singleton
     @Provides
-    fun provideRetrofit(): Retrofit =
+    fun provideRetrofit(client: OkHttpClient): Retrofit =
         Retrofit.Builder()
             .baseUrl("https://dog.ceo/api/")
             .addConverterFactory(
                 Json.asConverterFactory("application/json".toMediaType())
             )
+            .client(client)
             .build()
```

### debug variant と release variant に OkHttpClient を提供するモジュールを記述

まずは `./app/src/`**release**`/java/com/github/outerheavenproject/wanstagram/OkHttpClientModule.kt` に以下の内容でOkHttpClientを提供するよう記述します。
見ればわかる通り、ほぼ何もしていません。

```kotlin
@Module
class OkHttpClientModule {
    @Singleton
    @Provides
    fun provideOkHttpClient(): OkHttpClient =
        OkHttpClient.Builder().build()
}
```

次に `./app/src/`**debug**`/java/com/github/outerheavenproject/wanstagram/OkHttpClientModule.kt` を作成して記述します。

```kotlin
@Module
class OkHttpClientModule {
    @Singleton
    @Provides
    fun provideOkHttpClient(): OkHttpClient =
        OkHttpClient.Builder()
            .addInterceptor(
                HttpLoggingInterceptor().apply {
                    level = HttpLoggingInterceptor.Level.BASIC
                }
            )
            .build()
}
```

御覧の通り、`HttpLoggingInterceptor`が組み込まれています。

> `./app/src/` には通常 `test`, `androidTest` のテスト用コードの配置フォルダおよび、
> `main` というフォルダでメインアプリ用コードの配置フォルダが存在します。
> `debug`, `release` というフォルダは初期状態では存在しないので作成します。
> `debug`, `release` のバリアントは初期状態で存在しているためフォルダを作成するだけで利用できますが、
> それ以外の名称を付ける場合（例えば `staging` など）は、対応するビルドバリアントまたはフレーバーを
> `./app/build.gradle` に実装する必要があります。
> 詳しくはこちらを確認してください： [ビルド バリアントの設定  \|  Android Developers](https://developer.android.com/studio/build/build-variants?hl=ja)

### AppComponentにOkHttpClientModuleを登録する

```diff
 @Singleton
 @Component(
-    modules = [DataModule::class]
+    modules = [
+        DataModule::class,
+        OkHttpClientModule::class
+    ]
 )
 interface AppComponent {
     // ...
 }
```

さて `debug` バリアントで動かしてみましょう。
Android StudioのLogcatを見てみて、通信のログが表示されたら成功です！

### 宿題

- `release` バリアントでログが出ないことを確認しましょう。
- 本番環境と検証環境を分けるにはどうすればいいでしょうか？
    - まずは `production` フレーバーと `staging` フレーバーを用意するところからですね。
    - いくつかの答えがあるでしょう：
        - Retrofitクラスを本番/検証で分ける
            - この方法だとbaseUrl以外の記述がダブってしまい非効率かもしれません。また、片方で実装した内容がもう片方に実装されないエラーを引き起こす可能性があります
        - Retrofit.Builderクラスを本番/検証で分ける
            - この方法は baseUrl のみ設定した Retrofit.Builder をmainで共通化しているComponent実装で拡張していくので、先程の方法よりもエラーが出づらいです
        - baseUrlに設定するホストを独自のクラスに包んで 本番/検証で分ける
            - Value Object的な発想です。筆者はこのやり方はプロダクションのコードでは見たことがないですが、うまくいきそうな気がします。
    - 今回のサンプルプロジェクトでは2種類のAPIを用意することが出来ませんでした、なので回答は用意していません！でもここまで来たキミならできるはずだ！頑張って！

### diff

ここまでのdiffは以下のページで確認できます。

[Comparing intro\-dagger\-testing\.\.\.intro\-dagger\-build\-types · outerheavenproject/dagger\-codelabs\-sample](https://github.com/outerheavenproject/dagger-codelabs-sample/compare/intro-dagger-testing...intro-dagger-build-types)

