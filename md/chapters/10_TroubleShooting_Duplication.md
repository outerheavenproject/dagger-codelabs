## トラブルシューティング: 定義の重複

`troubleshooting-duplicate` branchをcheckoutしてbuildして下さい。
以下のようなエラーが発生します。

```
エラー: [Dagger/DuplicateBindings] com.github.outerheavenproject.wanstagram.ui.AppNavigator is bound multiple times:
public abstract interface AppComponent extends dagger.android.AndroidInjector<com.github.outerheavenproject.wanstagram.App> {
                ^
      @org.jetbrains.annotations.NotNull @Binds com.github.outerheavenproject.wanstagram.ui.AppNavigator com.github.outerheavenproject.wanstagram.ui.MainActivityBindModule.bindAppNavigator(com.github.outerheavenproject.wanstagram.ui.AppNavigatorImpl)
      @org.jetbrains.annotations.NotNull @Binds com.github.outerheavenproject.wanstagram.ui.AppNavigator com.github.outerheavenproject.wanstagram.ui.dog.DogFragmentBindModule.bindAppNavigator(com.github.outerheavenproject.wanstagram.ui.AppNavigatorImpl)
      com.github.outerheavenproject.wanstagram.ui.AppNavigator is injected at
          com.github.outerheavenproject.wanstagram.ui.DogAdapter(…, navigator)
      com.github.outerheavenproject.wanstagram.ui.DogAdapter is injected at
          com.github.outerheavenproject.wanstagram.ui.dog.DogFragment.dogAdapter
      com.github.outerheavenproject.wanstagram.ui.dog.DogFragment is injected at
          dagger.android.AndroidInjector.inject(T) [com.github.outerheavenproject.wanstagram.AppComponent → com.github.outerheavenproject.wanstagram.ui.MainActivityModule_ContributeMainActivity.MainActivitySubcomponent → com.github.outerheavenproject.wanstagram.ui.dog.DogFragmentModule_ContributeDogFragment.DogFragmentSubcomponent]
```

これは定義が重複している場合に発生します。
1人のプロジェクトや小規模なプロジェクトではあまり起きませんが、大規模なプロジェクトでグラフを完全に把握出来ていないような場合にしばしば発生します。

今回の場合は`AppNavigator`の定義が`MainActivityModule`と`DogFragmentModule`で重複しています。一方の不要な定義を消すことで解消します。

```kt
@Module
interface DogFragmentModule {
    @ContributesAndroidInjector
    fun contributeDogFragment(): DogFragment
}
```
