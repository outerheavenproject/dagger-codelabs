## Subcomponentの導入

<!--
start: intro-dagger-build-types
goal:  intro-dagger-subcomponent
-->

これまでの章で、Daggerの基本的な使い方を見てきました。Daggerをより便利に使うために、この章ではSubcomponentと呼ばれている機能について説明しています。

### Subcomponent

1つの大きなComponentがあったときに、その大きなComponentを小さいComponent（Subcomponet）に分割することで、依存関係を整理することを可能にする機能です。
また、スコープをそれぞれのSubcomponentで定義することが出来ます（スコープは後の章で説明します）。
これにより、どの`Context`を使うのか、というAndroid固有の問題を解決することが出来ます。

### Subcomponentの定義

まず、MainActivityに対するSubcomponentを定義します。
`<srcBasePath>/MainActivitySubcomponent.kt` を以下のように実装します。

```kotlin
@Subcomponent(modules = [MainActivityModule::class])
interface MainActivitySubcomponent {
    fun inject(activity: MainActivity): MainActivity
    fun inject(fragment: DogFragment): DogFragment
    fun inject(fragment: ShibaFragment): ShibaFragment

    @Subcomponent.Factory
    interface Factory {
        fun create(
            @BindsInstance context: Context
        ): MainActivitySubcomponent
    }
}

@Module
interface MainActivityModule {
    @Binds
    fun bindAppNavigator(navigator: AppNavigatorImpl): AppNavigator
}
```

Subcomponentを定義するには、セットで `Subcomponent.Factory` を定義する必要があります。
`@BindsInstance`を使うことで、引数として与えられたインスタンスを用いて、型の解決を試みるようになります。

次に、作成した`MainActivitySubcomponent`を親のComponentと結びつけます。
あわせて、`MainActivitySubcomponent`に定義が移動したFragmentのinject定義を削除します。

```diff
 @Singleton
 @Component(
     // ...
 )
 interface AppComponent {
     // ...
 
-    fun inject(fragment: DogFragment): DogFragment
-    fun inject(fragment: ShibaFragment): ShibaFragment
+    fun mainActivitySubcomponentFactory(): MainActivitySubcomponent.Factory
 }
```

これで準備は完了です。

### Subcomponentを使う

上記で作成した `MainActivitySubcomponent` を実際に使ってみます。

```kotlin
class MainActivity : AppCompatActivity() {
    lateinit var subComponent: MainActivitySubcomponent // 👈

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 👇
        subComponent = (application as App)
            .appComponent
            .mainActivitySubcomponentFactory()
            .create(this)
        subComponent.inject(this)
        // 👆
        
        // ...
    }
}
```

先程解説をした `@BindsInstance` は `mainActivitySubcomponentFactory().create(this)` にて与えられます。よって、Subcomponent内で `Context` が要求されたときは、`MainActivity`が使われることになります。

次に `AppNavigator.kt` を以下のように置き換え、`Context`の依存解決をするようにします。

```diff
 interface AppNavigator {
-    fun navigateToDetail(context: Context, imageUrl: String)
+    fun navigateToDetail(imageUrl: String)
 }

-class AppNavigatorImpl : AppNavigator {
-    override fun navigateToDetail(context: Context, imageUrl: String) {
+class AppNavigatorImpl @Inject constructor(
+    private val context: Context
+) : AppNavigator {
+    override fun navigateToDetail(imageUrl: String) {
         context.startActivity(DetailActivity.createIntent(context, imageUrl))
     }
 }
```

次に `DogAdapter.kt` を以下のように置き換えます。

```diff
-class DogAdapter(
+class DogAdapter @Inject constructor(
     private val navigator: AppNavigator
 ) : ListAdapter<String, DogViewHolder>(DogDiffUtil) {
     // ...
 
     override fun onBindViewHolder(holder: DogViewHolder, position: Int) {
         // ...
         holder.itemView.setOnClickListener {
-            navigator.navigateToDetail(it.context, dogUrl)
+            navigator.navigateToDetail(dogUrl)
         }
     }
 }
```

次に `DogFragment.kt` を以下のように書き換え、`DogAdapter` の依存解決をします。

```diff
 class DogFragment : Fragment(),
     DogContract.View {
     @Inject
     lateinit var presenter: DogPresenter
-    private lateinit var dogAdapter: DogAdapter
+
+    @Inject
+    lateinit var dogAdapter: DogAdapter
 
     override fun onAttach(context: Context) {
-        (activity!!.application as App).appComponent.inject(this)
+        (activity as MainActivity).subComponent.inject(this)
         super.onAttach(context)
     }
 
     // ...
 
     override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
         super.onViewCreated(view, savedInstanceState)
 
         val recycler = view.findViewById<RecyclerView>(R.id.recycler)
-        dogAdapter = DogAdapter(navigator = AppNavigatorImpl())
         recycler.layoutManager = GridLayoutManager(context, 2)
         recycler.adapter = dogAdapter
         // ...
     }
 
     // ...
 }
```

`DogFragment.kt` と同じように `ShibaFragment.kt` も書き換えます。

### 宿題

- 実際に実行してみましょう。サムネイルをタップしてDetailActivityが無事に表示されればOK。
- 以下のように書き換えてみるとどうなるか試してみましょう。`Context`は一致しているのでコンパイルも通り、一見アプリも動きますが、サムネイルをタップするとクラッシュします。理由はLogcatをみると分かります。確認してみましょう。

`AppComponent.kt`:

```diff
     @Component.Factory
     interface Factory {
-        fun create(): AppComponent
+        fun create(
+            @BindsInstance context: Context
+        ): AppComponent
     }
```

`App.kt`:

```diff
-        appComponent = DaggerAppComponent.create()
+        appComponent = DaggerAppComponent.factory().create(this)
```

`MainActivitySubcomponent.kt`:

```diff
     @Subcomponent.Factory
     interface Factory {
         fun create(
-            @BindsInstance context: Context
         ): MainActivitySubcomponent
     }
```

`MainActivity.kt`:

```diff
         subComponent = (application as App)
             .appComponent
             .mainActivitySubcomponentFactory()
-            .create(this)
+            .create()
```

- ApplicationContextとActivityContextを共存させたいときがありますが、このままだとうまくいきません。どうすればいいでしょうか？
    - 上記の `MainActivitySubcomponent.kt`, `MainActivity.kt` の修正を戻すとこの状態を再現させることが出来ます。しかし、Makeすると`エラー: [Dagger/DuplicateBindings] android.content.Context is bound multiple times` が発生します。
    - このCodelabsにおいて今時点でとれる解決策としては、`AppComponent`側の `@BindsInstance` で `Context` ではなく `Application` と定義することです
    - 別の解法としてはCustom Scopeの知識が必要になります。以降の章で説明します。

### diff

ここまでのdiffは以下のページで確認できます。

[Comparing intro\-dagger\-build\-types\.\.\.intro\-dagger\-subcomponent · outerheavenproject/dagger\-codelabs\-sample](https://github.com/outerheavenproject/dagger-codelabs-sample/compare/intro-dagger-build-types...intro-dagger-subcomponent)

