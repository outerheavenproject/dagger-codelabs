## Appendix 2: Scope

Scopeを定義し使用することでライフサイクルに沿ったインスタンスを受け取ることが出来ます。
実際にScopeを使用しながら感覚を掴んでいきましょう。

今回はPetBookに、複数の写真を選択してシェアする機能を作りましょう。
長押しした場合にBottom sheetが出てそこのメニューからまとめてシェアできる導線を作ることにします。

### `FragmentScope`

今回はFragmentのためのScopeとして`FragmentScope`を定義しましょう。

```kt
@Scope
@MustBeDocumented
@Retention(AnnotationRetention.RUNTIME)
annotation class FragmentScope
```

`MainFragment`のSubComponentにScopeを付加します。

```kt
```

### シェアリストの更新

Bottom sheetから何かしら返すことで実現しても良いのですが、今回はScopeを体感してもらうために親FragmentのPresenterを参照し、シェアするリストを更新していきます。

```kt
```

### 実行と確認

実際に動かしてみてください、選択する度に表示が更新されていくのがわかりはずです。
ここでもし`FragmentScope`を外した場合、Bottom sheet側には新しいインスタンスが渡されるため、更新はされません。

### まとめ
