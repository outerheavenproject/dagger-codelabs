## トラブルシューティング2: ScopeのConflict

次のケースは`Scope`がConflictしている場合です。
`troubleshooting-conflict-scope` branchをcheckoutしてください。

```
エラー: [com.github.outerheavenproject.wanstagram.ui.dog.DogFragmentModule_ContributeDogFragment.DogFragmentSubcomponent] com.github.outerheavenproject.wanstagram.ui.dog.DogFragmentModule_ContributeDogFragment.DogFragmentSubcomponent has conflicting scopes:
public abstract interface AppComponent extends dagger.android.AndroidInjector<com.github.outerheavenproject.wanstagram.App> {
                ^
    com.github.outerheavenproject.wanstagram.ui.MainActivityModule_ContributeMainActivity.MainActivitySubcomponent also has @com.github.outerheavenproject.wanstagram.di.MyScope
```

これは親子関係にある`Subcomponent`に対して同じ`Scope`を付加しているために発生します。
エラーメッセージにある通り、`MainActivitySubcomponent`に付加した`Scope`が`DogFragmentSubcomponent`にも付加されています。

// TODO: MainActivityModuleとMainActivitySubComponentの関係を説明したい

これはどちらかが正しい`Scope`を使うよう修正すれば解決です。

```kt
@Module
interface DogFragmentModule {
    // @MyScope
    @ContributesAndroidInjector
    fun contributeDogFragment(): DogFragment
}
```
