## 補項: Custom Scope (実装)

Positive
: `Custom Scope (事前準備)` に引き続き Custom Scope について解説します。ここからは Custom Scope を実際に使ってみます。

### なぜ動かない？

以前 `Scope` の章で説明しましたが、Scopeが未指定の場合はインスタンスが毎回生成されます。
つまり、現時点ではすべての依存関係は（たとえ実装上共通のインスタンスが必要であったとしても）それぞれインスタンスが生成されており、独立している状態になっています。


### Custom Scopeの作成

この章で最重要の `Scope` アノテーションを実装しますが、内容は極めてシンプルです。

今回は`Activity`のための`Scope`として`ActivityScope`、`Fragment`のための`Scope`として`FragmentScope`を定義します。

`<srcBasePath>/di/ActivityScope.kt` を以下の内容で実装します。

```kt
@Scope
@MustBeDocumented
@Retention(AnnotationRetention.RUNTIME)
annotation class ActivityScope
```

`<srcBasePath>/di/FragmentScope.kt` を以下の内容で実装します。

```kt
@Scope
@MustBeDocumented
@Retention(AnnotationRetention.RUNTIME)
annotation class FragmentScope
```

Positive
: これらのCustomScopeの名称としては他には `@PerActivity`, `@PerFragment` と名付ける流派もあります。また [google/iosched](https://github.com/google/iosched) 2019年版では [`@ActivityScoped`](iosched/ActivityScoped.java at master · google/iosched https://github.com/google/iosched/blob/7935c28f249f32786ccc53bc0098d073065b1ec5/shared/src/main/java/com/google/samples/apps/iosched/shared/di/ActivityScoped.java), [`@FragmentScoped`](https://github.com/google/iosched/blob/7935c28f249f32786ccc53bc0098d073065b1ec5/shared/src/main/java/com/google/samples/apps/iosched/shared/di/FragmentScoped.kt) と名付けられています。


### ...

`MainActivity`のSubComponentに`ActivityScope`を付加します。

```kt
@ActivityScope
@ContributesAndroidInjector
fun contributeMainActivity(): MainActivity
```

続いて`DogActionBottomSheetDialogFragment`には`FragmentScope`を付加します。

```kt
@FragmentScope
@ContributesAndroidInjector
fun contributeDogActionBottomSheetDialogFragment(): DogActionBottomSheetDialogFragment
```

### `MainPresenter` / `DogActionSink`

さて、先程のクラス図を見ると`DogActionSink`というinterfaceがあることに気づくでしょう。
今回はこのinterfaceの`write`を呼び出すことで、シェアリストへの追加を実現します。
この`DogActionSink`の実体は`MainPresenter`です。

ここで考えるべきこととして、今の状態では`MainPresenter`のインスタンスを毎回生成するため、`DogActionSink`をいくら呼び出したとしても、`MainActivity`から見えるシェアリストは空であるということです。
`MainActivity`から参照される`MainContract$Presenter`、`DogActionBottomSheetPresenter`から参照される`DogActionSink`、これらはすべて同じインスタンスである必要があります。 (混乱するかもしれませんが、`MainContract$Presenter`と`DogActionSink`の実体は同じ`MainPresenter`です。)

この課題を解決できるのが`Scope`です。
まずは`MainPresenter`に`ActivityScope`を**付加せずに**試してみてください。

```kt
class MainPresenter @Inject constructor(
    private val view: MainContract.View
) : MainContract.Presenter, DogActionSink {
```

`MainPresenter#write`あたりにbreakpointを置いて確認してみると、Bottom sheetから参照される`MainPresenter`が毎回生成されていることが分かるでしょう。

それでは`MainPresenter`に`ActivityScope`を付加してみましょう。

```kt
@ActivityScope
class MainPresenter @Inject constructor(
    private val view: MainContract.View
) : MainContract.Presenter, DogActionSink {
```

今度はインスタンスが保持され、期待した挙動になっていることが確認できます。

### まとめ

このチャプターでは`Scope`の使い方について実際に挙動を見ながら確認していきました。
最近ではMVVMを採用する場合には`androidx.lifecycle.ViewModelProvider`もあるため`Scope`が必要な機会はかなり少なくなってきているかとは思いますが、Fluxなどを採用する場合には有効な知識です。

