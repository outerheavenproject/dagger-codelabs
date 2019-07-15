## トラブルシューティング4: 再帰

次は`troubleshooting-recursion` branchをcheckoutしbuildして下さい。

```
e: [kapt] An exception occurred: java.lang.StackOverflowError
```

これは`Module`定義などがループしている場合に起きるエラーです。発生した場合は再帰的な参照が発生している箇所を探す必要があります。

この場合は`DogFragmentModule`の定義がループしていますので、これを修正すれば良いです。

```kt
@Module
interface DogFragmentModule {
    @ContributesAndroidInjector
    fun contributeDogFragment(): DogFragment
}
```
