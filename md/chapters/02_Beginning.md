## 序盤1: Dagger未導入のアプリにDaggerを導入する

<!--
start: master
goal:  intro-dagger
-->

> あなたは動物SNSアプリ「Wanstagram」を開発する会社に転職しました。
> この会社は新しい技術に積極的に取り組む風土があるのですが、Daggerだけは「よく分からない」という理由で導入が遅れていました。
> また、テストの導入もあまり進んでいませんでした。
> あなたは、そんなプロダクトにDaggerを導入するよう指示されました。
> はたして、あなたは無事にDaggerを導入できるでしょうか・・・

### プロジェクトのclone

まずはCodelabで実際に作業するリポジトリ——「Wanstagram」アプリ——を取得します。
以下のコマンドを実行して、GitHubリポジトリをcloneします。

```
$ git clone git@github.com:outer-heaven2/dagger-codelabs-sample.git
```

cloneが完了したらAndroid Studioを実行し、cloneしたプロジェクトを指定して開きます。

### プロジェクト構成

このプロジェクトではKotlinを採用し、AndroidXに対応済みです。
また、Kotlin Coroutinesを採用していますが、シンプルな記法のみに留めつつ採用しています。
通信ライブラリはRetrofitを採用しています。
JSONシリアライザーとしてkotlinx.serializationを採用しています。
アーキテクチャとしてMVPパターンを採用しています。

- ./app/src/main/java/com/github/outerheavenproject/wanstagram
  - data
    - Dog.kt: DogモデルおよびDogsモデル
    - DogService.kt: Retrofitのinterface定義およびRetrofitのBuilder
  - ui
    - MainActivity.kt: LauncherなどのエントリーポイントとなるActivityです。DogFragmentとShibaFragmentをBottomNavigationViewで切り替えます。
    - DogAdapter.kt: RecyclerViewのListAdapter類を定義しています
    - AppNavigator.kt: DogAdapterからDetailActivityへ遷移するためのアクションを定義しています
    - detail
      - DetailActivity.kt: 画像の詳細を表示します（大きな画面で表示する）
    - dog
      - DogFragment.kt: 犬画像をリスト表示するFragmentです
      - DogPresenter.kt: DogFragmentをViewと捉えた場合のPresenter実装です
      - DogContract.kt: DogFragmentとDogPresenterで実装すべきinterfaceが定義されています
    - shiba
      - ShibaFragment.kt: 柴犬画像をリスト表示するFragmentです
      - ShibaPresenter.kt: ShibaFragmentをViewと捉えた場合のPresenter実装です
      - ShibaContract.kt: ShibaFragmentとShibaPresenterで実装すべきinterfaceが定義されています

なお、`./app/src/main/java/com/github/outerheavenproject/wanstagram/`のパスは今後`<appRoot>/`と表現します。

### このプロジェクトの問題点 と、Daggerで解決できること

このプロジェクトは問題なくアプリが動いていますが、次の問題があります。

1.DogServiceのインスタンスを毎回生成してしまう。

シングルトンに管理したいインスタンスを、自分で生成・管理するのはめんどうです。Daggerを使うことで、安全にシングルトンでインスタンスを管理することが出来ます。

2.DogService RetrofitインターフェースをPresenter内で生成しているので、環境の切り替えが困難

これは、DIパターンを採用することで解決出来ます。Daggerを使うことで、DIパターンをお手軽に導入することが可能になります。

### Daggerのインストール

まず、Daggerを導入する最初の第一歩として、GradleにDaggerを設定します。
`dependencies`ブロック内に以下のように記述します。
また、`kapt`を使用するため、`kotlin-kapt`プラグインを有効にすることを忘れないようにします。

```./app/build.gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'kotlin-kapt' // 👈
apply plugin: 'kotlinx-serialization'

dependencies {
    // ...
    def dagger_version = '2.23.2'
    implementation "com.google.dagger:dagger:$dagger_version"
    kapt "com.google.dagger:dagger-compiler:$dagger_version"
}
```

書き換えたら `Sync Project with Gradle Files`を実行します。

### AppComponentをつくる

まず、`Component`アノテーションを使い、AppComponentを定義します。
`<appRoot>/AppComponent.kt` を作成します。

```kotlin
@Singleton
@Component
interface AppComponent {
    @Component.Factory
    interface Factory {
        fun create(): AppComponent
    }
}
```

上記のファイルを定義した後、`Make Project` を実行すると、アノテーションプロセッサーの自動生成により、`DaggerAppComponent`クラスが生成されます。

次に、`<appRoot>/App.kt` を作成してApplicationクラスを作成し、さきほど生成された`DaggerAppComponent`を使います。

