## トラブルシューティング3: Scopeのつけ間違い

次のケースは`Scope`をつけ間違えている場合です。
`troubleshooting-different-scope` branchをcheckoutしてください。

```
エラー: [Dagger/IncompatiblyScopedBindings] com.github.outerheavenproject.wanstagram.ui.MainActivityModule_ContributeMainActivity.MainActivitySubcomponent scoped with @com.github.outerheavenproject.wanstagram.di.ActivityScope may not reference bindings with different scopes:
public abstract interface AppComponent extends dagger.android.AndroidInjector<com.github.outerheavenproject.wanstagram.App> {
                ^
      @com.github.outerheavenproject.wanstagram.di.FragmentScope class com.github.outerheavenproject.wanstagram.ui.MainPresenter [com.github.outerheavenproject.wanstagram.AppComponent → com.github.outerheavenproject.wanstagram.ui.MainActivityModule_ContributeMainActivity.MainActivitySubcomponent]
```

これは`Scope`のライフサイクルを間違えて`Inject`している場合に起きます。例えば、`Fragment`のライフサイクルに応じた`Scope`を付加しているクラスを`Activity`に対して`Inject`しようとしている場合などです。`Fragment`の`Subcomponent`を`Activity`の`Subcomponent`の子として定義している場合には、この関係は成立しないため、エラーとなります。
また、親子関係にない場合でもそれぞれに付加している`Scope`を間違えて使用した場合には起きます。

この修正方法としては、`Scope`を正しくつけ直すことが必要となります。
エラーメッセージを見て下さい。
`MainActivitySubcomponent`は`ActivityScope`が付加されているが、`MainPresenter`には`FragmentScope`が付加されていると書いてあります。
今回の場合、`MainPresenter`は`MainActivity`で使用されるため、`ActivityScope`が妥当です。そのように修正すれば、このエラーは解消できます。

```kt
@ActivityScope
class MainPresenter @Inject constructor(
    private val view: MainContract.View
) : MainContract.Presenter, DogActionSink {
```
