## Dagger.Androidを使用したAndroidに特化した記述

<!--
start: intro-dagger-subcomponent
goal:  intro-dagger-android-support
-->

Dagger.Androidを使用することで、AndroidにおけるDaggerの利便性を高めることが出来ます。
実際に使っていきながら見ていきましょう。

### Dagger.Androidのライブラリの追加

Dagger.AndroidはDaggerとは別のライブラリとして提供されています。
`./app/build.gradle` に以下の依存を追加します。

```gradle
// ...
dependencies {
    // ...
    implementation "com.google.dagger:dagger-android:$dagger_version"
    implementation "com.google.dagger:dagger-android-support:$dagger_version"
    kapt "com.google.dagger:dagger-android-processor:$dagger_version"
}
```

### `HasAndroidInjector`の実装

まずは`App`で`HasAndroidInjector` interfaceを実装します。
このinterfaceは`AndroidInjector`を提供します。
`AndroidInjector`は`Activity`、`Fragment`などの主要なAndroidの要素について、依存関係の解決を行うためのinterfaceです。

`Application`に対して`HasAndroidInjector`を実装することで、`Activity`や`Service`などの依存関係を解決することが出来ます。なぜ`Application`に実装すると`Activity`の依存関係が解決できるかというと、`dagger.android.AndroidInjection`が内部的に`Activity`などから`Application`を取得し、`inject`を行うためです。

```kt
class App : Application(), HasAndroidInjector {
    @Inject
    lateinit var dispatchingAndroidInjector: DispatchingAndroidInjector<Any>

    // ...

    override fun androidInjector(): AndroidInjector<Any> = dispatchingAndroidInjector
}
```

先程、`Activity`の依存関係が解決できると書きましたが、では`Application`の依存関係はどう解決すればよいのでしょうか？
それを次に説明します。

### Applicationの依存関係を解決する

さて、`App`の依存関係を解決しましょう。
`AppComponent`が`AndroidInjector<App>`を継承するように変更を加えます。
`AppComponent.kt`のこれまでの内容を以下に書き換えてしまいます。
`Factory`interfaceの内容を、`AndroidInjector.Factory`を使用するようにします。

```kt
@Component
interface AppComponent : AndroidInjector<App> {
    @Component.Factory
    interface Factory : AndroidInjector.Factory<App>
}
```

そして、`AndroidInjector#inject`を`App`から呼び出すことで`App`の依存関係を解決します。

```diff
 class App : Application(), HasAndroidInjector {
     // ...
     override fun onCreate() {
         super.onCreate()
-        appComponent = DaggerAppComponent.create()
+        DaggerAppComponent
+            .factory()
+            .create(this)
+            .inject(this)
     }
     // ...
 }
```

また、`AndroidInjectionModule`を`AppComponent`にインストールしておきましょう。
これは`DispatchingAndroidInjector`が依存関係を解決するために必要とするものです。


```kt
@Component(
    modules = [
        AndroidInjectionModule::class
    ]
)
interface AppComponent : AndroidInjector<App> {
    // ...
}
```

### Activityの依存関係を解決する

`MainActivity`の依存関係を解決します。
まずは`<srcBasePath>/ui/MainActivityModule.kt`を作成します。`MainActivity.kt`と同じ改装にあるのが望ましいでしょう。

Positive
: これまでの章の `MainActivitySubcomponent` をDagger.Androidウェイな方法で実装しなおします。よって、すべてが完了したタイミングで`MainActivitySubcomponent.kt`は削除できます。

```kt
@Module
interface MainActivityModule {
     @ContributesAndroidInjector(
        modules = [
            MainActivityBindModule::class,
        ]
    )
    fun contributeMainActivity(): MainActivity
}

@Module
interface MainActivityBindModule {
    @Binds
    fun bindContext(context: MainActivity): Context

    @Binds
    fun bindAppNavigator(navigator: AppNavigatorImpl): AppNavigator
}
```

次に、`MainActivityModule`を`AppComponent`にインストールします。

直接インストールしても良いのですが、多くのアプリにおいて`Activity`やその他の依存関係は複雑になっていくため、別途`ActivityModule`を用意します。
`<srcBasePath>/ActivityModule.kt`を作成し、以下の内容で実装します。

```kt
@Module(
    includes = [
        MainActivityModule::class
    ]
)
interface ActivityModule
```

`AppComponent`には以下のように`ActivityModule::class`を足します。

```kt
@Component(
    modules = [
        AndroidInjectionModule::class,
        ActivityModule::class // 👈
    ]
)
interface AppComponent : AndroidInjector<App> {
    // ...
}
```

これで準備は整いました。
あとは`MainActivity`の`onCreate`で`AndroidInjection#inject`を呼び出します。

```kt
override fun onCreate(savedInstanceState: Bundle?) {
    AndroidInjection.inject(this)
    super.onCreate(savedInstanceState)
    // subComponent = ... は不要なので削除してよい
    // ...
}
```

