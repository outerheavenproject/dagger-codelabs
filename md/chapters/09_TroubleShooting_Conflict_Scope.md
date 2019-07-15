## トラブルシューティング2: ScopeのConflict

次のケースは`Scope`がConflictしている場合です。
`troubleshooting-conflict-scope` branchをcheckoutしてください。

```
エラー: [net.pside.android.example.petbook.ui.dog.DogFragmentModule_ContributeDogFragment.DogFragmentSubcomponent] net.pside.android.example.petbook.ui.dog.DogFragmentModule_ContributeDogFragment.DogFragmentSubcomponent has conflicting scopes:
public abstract interface AppComponent extends dagger.android.AndroidInjector<net.pside.android.example.petbook.App> {
                ^
    net.pside.android.example.petbook.ui.MainActivityModule_ContributeMainActivity.MainActivitySubcomponent also has @net.pside.android.example.petbook.di.MyScope
```

これは親子関係にある`Subcomponent`に対して同じ`Scope`を付加しているために発生します。
エラーメッセージにある通り、`MainActivitySubcomponent`に付加した`Scope`が`DogFragmentSubcomponent`にも付加されています。
これはどちらかが正しい`Scope`を付加されば解決です。

```kt
@Module
interface DogFragmentModule {
    // @MyScope
    @ContributesAndroidInjector
    fun contributeDogFragment(): DogFragment
}
```
