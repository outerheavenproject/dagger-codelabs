## 補項: Custom Scope (事前準備)

<!--
start: intro-dagger-scope
goal:  intro-dagger-custom-scope
-->

Positive
: Custom ScopeはDaggerのインスタンス管理をより柔軟にすることができますが、大規模なアプリではない場合においては必要にならず、そのための準備コードも膨大となったため、本題からは外しました。しかしながら大規模なアプリにおいてはしばしば見かける記述のため、「補項」としてお届けします。

ここからは`Scope`の章から続いて、実際に自分で定義した`Scope`を使いながら、より実践的な使い方を紹介します。
Custom Scopeについて解説する前に、既存のWanstagramアプリに機能強化をします（そうすることでCustom Scopeの良さが分かりやすくなります）。

今回はWanstagramに、複数の写真を選択してシェアする機能を作りましょう。
おおまかな仕様としては以下のようになります:

- サムネイルを長押しするとBottom Sheetが表示される
- Bottom Sheetからシェアする対象に追加できる
- Fabをタップすると、今まで追加した対象をまとめてシェアできる

`intro-dagger-scope` のbranchから実装をはじめ、上記を満たす機能を開発します。

ちなみに依存関係は以下のようになります。

![image](./12_Custom_Scope.png)

### 画像リソース, XMLの追加

これから使用する画像リソースやXMLファイルについては本筋とは関係がないので、以下のコミットからそのままプロジェクトに取り込んで使用してください。

[Add resources · outerheavenproject/dagger\-codelabs\-sample@dd3cbb2](https://github.com/outerheavenproject/dagger-codelabs-sample/commit/dd3cbb28507dda1fe7ec74ad7a48bb2488c72a10)

### `DogActionBottomSheet` の実装

`DogActionBottomSheet` を実装します。

新しい画面実装をしますが、ここまではこれまで学習したことを使っているだけです。落ち着いて実装しましょう。

`<srcBasePath>/ui/dogaction/DogActionBottomSheetContract.kt`:

```kotlin
interface DogActionBottomSheetContract {
    interface View {
    }

    interface Presenter {
        fun start(url: String)
        fun share()
    }
}
```

`<srcBasePath>/ui/dogaction/DogActionBottomSheetDialogFragment.kt`:

```kotlin
class DogActionBottomSheetDialogFragment : BottomSheetDialogFragment(),
    DogActionBottomSheetContract.View {
    companion object {
        const val TAG = "DogActionBottomSheetDialogFragment"
        private const val URL_KEY = "url"

        fun newInstance(url: String) =
            DogActionBottomSheetDialogFragment()
                .apply { arguments = bundleOf(URL_KEY to url) }
    }

    @Inject
    lateinit var presenter: DogActionBottomSheetContract.Presenter

    private val url: String by lazy {
        requireArguments().getString(URL_KEY) ?: throw IllegalStateException()
    }

    override fun onAttach(context: Context) {
        AndroidSupportInjection.inject(this)
        super.onAttach(context)
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        LayoutInflater.from(requireContext())
            .inflate(
                R.layout.dog_action_bottom_sheet_dialog_fragment,
                container,
                false
            )
            .also {
                it.setOnClickListener {
                    presenter.share()
                    dismiss()
                }
            }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        presenter.start(url)
    }
}
```

`<srcBasePath>/ui/dogaction/DogActionBottomSheetPresenter.kt`:

```kotlin
class DogActionBottomSheetPresenter @Inject constructor(
    private val sink: DogActionSink,
    private val view: DogActionBottomSheetContract.View
) : DogActionBottomSheetContract.Presenter {
    private lateinit var url: String

    override fun start(url: String) {
        this.url = url
    }

    override fun share() {
        sink.write(url)
    }
}
```

`<srcBasePath>/ui/dogaction/DogActionSink.kt`:

```kotlin
interface DogActionSink {
    fun write(url: String)
}
```

Positive
: `DogActionSink` という命名は馴染みのない方もいるかも知れません。「キッチンのシンク」のように、そこに何かを溜めるような仕組みを提供するものに対して、そう名付けることがあります。実際、`DogActionSink`ではString型のurlを受け取るようなインターフェースを備えています。

`<srcBasePath>/ui/dogaction/DogActionBottomSheetDialogFragmentModule.kt`:

```kotlin
@Module
interface DogActionBottomSheetDialogFragmentModule {
    @FragmentScope
    @ContributesAndroidInjector(
        modules = [
            DogActionBottomSheetDialogFragmentBindModule::class
        ]
    )
    fun contributeDogActionBottomSheetDialogFragment(): DogActionBottomSheetDialogFragment
}

@Module
interface DogActionBottomSheetDialogFragmentBindModule {
    @Binds
    fun bindView(fragment: DogActionBottomSheetDialogFragment): DogActionBottomSheetContract.View

    @Binds
    fun bindPresenter(presenter: DogActionBottomSheetPresenter): DogActionBottomSheetContract.Presenter
}
```

### Fragmentに `HasAndroidInjector` を実装する

Positive
: `Dagger.Android` の章の最後に説明したとおり `DaggerFragment` を用いてもOKです ;-)

`DogFragment`と`ShibaFragment`に`HasAndroidInjector`を実装します（いつものとおり`DogFragment`のdiffのみですが、`ShibaFragment`も同じく対応します）。

