## Scope

<!--
start: intro-dagger-android-support
goal:  intro-dagger-scope
-->

`Scope`を定義し使用することでライフサイクルに沿ったインスタンスを受け取ることが出来ます。
実際に`Scope`を使用しながら感覚を掴んでいきましょう。

Daggerですでに定義されている`Scope`として`Singleton`があります。
これがどのように作用するか見ていきましょう。

### Repositoryを作る

今回は、`Service`と`Presenter`の間に`Repository`を定義し、Responseを保持して逐一APIにアクセスしなくても良い方法を考えます。
まずは`Repository`を定義しましょう。

```kt
class DogRepository @Inject constructor(
    private val dogService: DogService
) {
    companion object {
        private const val LIMIT = 20
    }

    private var dogs: Dogs? = null

    suspend fun findAll(): Dogs {
        dogs?.let { return it }
        return dogService.getDogs(LIMIT)
            .also { dogs = it }
    }
}
```

`Dogs`を保持し、あればそちらを返す、なければ新たに取得します。

`DogPresenter`で`DogService`の代わりに使用しましょう。

```kt
class DogPresenter @Inject constructor(
    private val repository: DogRepository
) : DogContract.Presenter {

    ...

    override suspend fun start() {
        val dogs = repository.findAll()
        ...
    }
}
```

Negative
: ShibaPresenterではRepositoryを実装していないので、「柴犬」タブでは依然として毎回APIリクエストが発生します

この状態でビルドして、「犬」タブから「柴犬」タブに行き、また「犬」タブを開いてみてください。
すると、Repositoryを設定したにもかかわらず、うまく機能していない(毎回APIにアクセスしている)ことが分かるはずです。
これは`Repository`のインスタンスが毎回生成されるため、`Dogs`の状態を保持できていないからです。

このような場合に`Scope`が役立ちます。
`Singleton`を付加してもう一度試してみましょう。

```kt
@Singleton // 👈
class DogRepository @Inject constructor(
```

今度はタブを切り替えても同じ画像が表示されます。
これが基本的な`Scope`の使い方です。

Positive
: Custom Scopeに関する解説を "補項" として用意してあります

### 宿題

今回は宿題ありません😃

### diff

ここまでのdiffは以下のページで確認できます。

[Comparing intro\-dagger\-android\-support\.\.\.intro\-dagger\-scope · outerheavenproject/dagger\-codelabs\-sample](https://github.com/outerheavenproject/dagger-codelabs-sample/compare/intro-dagger-android-support...intro-dagger-scope)

