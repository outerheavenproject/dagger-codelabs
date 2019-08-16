## トラブルシューティング: Provide/Bindのし忘れ

Positive
: ここから先のトラブルシューティング章では、Daggerを使う上でよく目にするエラーを確認しながら直していきます。動作しないコードが含まれるbranchをcheckoutすることで、実際のエラーを引き起こした後、エラーを修正します。

まずはProvideまたはBindをし忘れているケースです。
`troubleshooting-bind-and-provide` branchをcheckoutしてbuildしてください。
以下のエラーが出るはずです。

```
エラー: [Dagger/MissingBinding] com.github.outerheavenproject.wanstagram.ui.dog.DogContract.Presenter cannot be provided without an @Provides-annotated method.
public abstract interface AppComponent extends dagger.android.AndroidInjector<com.github.outerheavenproject.wanstagram.App> {
                ^
      com.github.outerheavenproject.wanstagram.ui.dog.DogContract.Presenter is injected at
          com.github.outerheavenproject.wanstagram.ui.dog.DogFragment.presenter
      com.github.outerheavenproject.wanstagram.ui.dog.DogFragment is injected at
          dagger.android.AndroidInjector.inject(T) [com.github.outerheavenproject.wanstagram.AppComponent → com.github.outerheavenproject.wanstagram.ui.MainActivityModule_ContributeMainActivity.MainActivitySubcomponent → com.github.outerheavenproject.wanstagram.ui.dog.DogFragmentModule_ContributeDogFragment.DogFragmentSubcomponent]
```

これは`DogFragment`が`DogContract.Presenter`を必要としているが、`DogContract.Presenter`がどこからも供給されておらず、依存が解決できないことを示しています。
この場合、解決方法としては`Provide`するか`Bind`するかの大きく2つがあります。今回、`DogContract.Presenter`は`DogPresenter`で実装されており、bindするだけで良いです。

この依存は`DogFragment`で解決できれば良いので、`DogFragmentBindModule`を新たに定義し、`DogFragmentSubcomponent`にinstallします。

```kt
@Module
interface DogFragmentModule {
    @ContributesAndroidInjector(
        modules = [
            DogFragmentBindModule::class
        ]
    )
    fun contributeDogFragment(): DogFragment
}

@Module
interface DogFragmentBindModule {
    @Binds
    fun bindPresenter(presenter: DogPresenter): DogContract.Presenter
}
```
