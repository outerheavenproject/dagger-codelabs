## 序盤1: Dagger未導入のアプリにDaggerを導入する

> あなたは動物の写真を表示するアプリ「Petbook」を開発する会社に転職しました。
> この会社は新しい技術に積極的に取り組む風土があるのですが、Daggerだけは「よく分からない」という理由で導入が遅れていました。
> また、テストの導入もあまり進んでいませんでした。
> あなたは、そんなプロダクトにDaggerを導入するタスクにアサインされました。
> はたして、あなたは無事にDaggerを導入できるでしょうか・・・

### プロジェクトのclone

以下のコマンドを実行するか、それに準ずる操作を行い、GitHubリポジトリをcloneします

```
$ git clone git@github.com:outer-heaven2/dagger-codelabs-sample.git
```

cloneが完了したらAndroid Studioを実行し、cloneしたプロジェクトを開きます。

### プロジェクト構成

TODO: stsnさん書いて

### このプロジェクトの問題点 と、Daggerで解決できること

このプロジェクトでは、次の問題があります。

1. DogServiceのインスタンスを毎回生成してしまう。

シングルトンに管理したいインスタンスを、自分で生成・管理するのはめんどうです。Daggerを使うことで、安全にシングルトンでインスタンスを管理することが出来ます。

1. DogService RetrofitインターフェースをPresenter内で生成しているので、環境の切り替えが困難

これは、DIパターンを採用することで解決出来ます。Daggerを使うことで、DIパターンをお手軽に導入することが可能になります。

### Daggerのインストール

まず、Daggerを導入する最初の第一歩として、GradleにDaggerを設定します。

```app/build.gradle
def dagger_version = '2.23.2'
implementation "com.google.dagger:dagger:$dagger_version"
kapt "com.google.dagger:dagger-compiler:$dagger_version"
```

書き換えたら `Sync Project with Gradle Files`を実行します。

### AppComponentをつくる

まず、`Component`アノテーションを使い、AppComponentを定義します。

```kotlin
@Component
@Singleton
interface AppComponent {
    @Component.Factory
    interface Factory {
        fun create(): AppComponent
    }
}
```

上記のファイルを定義すると、アノテーションプロセッサーにより、`DaggerAppComponent`クラスが生成されます。

次に、Applicationクラスで、生成された`DaggerAppComponent`を使います。

```kotlin
class App : Application() {
    lateinit var appComponent: AppComponent

    override fun onCreate() {
        super.onCreate()
        appComponent = DaggerAppComponent.create()
    }
}
```

これで下準備は完了です。

### DogServiceインスタンスをDaggerで生成する

DogServiceをDaggerから提供するには次のように行います。

```kotlin
@Module
class DataModule {
    @Singleton
    @Provides
    fun provideRetrofit(): Retrofit =
        Retrofit.Builder()
            .baseUrl("https://dog.ceo/api/")
            .addConverterFactory(
                Json.asConverterFactory("application/json".toMediaType())
            )
            .build()

    @Singleton
    @Provides
    fun provideDogService(retrofit: Retrofit): DogService = retrofit.create()
}
```

### 動かしてみる

Android Studioの`Make Project` または `Command + F9` を実行します。

### まとめ

...