```kotlin
class App : Application() {
    lateinit var appComponent: AppComponent

    override fun onCreate() {
        super.onCreate()
        appComponent = DaggerAppComponent.create()
    }
}
```

もちろん、AndroidManifest.xmlへのApplicationクラスの登録を忘れずに。

```./app/src/main/AndroidManifest.xml
<manifest ...>
    <!-- ... -->
    <application
        android:name=".App"
        ...
    />
        <!-- ... -->
    </application>
</manifest>
```

これで下準備は完了です。

### DogServiceインスタンスをDaggerで生成する

現在、DogService.ktに実装されている `getDogService()` をDaggerから提供するよう書き換えていきます。

`<appRoot>/DataModule.kt` を作成し、以下のように記述します。

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

> `"application/json".toMediaType()` は `import okhttp3.MediaType.Companion.toMediaType` を記述することで使用できるようになります。
> もし自動インポートされない場合は手動で上記import文を補ってみてください。

これだけだとまだDaggerのComponentに登録されていないので、AppComponentとDataModuleを結びつけます。

`<appRoot>/AppComponent.kt` を再び開き、以下のように書き換えます。

```kotlin
@Singleton
@Component(
    modules = [DataModule::class] // 👈
)
interface AppComponent {
    @Component.Factory
    interface Factory {
        fun create(): AppComponent
    }
}
```

### Daggerから提供されるインスタンスを使用する

先程の実装で、DaggerからRetrofitインスタンスを提供するようになりました。
しかし、まだ実際にRetrofitインスタンスを使用するクラスでDaggerから受け取る実装ができていません。

`getDogService()`は`DogPresenter`および`ShibaPresenter`で使用されています。
つまりこれらのクラスに対してDaggerから依存関係を注入する必要があります。
どちらもほぼ同じ構成なので、`DogPresenter`についてのみ解説します。

`DogPresenter.kt` を以下のように書き換えます。

```diff
-class DogPresenter(
-    private val view: DogContract.View
+class DogPresenter @Inject constructor(
+    private val dogService: DogService
 ) : DogContract.Presenter {
+    private lateinit var view: DogContract.View
+
+    fun attachView(view: DogContract.View) {
+        this.view = view
+    }
+
     override suspend fun start() {
-        val dogs = getDogService().getDogs(limit = 20)
+        val dogs = dogService.getDogs(limit = 20)
         withContext(Dispatchers.Main) {
             view.updateDogs(dogs)
         }
```

また、`DogFragment.kt`も書き換えます。
DogFragmentにおいて、DogPresenterをDaggerから注入してもらうように書き換えます。

```diff
 class DogFragment : Fragment(),
     DogContract.View {
-    private lateinit var presenter: DogContract.Presenter
+    @Inject
+    lateinit var presenter: DogPresenter
+
     private lateinit var dogAdapter: DogAdapter
 
+    override fun onAttach(context: Context) {
+        (activity!!.application as App).appComponent.inject(this) // 👈この時点ではメソッドが存在しませんがあとで解決されますからご安心を
+        super.onAttach(context)
+    }
+
     override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
         super.onViewCreated(view, savedInstanceState)
 
         val recycler = view.findViewById<RecyclerView>(R.id.recycler)
         dogAdapter = DogAdapter(navigator = AppNavigatorImpl())
         recycler.layoutManager = GridLayoutManager(context, 2)
         recycler.adapter = dogAdapter
 
-        presenter = DogPresenter(view = this)
+        presenter.attachView(view = this)
 
         lifecycleScope.launch {
             presenter.start()
         }
     }
```

さて、 `appComponent.inject(this)`が解決できていないので、`AppComponent.kt`を書き換えて解決します。

```diff
 interface AppComponent {
     @Component.Factory
     interface Factory {
         fun create(): AppComponent
     }
 
+    fun inject(fragment: DogFragment): DogFragment
+    fun inject(fragment: ShibaFragment): ShibaFragment
 }
```

### 動かしてみる

Android Studioの`Make Project` または `Command + F9` を実行します。
無事に実行出来たらDaggerの導入はひとまず無事に完了しました！

### 宿題

- `ShibaPresenter`も`DogService`をDaggerで注入するよう書き換えてみましょう。
- どちらのPresenterもDagger化が済んだなら、`DogService.kt`の`getDogService()`を削除しても動作するはずです。やってみよう。
- Dagger化する前とした後で `DogService` のインスタンスがどう変化しているか確認してみよう。（例えば `dogService.hashCode()` はインスタンスが同じかどうかを調べるには良い方法です）

### diff

masterとここまでの記事内容の想定回答のdiffです。

[Comparing master\.\.\.intro\-dagger · outer\-heaven2/dagger\-codelabs\-sample](https://github.com/outerheavenproject/dagger-codelabs-sample/compare/master...intro-dagger)
