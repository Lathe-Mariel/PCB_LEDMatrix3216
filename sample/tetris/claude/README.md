# Matrix LED Tetris for Tang Primer 25K

## ファイル構成

| ファイル | 説明 |
|---------|------|
| `tetris_top.v`    | トップモジュール（PLL接続・配線） |
| `tetris_engine.v` | テトリスゲームエンジン（FSM + フレームバッファ合成） |
| `led_driver.v`    | マトリクスLEDドライバ（シリアル走査） |
| `font_5x3.v`      | 3×5ドット数字フォントROM |
| `tetris.cst`      | 物理制約ファイル |
| `pll_spec.md`     | **PLLのIP生成仕様**（ユーザーが生成してください） |

## PLLについて
`pll_spec.md` を参照して Gowin IP Generator で `pll_25m` モジュールを生成し、
プロジェクトに追加してください。

---

## 画面レイアウト (16col × 64row)

```
Col:  0  1  2  3  4  5  6  7 | 8  9 10 11 | 12 13 14 15
Row 0 ┌──────────────────────┬────────────┬────────────┐
      │                      │ Next piece │  (未使用)  │ rows 0-7
      │   Play field         │  4×4 dots  │            │
      │   8cols × 32rows     ├────────────┴────────────┤
      │                      │      (未使用)           │ rows 8-31
Row31 │                      │                         │
      ├──────────────────────┼─────────────────────────┤
Row32 │   (未使用)           │ Score  5桁 (縦並び)     │ rows 32-63
Row63 └──────────────────────┴─────────────────────────┘
```

**フレームバッファのビット割り当て**:
- `fb_rowN[15]` = col 0 (左端・プレイフィールド左)
- `fb_rowN[8]`  = col 7 (プレイフィールド右端)
- `fb_rowN[7]`  = col 8 (予告エリア左端)
- `fb_rowN[0]`  = col 15 (右端)

---

## マトリクスLEDドライバの動作

### シフトレジスタ構成
```
64クロックで1行分を転送:
  SIN1 : 64bit one-hot 行選択 (MSBファースト)
  SIN2 : 64bit 列データ (col_word × 4 複製)
  SIN3 : 64bit 列データ (col_word × 4 複製)

転送→LATCH→STROBE_ Low (表示保持) →次の行
```

### リフレッシュレート
- シフトクロック: 12.5 MHz (25MHz ÷ 2)
- 転送時間: 64 / 12.5MHz ≈ 5.1 µs
- 保持時間: 780 cycles × 40ns ≈ 31.2 µs
- 1行あたり: ≈ 36.3 µs → 行レート ≈ 27.5 kHz
- フレームレート: 27.5 kHz ÷ 64 ≈ **430 fps**

---

## テトリスゲーム仕様

### ゲームロジック
- **重力タイマー**: 25 MHz ÷ 12,500,000 = 2 Hz（約0.5秒/1段落下）
- **ピース種類**: I, O, T, S, Z, J, L（7種）
- **回転**: 0°/90°/180°/270°（各4状態）
- **乱数**: 7bit LFSR（フィードバックポリノミアル: x7+x6+1）

### キー入力（物理的な実装）
現在 USER_KEY → 左移動、USER_KEY2 → 右移動 にマッピング済み。
将来の拡張用に以下のレジスタ信号を用意:
```verilog
input wire key_left    // 左移動
input wire key_right   // 右移動
input wire key_down    // 高速落下
input wire key_rot_r   // 右回転 (A button)
input wire key_rot_l   // 左回転 (B button)
```

### 得点計算
| 同時消去行数 | 加算点数 |
|------------|---------|
| 1行         | 1点     |
| 2行         | 4点     |
| 3行         | 16点    |
| 4行         | 256点   |

スコアは5桁BCD（最大99999点）で保持。

### ゲームオーバー
- スポーン時に衝突検出 → ゲームオーバー状態
- 全LEDが点滅
- いずれかのキー入力でリセット

---

## 合成・実装手順 (Gowin EDA)

1. 新規プロジェクト作成 (Device: **GW5A-25**, Tang Primer 25K)
2. `pll_spec.md` を参照してPLL IPを生成 → プロジェクトに追加
3. 以下のVerilogファイルを追加:
   - `tetris_top.v` (Top module)
   - `tetris_engine.v`
   - `led_driver.v`
   - `font_5x3.v`
4. `tetris.cst` を物理制約として追加
5. **Synthesize → Place & Route → Generate Bitstream**
6. `tetris_top` をトップモジュールに指定