```diff
-class DogFragment : Fragment(), DogContract.View {
+class DogFragment : Fragment(), DogContract.View, HasAndroidInjector {
+    @Inject
+    lateinit var dispatchingAndroidInjector: DispatchingAndroidInjector<Any>
+    
 // ...
+
+    override fun androidInjector(): AndroidInjector<Any> = dispatchingAndroidInjector
 }
```

### AppNavigatorの拡張

それぞれのFragmentで発生したイベントを実行する AppNavigator を拡張して、BottomSheetを開くなどのイベントに対応させます。

```diff
 interface AppNavigator {
     fun navigateToDetail(imageUrl: String)
+    fun navigateToAction(childFragmentManager: FragmentManager, url: String)
+    fun shareUris(context: Context, uris: ArrayList<Uri>)
 }

 class AppNavigatorImpl @Inject constructor(
     private val context: Context
 ) : AppNavigator {
     // ...
+
+    override fun navigateToAction(childFragmentManager: FragmentManager,  url: String) {
+        DogActionBottomSheetDialogFragment.newInstance(url)
+            .show(childFragmentManager,  DogActionBottomSheetDialogFragment.TAG)
+    }
+
+    override fun shareUris(context: Context, uris: ArrayList<Uri>) {
+        context.startActivity(
+            Intent.createChooser(
+                Intent().apply {
+                    action = Intent.ACTION_SEND_MULTIPLE
+                    type = "image/*"
+                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
+                },
+                ""
+            )
+        )
+    }
 }
```

そして、 `DogAdapter` を書き換え、追加したイベントをコールします。

```diff
 class DogAdapter @Inject constructor(
+    private val childFragmentManager: FragmentManager,
     private val navigator: AppNavigator
 ) : ListAdapter<String, DogViewHolder>(DogDiffUtil) {
     // ...
     override fun onBindViewHolder(holder: DogViewHolder, position: Int) {
         // ...
+        holder.itemView.setOnLongClickListener {
+            navigator.navigateToAction(childFragmentManager, dogUrl)
+            true
+        }
     }
 }
```

Positive
: `OnLongClickListener`の最後にある不自然な `true` は、LongClickListenerがbooleanを返す必要がある為で、ロングタップで何かイベントを行った場合は `true` を返すことを求められているためです。

### MainPresenterの実装

MainActivityですべきことが増えたため、MainPresenterを実装します。

`<srcBasePath>/ui/MainContract.kt`:

```kotlin
interface MainContract {
    interface View {
        fun shareDogs(dogs: Set<String>)
    }

    interface Presenter {
        fun start()
        fun share()
    }
}
```

`<srcBasePath>/ui/MainPresenter.kt`:

```kotlin
class MainPresenter @Inject constructor(
    private val view: MainContract.View
) : MainContract.Presenter, DogActionSink {
    private val shareList = mutableSetOf<String>()

    override fun start() {
    }

    override fun write(url: String) {
        shareList.add(url)
    }

    override fun share() {
        view.shareDogs(shareList)
    }
}
```

Positive
: ここで `DogActionSink` を実装しました :-)

`MainActivity`で新たに実装したPresenterに対応させます。

```diff
-class MainActivity : AppCompatActivity(), HasAndroidInjector {
+class MainActivity : AppCompatActivity(), HasAndroidInjector, MainContract.View {
+    @Inject
+    lateinit var presenter: MainContract.Presenter
+
+    @Inject
+    lateinit var navigator: AppNavigator
 
     // ...
 
     override fun onCreate(savedInstanceState: Bundle?) {
         // ...
+        findViewById<View>(R.id.fab)
+            .setOnClickListener { presenter.share() }
+
+        presenter.start()
     }
 
+    override fun shareDogs(dogs: Set<String>) {
+        navigator.shareUris(this, ArrayList(dogs.map { it.toUri() }))
+    }
 
     // ...
 }
```

### MainActivityModuleでModuleのインストール, 追加

新しく作成した画面や、拡張したクラスで依存関係が増えたので、対応させます。
`MainActivityModule`を編集し、Moduleのインストールや依存関係の追加をします。

```diff
 @Module
 interface MainActivityModule {
     @ActivityScope
     @ContributesAndroidInjector(
         modules = [
+            MainActivityProvidesModule::class,
             MainActivityBindModule::class,
             DogFragmentModule::class,
-            ShibaFragmentModule::class
+            ShibaFragmentModule::class,
+            DogActionBottomSheetDialogFragmentModule::class
         ]
     )
     fun contributeMainActivity(): MainActivity
 }
 
+@Module
+class MainActivityProvidesModule {
+    @Provides
+    fun provideFragmentManager(activity: MainActivity): FragmentManager {
+        return activity.supportFragmentManager
+    }
+}
+
 @Module
 interface MainActivityBindModule {
     @Binds
     fun bindContext(context: MainActivity): Context
 
     @Binds
     fun bindAppNavigator(navigator: AppNavigatorImpl): AppNavigator
+
+    @Binds
+    fun bindView(activity: MainActivity): MainContract.View
+
+    @Binds
+    fun bindPresenter(presenter: MainPresenter): MainContract.Presenter
+
+    @Binds
+    fun bindDogActionSink(presenter: MainPresenter): DogActionSink
 }
```

ここまでが準備編です。
各パーツは揃っているのでコンパイルは通りますが、実際に動かしてみると想定通りに動きません。いくら画像を長押しして「後でシェアする」を押し、FABを押しても空のリストが帰ってきます。

それは何故でしょうか？それはどうやったら修正できるでしょうか？

続く・・・。

