## 付録1: Dagger.Android を使用したAndroidに特化した記述

<!--
start: intro-dagger-subcomponent
goal:  intro-dagger-android-support
-->

Dagger.Androidを使用することで、AndroidにおけるDaggerの利便性を高めることが出来ます。
実際に使っていきながら見ていきましょう。

### `HasAndroidInjector`

まずは`App`で`HasAndroidInjector`を実装します。
`HasAndroidInjector`は`AndroidInjector`を提供します。
`AndroidInjector`は`Activity`、`Fragment`などの主要なAndroidの要素について、依存関係の解決を行うためのinterfaceです。

`Application`に対して`HasAndroidInjector`を実装することで、`Activity`や`Service`などの依存関係を解決することが出来ます。なぜ`Application`に実装すると`Activity`の依存関係が解決できるかというと、`dagger.android.AndroidInjection`が内部的に`Activity`などから`Application`を取得し、`inject`を行うためです。

```kt
class App : Application(), HasAndroidInjector {
    @Inject
    lateinit var dispatchingAndroidInjector: DispatchingAndroidInjector<Any>

    ...

    override fun androidInjector(): AndroidInjector<Any> = dispatchingAndroidInjector
}
```

先程、`Activity`の依存関係が解決できると書きましたが、では`Application`の依存関係はどう解決すればよいのでしょうか？
それを次に説明します。

### Applicationの依存関係を解決する

さて、`App`の依存関係を解決しましょう。
`AppComponent`が`AndroidInjector<App>`を継承するように変更を加えます。

```kt
interface AppComponent : AndroidInjector<App>
```

そして、`AndroidInjector#inject`を`App`から呼び出すことで`App`の依存関係を解決します。

```kt
override fun onCreate() {
    super.onCreate()
    DaggerAppComponent
        .factory()
        .create()
        .inject(this)
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
interface AppComponent : AndroidInjector<App>
```

### Activityの依存関係を解決する

次に`MainActivity`の依存関係を解決します。
まずは`MainActivityModule`を定義しましょう

```kt
@Module
interface MainActivityModule {
    @ContributesAndroidInjector
    fun contributeMainActivity(): MainActivity
}
```

これを`AppComponent`にインストールします。
直接インストールしても良いのですが、多くのアプリにおいて`Activitiy`やその他の依存関係は複雑になっていくため、別途`ActivityModule`を用意するのも良いでしょう。

```kt
@Module(
    includes = [
        MainActivityModule::class
    ]
)
interface ActivityModule
```

```kt
@Component(
    modules = [
        AndroidInjectionModule::class,
        ActivityModule::class
    ]
)
```

これで準備は整いました。
あとは`MainActivity`の`onCreate`で`AndroidInjection#inject`を呼び出します。

```kt
override fun onCreate(savedInstanceState: Bundle?) {
    AndroidInjection.inject(this)
    super.onCreate(savedInstanceState)
    ...
}
```

### Fragmentの依存関係を解決する

今度は`DogFragment`の依存関係を解決しましょう。
まずは先程と同様に`DogFragmentModule`を定義します。

```kt
@Module
interface DogFragmentModule {
    @ContributesAndroidInjector
    fun contributeDogFragment(): DogFragment
}
```

これは`MainActivitySubcomponent`にインストールします。この`Subcomponent`は生成されるため、以下のように記述します。

```kt
@Module
interface MainActivityModule {
    @ContributesAndroidInjector(
        modules = [
            DogFragmentModule::class
        ]
    )
    fun contributeMainActivity(): MainActivity
}
```

ここでなぜ`AppComponent`にインストールしないのか疑問に思うかもしれません。
実際、`AppComponent`にインストールしても動きますし、困らないかもしれません。
これは後で説明する`Scope`の概念に大きく関わってくる部分ですので、今はこういうものだと思って書いてみてください。興味があれば「付録2: Scope」を参照してください。

さて、本題に戻りますが、`Fragment`の場合は`Activity`にも変更が必要です。
`MainActivity`にも`HasAndroidInjector`を実装しましょう。

```kt
class MainActivity : AppCompatActivity(),
    HasAndroidInjector {
    @Inject
    lateinit var dispatchingAndroidInjector: DispatchingAndroidInjector<Any>

    ...

    override fun androidInjector(): AndroidInjector<Any> = dispatchingAndroidInjector
}
```

後は`Activity`の場合と同じです。
`Fragment`の場合は`AndroidSupportInjection`を使用します。

```kt
override fun onAttach(context: Context) {
    AndroidSupportInjection.inject(this)
    super.onAttach(context)
}
```

`DialogFragment`や`BottomSheetDialogFragment`の場合も同じように書くことが出来ます。

### もっと簡単に書く

ここまで説明してきましたが、`HasAndroidInjector`の実装や、`inject`についてはそれぞれ実装済みの基底クラスが用意されています。

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
