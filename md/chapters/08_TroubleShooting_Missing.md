## トラブルシューティング1: Provide/Bindのし忘れ

ここから先はトラブルシューティングとして、Daggerを使う上でよく目にするエラーを確認しながら直していきましょう。

まずはProvideまたはBindをし忘れているケースです。
`troubleshooting-bind-and-provide` branchをcheckoutしてbuildしてください。
以下のエラーが出るはずです。

```
エラー: [Dagger/MissingBinding] net.pside.android.example.petbook.ui.dog.DogContract.Presenter cannot be provided without an @Provides-annotated method.
public abstract interface AppComponent extends dagger.android.AndroidInjector<net.pside.android.example.petbook.App> {
                ^
      net.pside.android.example.petbook.ui.dog.DogContract.Presenter is injected at
          net.pside.android.example.petbook.ui.dog.DogFragment.presenter
      net.pside.android.example.petbook.ui.dog.DogFragment is injected at
          dagger.android.AndroidInjector.inject(T) [net.pside.android.example.petbook.AppComponent → net.pside.android.example.petbook.ui.MainActivityModule_ContributeMainActivity.MainActivitySubcomponent → net.pside.android.example.petbook.ui.dog.DogFragmentModule_ContributeDogFragment.DogFragmentSubcomponent]
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
