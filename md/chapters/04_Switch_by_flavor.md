## Dagger導入環境における、本番環境と検証環境で使用するクラスの切り替え

<!--
start: intro-dagger-testing
goal:  intro-dagger-build-types
-->

Positive
: あなたはDagger環境でテストを書くことが出来ました！<br>次はDaggerを使ってデバッグログ出力を切り替えたり、本番/検証環境を切り替えるといった、通常アプリを作っていてありがちなケースをDaggerで解決します。

Daggerを導入しつつ、本番環境と検証環境を差し替える方法を考えます。

Androidアプリ開発において、本番環境と検証環境を差し替える方法として一般的なのは、
Build variant(Build type (`debug`,`release`)やProduct flavor(例として`staging`, `production`))ごとにフォルダを切り替える機能があります。
Daggerにおいてもこれらの機能を活用するのですが、**差し替えたいクラスをvariantごとに提供して直接差し替える**のではなく、**Moduleをvariantごとに提供することで間接的に差し替えを行う**ことが求められます。

というわけで、デバッグ環境ではRetrofitのログ出力を行うが、本番環境ではログ出力をさせない実装を行いたいと思います。

### ログ出力用ライブラリの追加

Retrofitの通信ログをLogcatに出力する方法として手っ取り早い方法は、
Retrofitが内部で使用しているOkHttpに対してInterceptorを設定することです。

というわけで`logging-interceptor`を依存関係に加えます。

```./app/build.gradle
// ...
dependencies {
    // ...
    implementation 'com.squareup.okhttp3:okhttp:4.0.1'
    debugImplementation 'com.squareup.okhttp3:logging-interceptor:4.0.1' // 👈
    // ...
}
```

### Retrofitがカスタムされた OkHttpClient を使用するよう書き換え

RetrofitではOkHttpClientを指定しない場合、デフォルト設定でOkHttpを初期化し、使用します。
その場合ログ出力はされないので、ログ出力をしたい場合はカスタマイズされたOkHttpを使用するようにRetrofitのBuilderで設定します。
以下のように記述することで、カスタマイズされたOkHttpを使います。

肝心のカスタマイズされたOkHttpは次のステップで用意します。

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

Positive
: `./app/src/` には通常 `test`, `androidTest` のテスト用コードの配置フォルダおよび、`main` というフォルダでメインアプリ用コードの配置フォルダが存在します。<br>`debug`, `release` というフォルダは初期状態では存在しないので作成します。<br>`debug`, `release` のvariantは初期状態で存在しているためフォルダを作成するだけで利用できますが、それ以外の名称を付ける場合（例えば `staging` など）は、対応するBuild variantまたはフレーバーを`./app/build.gradle` に実装する必要があります。<br>詳しくはこちらを確認してください： [ビルド バリアントの設定  \|  Android Developers](https://developer.android.com/studio/build/build-variants?hl=ja)

まずは `./app/src/`**release**`/java/com/github/outerheavenproject/wanstagram/OkHttpClientModule.kt` に以下の内容でOkHttpClientを記述します。

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

御覧の通り、`HttpLoggingInterceptor`が組み込まれています。

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

### AppComponentにOkHttpClientModuleを登録する

`@Component`に記載しないと `provideRetrofit(client: OkHttpClient)` の `OkHttpClient`が解決できなくなるので、忘れないように記載しましょう。

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

Negative
: 記載するのを忘れると `エラー: [Dagger/MissingBinding] okhttp3.OkHttpClient cannot be provided without an @Inject constructor or an @Provides-annotated method.` というエラーが出ます。

さて `debug` バリアントで実際にアプリを動かしてみましょう。
Android StudioのLogcatを確認し、通信のログが表示されたら成功です！

### 宿題

- `release` バリアントではログが出ないことを確認しましょう。
    - releaseビルドのための鍵設定が少々面倒です。大雑把にやるだけなら `./app/build.gradle` を以下のように設定します。

```gradle
android {
    // ...
    buildTypes {
        release {
            // ...
            signingConfig signingConfigs.debug
        }
    }

    signingConfigs {
        debug {
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
            storeFile file("${System.getProperty("user.home")}/.android/debug.keystore")
        }
    }
}
// ...
```

- 本番環境と検証環境を分けるにはどうすればいいでしょうか？
    - まずは `production` フレーバーと `staging` フレーバーを用意します。先程リンクを紹介したビルドバリアントの設定を参考にしてください。
    - いくつか回答例が考えられます：
        - Retrofitクラスを本番/検証で分ける
            - この方法だと baseUrl 以外の記述がダブってしまい非効率かもしれません。また、片方で実装した内容がもう片方に実装されない人為的エラーを引き起こす可能性があります
        - Retrofit.Builderクラスを本番/検証で分ける
            - この方法は baseUrl のみ設定した Retrofit.Builder を出し分けるため、先程の方法よりも問題が出づらいです
        - baseUrlに設定するホストを独自のクラスに包んで 本番/検証で分ける
            - Value Object的な発想です。筆者はこのやり方はプロダクションのコードではこれまで見たことがないですが、うまくいきそうな気がします。
    - 今回のサンプルプロジェクトでは2種類のAPIを用意することが出来ませんでした。なので回答例は用意していません 🙇‍♀️

### diff

ここまでのdiffは以下のページで確認できます。

[Comparing intro\-dagger\-testing\.\.\.intro\-dagger\-build\-types · outerheavenproject/dagger\-codelabs\-sample](https://github.com/outerheavenproject/dagger-codelabs-sample/compare/intro-dagger-testing...intro-dagger-build-types)

