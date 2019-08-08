## トラブルシューティング4: 定義の重複

`troubleshooting-duplicate` branchをcheckoutしてbuildして下さい。
以下のようなエラーが発生します。

```
エラー: [Dagger/DuplicateBindings] net.pside.android.example.petbook.ui.AppNavigator is bound multiple times:
public abstract interface AppComponent extends dagger.android.AndroidInjector<net.pside.android.example.petbook.App> {
                ^
      @org.jetbrains.annotations.NotNull @Binds net.pside.android.example.petbook.ui.AppNavigator net.pside.android.example.petbook.ui.MainActivityBindModule.bindAppNavigator(net.pside.android.example.petbook.ui.AppNavigatorImpl)
      @org.jetbrains.annotations.NotNull @Binds net.pside.android.example.petbook.ui.AppNavigator net.pside.android.example.petbook.ui.dog.DogFragmentBindModule.bindAppNavigator(net.pside.android.example.petbook.ui.AppNavigatorImpl)
      net.pside.android.example.petbook.ui.AppNavigator is injected at
          net.pside.android.example.petbook.ui.DogAdapter(navigator)
      net.pside.android.example.petbook.ui.DogAdapter is injected at
          net.pside.android.example.petbook.ui.dog.DogFragment.dogAdapter
      net.pside.android.example.petbook.ui.dog.DogFragment is injected at
          dagger.android.AndroidInjector.inject(T) [net.pside.android.example.petbook.AppComponent → net.pside.android.example.petbook.ui.MainActivityModule_ContributeMainActivity.MainActivitySubcomponent → net.pside.android.example.petbook.ui.dog.DogFragmentModule_ContributeDogFragment.DogFragmentSubcomponent]
```

これは定義が重複している場合に発生します。
1人のプロジェクトや小規模なプロジェクトではあまり起きませんが、大規模なプロジェクトでグラフを完全に把握出来ていないような場合にしばしば発生します。

今回の場合は`AppNavigator`の定義が重複しています。一方の不要な定義を消すことで解消します。

```kt
@Module
interface DogFragmentModule {
    @ContributesAndroidInjector
    fun contributeDogFragment(): DogFragment
}
```