Positive
: `super.onCreate()`よりも先に`AndroidInjection.inject()`を実行する理由は・・・　TODO: なんでだっけ？

### Fragmentの依存関係を解決する

今度は`DogFragment`の依存関係を解決しましょう。
まずは先程と同様に`DogFragmentModule`を定義します。
`<srcBasePath>/ui/dog/DogFragmentModule.kt` を作成し、以下のように実装します。
`DogFragment.kt`と同階層にあるのが望ましいでしょう。

```kt
@Module
interface DogFragmentModule {
    @ContributesAndroidInjector
    fun contributeDogFragment(): DogFragment
}
```

これは`MainActivitySubcomponent`にインストールします。この`Subcomponent`はaptにより自動生成されるます。

`MainActivityModule.kt` に以下のように追記します。

```kt
@Module
interface MainActivityModule {
    @ContributesAndroidInjector(
        modules = [
            DogFragmentModule::class // 👈
        ]
    )
    fun contributeMainActivity(): MainActivity
}
```

Positive
: なぜ`AppComponent`にインストールしないのか疑問に思うかもしれません。<br>実際、`AppComponent`にインストールしても動きますし、困らないかもしれません。これは後で説明する`Scope`の概念に大きく関わってくる部分ですので、今はこういうものだと思って書いてみてください。「Scope」の章を参照してください。

`Fragment`の依存関係を解決する場合は、そのFragmentがcommitされる`Activity`にも変更が必要です。
`MainActivity`にも`HasAndroidInjector`を実装しましょう。

```kt
class MainActivity : AppCompatActivity(),
    HasAndroidInjector { // 👈 HasAndroidInjectorを実装する

    @Inject
    lateinit var dispatchingAndroidInjector: DispatchingAndroidInjector<Any>
    // 👆

    // ...

    // 👇
    override fun androidInjector(): AndroidInjector<Any> = dispatchingAndroidInjector
}
```

後は`Activity`の場合と同じです。
`Fragment`の場合は`AndroidSupportInjection`を使用します。

```diff
 override fun onAttach(context: Context) {
-    (activity as MainActivity).subComponent.inject(this)
+    AndroidSupportInjection.inject(this)
     super.onAttach(context)
 }
```

Positive
: `DialogFragment`や`BottomSheetDialogFragment`の場合も同じように書くことが出来ます。

### もっと簡単に書く

ここまでいろいろと説明してきましたが、`HasAndroidInjector`の実装や、`inject`についてはそれぞれ実装済みの基底クラスが用意されています。

- `DaggerApplication`
- `DaggerAppCompatActivity`
- `DaggerFragment`

などです。

例えば`DaggerApplication`を使うと

```kt
class App : DaggerApplication() {
    override fun applicationInjector(): AndroidInjector<out DaggerApplication> =
        DaggerAppComponent.factory().create()
}
```

このように、多くのボイラープレートコードを削ることが出来ます。
はじめから使ってしまうと何をしているかが分かりづらくなってしまうため、使わない方法を先に紹介しました。
すでに基底クラスがある場合などは、`Dagger*`を使わない方が良い場合も出てくるでしょう。

例えば[DaggerActivityの実装](https://github.com/google/dagger/blob/beed87cc75439d873a2f53dbd70306266023d766/java/dagger/android/DaggerActivity.java)は以下のようになっています。DaggerActivityを用いれば、これらの実装を省略できます。他のクラスに関しても同様です。

```java
/**
 * An {@link Activity} that injects its members in {@link #onCreate(Bundle)} and can be used to
 * inject {@link Fragment}s attached to it.
 */
@Beta
public abstract class DaggerActivity extends Activity implements HasAndroidInjector {

  @Inject DispatchingAndroidInjector<Object> androidInjector;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    AndroidInjection.inject(this);
    super.onCreate(savedInstanceState);
  }

  @Override
  public AndroidInjector<Object> androidInjector() {
    return androidInjector;
  }
}
```

Negative
: `android.app.Activity` と Support Libraryの `android.support.v7.app.AppCompatActivity` で提供しているクラスが異なるため、間違わないように注意してください。

### 宿題

- ShibaFragmentのDagger.Android化がまだ済んでいません。やってみよう。
- 実際に動かしてみて、きちんと動作するか確認しよう。
- 下のdiffを開き、Subcomponentを使用した場合とそうでない場合のコードを見比べてみよう。
    - 特に、キャストをしているコードが（見かけ上）キャスト不要になっているあたりとか。
- `DaggerApplication`, `DaggerAppCompatActivity` などを用いたやり方を試してみよう。（なお、今後出てくるコードでは`DaggerApplication`などを使う方法ではなく、今回解説したコードベースで説明が続きます。。。）

### diff

ここまでのdiffは以下のページで確認できます。

[Comparing intro\-dagger\-subcomponent\.\.\.intro\-dagger\-android\-support · outerheavenproject/dagger\-codelabs\-sample](https://github.com/outerheavenproject/dagger-codelabs-sample/compare/intro-dagger-subcomponent...intro-dagger-android-support)

