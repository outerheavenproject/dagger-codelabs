## 序盤x: Subcomponentの導入

これまでの章で、Daggerの基本的な使い方を見てきました。Daggerをより便利に使うために、この章ではSubcomponentと呼ばれている機能について説明しています。

### Subcomponent

1つの大きなComponentがあったときに、その大きなComponentを小さいComponent（Subcomponet）に分割することで、依存関係を整理することを可能にする機能です。
また、スコープ（x章参照）をそれぞれのSubcomponentで定義することが出来ます。

### Subcomponentの定義

まず、MainActivityに対するSubcomponentを定義します。

```kotlin
@Subcomponent
interface MainActivitySubcomponent {
    fun inject(activity: MainActivity): MainActivity

    @Subcomponent.Factory
    interface Factory {
        fun create(): MainActivitySubcomponent
    }
}
```

Subcomponentを定義するには、セットでSubcomponent.Factoryを定義する必要があります。

次に、作成した`MainActivitySubcomponent`を親のComponentと結びつけます。

```kotlin
@Singleton
@Component(
    modules = [DataModule::class]
)
interface AppComponent {
    fun mainActivitySubcomponentFactory(): MainActivitySubcomponent.Factory
}
```

これで準備は完了です。

### Subcomponentを使う

次に、上記で作成した `MainActivitySubcomponent` を使います。

```kotlin
class App : Application() {
    lateinit var appComponent: AppComponent

    override fun onCreate() {
        super.onCreate()

        appComponent = DaggerAppComponent.create()
    }
}

class MainActivity : AppCompatActivity() {
    lateinit var subComponent: MainActivitySubcomponent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        subComponent = (application as App)
            .appComponent
            .mainActivitySubcomponentFactory()
            .create()
        subComponent.inject(this)
        ...
    }
}
```

これで完了です。

次の節から、Subcomponentの便利な機能を見ていきます。

### NavigatorをInjectableする
