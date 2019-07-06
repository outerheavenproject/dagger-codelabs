## 付録3: Custom Scope

ここでは先程の`Scope`に続いて、実際に自分で定義した`Scope`を使いながら、より実践的な使い方を紹介します。

今回はPetBookに、複数の写真を選択してシェアする機能を作りましょう。
おおまかな仕様としては以下のようになります。
- Bottom sheetからシェアする対象に追加できる
- Fabをタップすると、今まで追加した対象をまとめてシェアできる

`intro-dagger-scope`を見てみてください。今回主に使用するのは
- `MainActivity`
- `DogActionBottomSheetDialogFragment`

の2つです。
UIの作りについては本題とずれるため触れません。
依存関係は以下のようになっています。

![image](./07_Custom_Scope.png)

### `Scope`

今回は`Activity`のための`Scope`として`ActivityScope`、`Fragment`のための`Scope`として`FragmentScope`を定義しましょう。
カスタムスコープは以下のように定義します。

```kt
@Scope
@MustBeDocumented
@Retention(AnnotationRetention.RUNTIME)
annotation class ActivityScope
```

```kt
@Scope
@MustBeDocumented
@Retention(AnnotationRetention.RUNTIME)
annotation class FragmentScope
```

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
